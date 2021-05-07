# STAR Spack Package Repository

Quick start for maintainers:

    # A one-time setup
    git clone --recurse-submodules https://github.com/star-bnl/star-spack.git
    source star-spack/spack/share/spack/setup-env.sh
    spack repo add star-spack
    spack env create star-x86_64 star-spack/environments/star-x86_64.yaml
    spack env create star-x86 star-spack/environments/star-x86.yaml

    # Install packages in 64-bit environment
    spack env activate -p star-x86_64
    spack install
    despacktivate

    # Build 32-bit version
    spack env activate -p star-x86
    spack install
    despacktivate
