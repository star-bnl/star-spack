# syntax=docker/dockerfile:latest

ARG starenv=root6

# Pick one from [gcc485, gcc11]
ARG compiler=gcc485

ARG baseimg_os=scientificlinux/sl:7

# Normal builds require this image to provide /opt/spack-buildcache. Override
# it only to consume another compatible mirror image.
ARG spack_cache_image=ghcr.io/star-bnl/star-spack:spack-buildcache

# Set this to true only when exporting an updated shared buildcache image.
# It does not change the installation steps, so an export can reuse the layers
# produced by a preceding normal build.
ARG rebuild_spack_buildcache=false

# The local fallback and the GHCR image expose the same path.
FROM ${baseimg_os} AS spack-cache-empty-stage
RUN mkdir -p /opt/spack-buildcache

FROM ${spack_cache_image} AS spack-cache-seed-stage

# Install common packages
FROM ${baseimg_os} AS base-stage

RUN sed -i 's/scientificlinux.org\/linux\/scientific\//scientificlinux.org\/linux\/scientific\/obsolete\//g' /etc/yum.repos.d/*
RUN yum install -y git unzip make patch perl perl-Data-Dumper file


# Install gcc485 (default)
FROM base-stage AS gcc485-prep-stage
RUN yum install -y gcc gcc-c++ gcc-gfortran \
 && mkdir -p /opt/rh # create dummy dir

# Install gcc11
FROM base-stage AS gcc11-prep-stage

COPY <<-"EOF" /etc/yum.repos.d/rocky-sclo-rh.repo
[rocky-sclo-rh]
name=Rocky Vault CentOS 7 SCLo rh
baseurl=https://dl.rockylinux.org/vault/centos/7/sclo/$basearch/rh/
enabled=1
gpgcheck=0
EOF

RUN yum install -y devtoolset-11 \
 && echo "source /opt/rh/devtoolset-11/enable" >> /etc/profile.d/z01_setup_compiler.sh


FROM ${compiler}-prep-stage AS spack-build-stage

SHELL ["/bin/bash", "-l", "-c"]

RUN yum install -y lapack-static blas-static imake motif-devel

# Install cernlib
RUN mkdir /cern && cd /cern \
 && curl -sL https://github.com/psilib/cernlib/archive/9d59c54d.tar.gz | tar -xz --strip-components 1 \
 && ./build_cernlib.sh \
 && mv /usr/lib64/libblas.a   /cern/2006/lib/libblas.a \
 && mv /usr/lib64/liblapack.a /cern/2006/lib/liblapack3.a \
 && ln -s 2006 /cern/pro \
 && rm -fr /cern/2006/src /cern/2006/build

RUN mkdir -p /star-spack/spack && curl -sL https://github.com/spack/spack/archive/v0.18.1.tar.gz | tar -xz --strip-components 1 -C /star-spack/spack

# Copy only inputs that affect concretization or package builds. In particular,
# README and workflow-only changes should not invalidate the Spack layers.
COPY repo.yaml setup.sh setup.csh /star-spack/
COPY environments /star-spack/environments
COPY packages /star-spack/packages

RUN echo "[ -f /star-spack/setup.sh ] && source /star-spack/setup.sh" > /etc/profile.d/z09_setup_spack.sh

ARG starenv

COPY --from=spack-cache-seed-stage /opt/spack-buildcache /spack-buildcache-seed

COPY --chmod=0755 <<-"EOF" dostarenv.sh
	#!/bin/bash -l
	set -e
	environment=${1}
	cache_dir=${2}
	spack compiler add $(dirname $(which gcc))
	spack mirror add --scope site spack-buildcache "file://${cache_dir}" || true
	spack mirror list
	spack buildcache update-index --mirror-url "file://${cache_dir}"
	spack config add 'config:install_tree:root:/opt/software'
	spack env remove -y "${environment}" || true
	spack env create "${environment}" "/star-spack/environments/${environment}.yaml"
	spack env activate "${environment}"
	install_status=0
	spack --insecure install --no-check-signature --reuse || install_status=$?
	mapfile -t installed_hashes < <(spack find --no-groups --format "/{hash}")
	if ((${#installed_hashes[@]})); then
		spack buildcache create --allow-root --unsigned --rebuild-index --directory "${cache_dir}" "${installed_hashes[@]}"
	fi
	if ((install_status)); then
		spack env deactivate
		exit "${install_status}"
	fi
	spack module tcl refresh -y
	spack env deactivate
EOF

RUN --mount=type=cache,id=star-spack-buildcache,target=/spack-buildcache,sharing=locked \
	cp -an /spack-buildcache-seed/. /spack-buildcache/ \
 && ./dostarenv.sh star-loose /spack-buildcache
RUN --mount=type=cache,id=star-spack-buildcache,target=/spack-buildcache,sharing=locked \
	cp -an /spack-buildcache-seed/. /spack-buildcache/ \
 && ./dostarenv.sh ${starenv} /spack-buildcache


FROM spack-build-stage AS build-stage

SHELL ["/bin/bash", "-l", "-c"]

ARG starenv
ARG optimize_runtime=true

# Reduce the runtime image size while keeping static archives usable for
# downstream linking. Pull-request builds disable this expensive optimization.
RUN if [[ "${optimize_runtime}" == true ]]; then \
        find /opt/software -type f -exec sh -c ' \
        for file do \
            description=$(file -b "$file"); \
            case "$description" in \
                *ELF*"executable"*|*ELF*"shared object"*) \
                    strip --strip-unneeded "$file" \
                    ;; \
                *"current ar archive"*) \
                    strip --strip-debug "$file" \
                    ;; \
            esac; \
        done \
        ' sh {} +; \
    fi

# Load only the umbrella star-env module
RUN spack -e ${starenv} module tcl loads star-env >> /etc/profile.d/z10_load_spack_env_modules.sh


# Cache mounts are local to a BuildKit builder and cannot be pushed directly.
# Rebuild mode snapshots the named mount into a normal layer for export. This
# stage is not part of normal runtime-image builds.
FROM spack-build-stage AS spack-buildcache-export-stage

SHELL ["/bin/bash", "-l", "-c"]

ARG rebuild_spack_buildcache
ARG spack_cache_export_revision=local

RUN --mount=type=cache,id=star-spack-buildcache,target=/spack-buildcache,sharing=locked \
	test "${rebuild_spack_buildcache}" == true \
 && test -n "${spack_cache_export_revision}" \
 && cp -an /spack-buildcache-seed/. /spack-buildcache/ \
 && spack buildcache update-index --mirror-url file:///spack-buildcache \
 && mapfile -t installed_hashes < <(spack find --no-groups --format "/{hash}") \
 && if ((${#installed_hashes[@]})); then \
		spack buildcache create --allow-root --unsigned --rebuild-index --directory /spack-buildcache "${installed_hashes[@]}"; \
	fi \
 && rm -rf /spack-buildcache-export \
 && mkdir -p /spack-buildcache-export \
 && cp -a /spack-buildcache/. /spack-buildcache-export/


# Export only the Spack mirror. Neither this snapshot nor the cache mount is
# copied into the runtime image below.
FROM scratch AS spack-buildcache

COPY --from=spack-buildcache-export-stage /spack-buildcache-export /opt/spack-buildcache


FROM ${baseimg_os} AS starenv-stage

ARG starenv
ARG compiler

RUN sed -i 's/scientificlinux.org\/linux\/scientific\//scientificlinux.org\/linux\/scientific\/obsolete\//g' /etc/yum.repos.d/*
RUN yum update -q -y \
 && yum install -y \
    binutils gcc gcc-c++ gcc-gfortran \
    git bzip2 file which make patch \
    bison byacc flex flex-devel libcurl-devel \
    perl perl-Env perl-Digest-MD5 \
    libX11-devel libXext-devel libXpm-devel libXt-devel \
    environment-modules \
 && yum clean all

# Copy the generated activation scripts only after the `module` command is installed
COPY --from=build-stage /cern /cern
COPY --from=build-stage /etc/profile.d /etc/profile.d
COPY --from=build-stage /opt/software /opt/software
COPY --from=build-stage /star-spack/spack/share/spack/modules/linux-scientific7-x86_64 /opt/linux-scientific7-x86_64

SHELL ["/bin/bash", "-l", "-c"]

ENV MODULEPATH=/opt/linux-scientific7-x86_64
ENV USE_64BITS=1
ENV CERN=/cern
ENV CERN_LEVEL=pro
ENV CERN_ROOT=$CERN/$CERN_LEVEL
ENV OPTSTAR=/opt/software
ENV STAR_HOST_SYS=sl79_${compiler}
ENV PATH=$CERN_ROOT/bin:$PATH
ENV LIBPATH+=:/lib64:/lib

# Empty dummy directories checked by cons
RUN mkdir $OPTSTAR/lib && mkdir $OPTSTAR/include
# Some STAR packages include mysql.h as <mysql/mysql.h>
RUN ln -s $(mysql_config --variable=pkgincludedir) /usr/include/mysql

COPY --chmod=0755 <<-"EOF" /opt/entrypoint.sh
	#!/bin/bash -l
	set -e
	exec "$@"
EOF

ENTRYPOINT ["/opt/entrypoint.sh"]
CMD ["/bin/bash"]
