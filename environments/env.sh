#!/usr/bin/env bash

# To remove a package in order to reinstall it
#
# $ spack uninstall --dependents --all --force -y <package>
#
# e.g.
#
# $ spack env deactivate; spack env rm -y star-x86-root5; spack env create star-x86-root5 environments/star-x86-root-5.34.yaml; spack env activate star-x86-root5; spack install
# $ spack env deactivate; spack env rm -y star-x86_64-root5; spack env create star-x86_64-root5 environments/star-x86_64-root-5.34.yaml; spack env activate star-x86_64-root5; spack install
#
# $ setarch i686 bash
#
# spack install --keep-stage --reuse root@6.24.06~vc~vmc~python build_type=Debug

set -e

install_envs() {

    envs=("$@")

    for env in "${envs[@]}"; do
        filename=${env%%:*}
        spackenv=${env#*:}
        echo

        if [[ $spackenv == *"debug"* ]]; then
            DEBUG_OPTS="--keep-stage"
        else
            DEBUG_OPTS=""
        fi

        cmd="spack env rm -y $spackenv"
        echo "$cmd"
        eval "$cmd"

        cmd="spack env create $spackenv $SPACK_ROOT/../environments/$filename.yaml"
        echo "$cmd"
        eval "$cmd"

        cmd="spack env activate $spackenv"
        echo "$cmd"
        eval "$cmd"

        cmd="spack install $DEBUG_OPTS"
        echo "$cmd"
        eval "$cmd"

        cmd="spack module tcl refresh -y"
        echo "$cmd"
        eval "$cmd"

        cmd="spack env deactivate"
        echo "$cmd"
        eval "$cmd"
    done
}


compilers_x86_64=$(cat <<EOF
compilers:
- compiler:
    spec: gcc@4.8.5
    paths:
      cc: /usr/bin/gcc
      cxx: /usr/bin/g++
      f77: /usr/bin/gfortran
      fc: /usr/bin/gfortran
    flags: {}
    operating_system: rhel7
    target: x86_64
    modules: []
    environment: {}
    extra_rpaths: []
EOF
)

compilers_x86=$(cat <<EOF
compilers:
- compiler:
    spec: gcc@4.8.5
    paths:
      cc: /usr/bin/gcc
      cxx: /usr/bin/g++
      f77: /usr/bin/gfortran
      fc: /usr/bin/gfortran
    flags:
      cflags: -m32
      cxxflags: -m32
      fflags: -m32
      ldflags: -m32
    operating_system: rhel7
    target: x86
    modules: []
    environment: {}
    extra_rpaths: []
EOF
)

envs_x86_64=(
    "star-x86_64-loose:star-x86_64-loose"
    "star-x86_64-root-5.34:star-x86_64-root5"
    "star-x86_64-root-6.24:star-x86_64-root6"
    "star-geant:star-x86_64-geant"
    "star-debug:star-x86_64-debug"
)

envs_x86=(
    "star-x86-loose:star-x86-loose"
    "star-x86-root-5.34:star-x86-root5"
    "star-x86-root-6.24:star-x86-root6"
    "star-geant:star-x86-geant"
)


if [ "$1" == 'x86_64' ]; then
    echo "==> Install envs for target=x86_64"
    echo "$compilers_x86_64" > ~/.spack/linux/compilers.yaml
    cat ~/.spack/linux/compilers.yaml
    install_envs "${envs_x86_64[@]}"

elif [ "$1" == 'x86' ]; then
    echo "==> Install envs for target=x86"
    echo "$compilers_x86" > ~/.spack/linux/compilers.yaml
    cat ~/.spack/linux/compilers.yaml
    install_envs "${envs_x86[@]}"

else
    echo "==> Error: Unrecognized target $1"
    echo "==> Pick one of [x86, x86_64]"
fi
