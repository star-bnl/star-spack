# Pick one from [os, bc]
ARG baseimg=bc

ARG baseimg_os=scientificlinux/sl:7
ARG baseimg_bc=ghcr.io/star-bnl/star-spack:buildcache

FROM ${baseimg_os} AS baseimg_os-stage
FROM ${baseimg_bc} AS baseimg_bc-stage

FROM baseimg_${baseimg}-stage AS build-stage

ARG starenv=x86_64-root-6.16.00

RUN yum update -q -y \
 && yum install -y \
    gcc gcc-c++ gcc-gfortran \
    git unzip make patch perl perl-Data-Dumper \
    lapack-static blas-static imake motif-devel \
 && yum clean all

# Install cernlib
RUN mkdir /cern && cd /cern \
 && curl -sL https://github.com/psilib/cernlib/archive/centos7.tar.gz | tar -xz --strip-components 1 \
 && ./build_cernlib.sh \
 && mv /usr/lib64/libblas.a   /cern/2006/lib/libblas.a \
 && mv /usr/lib64/liblapack.a /cern/2006/lib/liblapack3.a \
 && ln -s 2006 /cern/pro \
 && rm -fr /cern/2006/src /cern/2006/build

COPY . star-spack

RUN mkdir -p star-spack/spack && curl -sL https://github.com/spack/spack/archive/v0.17.2.tar.gz | tar -xz --strip-components 1 -C star-spack/spack

# Create star-spack/spack/var/spack/environments/star-env/loads
SHELL ["/bin/bash", "-c"]

RUN source star-spack/setup.sh \
 && spack mirror add buildcache /opt/buildcache \
 && spack buildcache update-index -d /opt/buildcache \
 && spack env create star-env star-spack/environments/star-${starenv}-container.yaml \
 && spack env activate star-env \
 && spack --insecure install --no-check-signature \
 && spack env loads \
 && spack module tcl refresh -y

# Strip all the binaries
RUN find -L /opt/software/* -type f -exec readlink -f '{}' \; | \
    xargs file -i | \
    grep 'charset=binary' | \
    grep 'x-executable\|x-archive\|x-sharedlib' | \
    awk -F: '{print $1}' | xargs strip -S


FROM ${baseimg_os} AS starenv-stage

COPY --from=build-stage /cern /cern
COPY --from=build-stage /opt/software /opt/software
COPY --from=build-stage /star-spack/spack/var/spack/environments/star-env/loads /etc/profile.d/z10_load_spack_env_modules.sh
COPY --from=build-stage /star-spack/spack/share/spack/modules/linux-scientific7-x86_64 /opt/linux-scientific7-x86_64

# epel repo is for python-pip only
RUN yum update -q -y \
 && yum install -y epel-release \
 && yum install -y \
    binutils gcc gcc-c++ gcc-gfortran \
    git bzip2 file which make patch \
    bison byacc flex flex-devel libcurl-devel \
    perl perl-Env perl-Digest-MD5 \
    libX11-devel libXext-devel libXpm-devel libXt-devel \
    python python-pip \
    environment-modules \
 && yum clean all

# Install extra python modules used by the STAR software
RUN pip install pyparsing==2.2.0

ENV MODULEPATH=/opt/linux-scientific7-x86_64
ENV USE_64BITS=1
ENV CERN=/cern
ENV CERN_LEVEL=pro
ENV CERN_ROOT=$CERN/$CERN_LEVEL
ENV OPTSTAR=/opt/software
ENV STAR_HOST_SYS=sl79_gcc485
ENV PATH=$CERN_ROOT/bin:$PATH
ENV LIBPATH+=:/lib64:/lib

# Empty dummy directories checked by cons
RUN mkdir $OPTSTAR/lib && mkdir $OPTSTAR/include
# Some STAR packages include mysql.h as <mysql/mysql.h>
RUN source /etc/profile && ln -s `mysql_config --variable=pkgincludedir` /usr/include/mysql

RUN echo -e '#!/bin/bash --login\n set -e; eval "$@"' > entrypoint.sh && chmod 755 entrypoint.sh
ENTRYPOINT ["./entrypoint.sh"]
CMD ["/bin/bash"]
