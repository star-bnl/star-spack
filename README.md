# STAR Spack Package Repository

Quick start for maintainers:

    git clone https://github.com/spack/spack.git
    git clone https://github.com/star-bnl/star-spack.git
    source spack/share/spack/setup-env.sh
    spack repo add star-spack
    spack env create star-x86_64 star-spack/environments/star-x86_64.yaml
    spack env activate -p star-x86_64
    spack install
