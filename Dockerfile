# syntax=docker/dockerfile:latest

ARG starenv=root6

# Pick one from [gcc485, gcc11]
ARG compiler=gcc485

# Pick one from [os, bc]
ARG baseimg=bc

ARG baseimg_os=scientificlinux/sl:7
ARG baseimg_bc=ghcr.io/star-bnl/star-spack:buildcache

# This implements a switch for /opt/buildcache in buildcache-stage
FROM ${baseimg_os} AS baseimg_os-stage
RUN mkdir -p /opt/buildcache # create dummy dir
FROM ${baseimg_bc} AS baseimg_bc-stage
FROM baseimg_${baseimg}-stage AS buildcache-stage


# Install gcc485 (default)
FROM ${baseimg_os} AS gcc485-prep-stage
RUN yum install -y gcc gcc-c++ gcc-gfortran \
 && mkdir -p /opt/rh # create dummy dir

# Install gcc11
FROM ${baseimg_os} AS gcc11-prep-stage
RUN curl -O http://mirror.centos.org/centos/7/extras/x86_64/Packages/centos-release-scl-rh-2-3.el7.centos.noarch.rpm \
 && rpm -ivh centos-release-scl-rh-2-3.el7.centos.noarch.rpm \
 && yum install -y devtoolset-11 \
 && echo "source /opt/rh/devtoolset-11/enable" >> /etc/bashrc


FROM ${compiler}-prep-stage AS build-stage

# The shell command allows to pick up the changes in /etc/bashrc
SHELL ["/bin/bash", "--login", "-c"]

RUN yum install -y git unzip make patch \
    perl perl-Data-Dumper \
    lapack-static blas-static imake motif-devel

# Install cernlib
RUN mkdir /cern && cd /cern \
 && curl -sL https://github.com/psilib/cernlib/archive/9d59c54d.tar.gz | tar -xz --strip-components 1 \
 && ./build_cernlib.sh \
 && mv /usr/lib64/libblas.a   /cern/2006/lib/libblas.a \
 && mv /usr/lib64/liblapack.a /cern/2006/lib/liblapack3.a \
 && ln -s 2006 /cern/pro \
 && rm -fr /cern/2006/src /cern/2006/build

COPY . /star-spack

RUN mkdir -p /star-spack/spack && curl -sL https://github.com/spack/spack/archive/v0.18.1.tar.gz | tar -xz --strip-components 1 -C /star-spack/spack

ARG starenv

COPY --from=buildcache-stage /opt/buildcache /opt/buildcache

COPY --chmod=0755 <<-"EOF" dostarenv.sh
	#!/bin/bash -l
	set -e
	source /star-spack/setup.sh
	rm -f $HOME/.spack/mirrors.yaml
	spack compiler add $(dirname $(which gcc))
	spack mirror add buildcache /opt/buildcache
	spack buildcache update-index -d /opt/buildcache
	spack env create ${1} /star-spack/environments/${1}.yaml
	spack env activate ${1}
	spack --insecure install --no-check-signature --reuse
	spack module tcl refresh -y
	spack env deactivate
EOF

COPY <<"EOF" /root/.spack/config.yaml
config:
  install_tree:
    root: /opt/software
EOF

RUN ./dostarenv.sh star-utils
RUN ./dostarenv.sh star-x86_64-loose
RUN ./dostarenv.sh ${starenv}
# Load only the umbrella star-env module
RUN <<-EOF
	source /star-spack/setup.sh
	spack -e ${starenv} module tcl loads star-env >> /star-spack/spack/var/spack/environments/${starenv}/loads
EOF

# Strip all the binaries
RUN find -L /opt/software/* -type f -exec readlink -f '{}' \; | \
    xargs file -i | \
    grep 'charset=binary' | \
    grep 'x-executable\|x-archive\|x-sharedlib' | \
    awk -F: '{print $1}' | xargs strip -S


FROM ${baseimg_os} AS starenv-stage

ARG starenv
ARG compiler

COPY --from=build-stage /cern /cern
COPY --from=build-stage /etc/bashrc /etc/bashrc
COPY --from=build-stage /opt/software /opt/software
COPY --from=build-stage /star-spack/spack/var/spack/environments/${starenv}/loads /etc/profile.d/z10_load_spack_env_modules.sh
COPY --from=build-stage /star-spack/spack/share/spack/modules/linux-scientific7-x86_64 /opt/linux-scientific7-x86_64

RUN yum update -q -y \
 && yum install -y \
    binutils gcc gcc-c++ gcc-gfortran \
    git bzip2 file which make patch \
    bison byacc flex flex-devel libcurl-devel \
    perl perl-Env perl-Digest-MD5 \
    libX11-devel libXext-devel libXpm-devel libXt-devel \
    environment-modules \
 && yum clean all

RUN curl -O http://mirror.centos.org/centos/7/extras/x86_64/Packages/centos-release-scl-rh-2-3.el7.centos.noarch.rpm \
 && rpm -ivh centos-release-scl-rh-2-3.el7.centos.noarch.rpm \
 && yum install -y devtoolset-11 \
 && yum clean all

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
RUN source /etc/profile \
 && ln -s `mysql_config --variable=pkgincludedir` /usr/include/mysql

COPY --chmod=0755 <<-"EOF" /opt/entrypoint.sh
	#!/bin/bash -l
	set -e
	exec "$@"
EOF

ENTRYPOINT ["/opt/entrypoint.sh"]
CMD ["/bin/bash"]
