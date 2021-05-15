# STAR Spack Package Repository

Quick start for STAR users:

    $ source /cvmfs/star.sdcc.bnl.gov/star-spack/setup.sh
    $ spack env list
    ==> 4 environments
        star-x86  star-x86-root616  star-x86_64  star-x86_64-root616
    $ spack find
    ==> 318 installed packages
    -- linux-rhel7-x86 / gcc@4.8.5 ----------------------------------
    apr@1.7.0        davix@0.7.6        ftgl@2.4.0     ...
    ...

    -- linux-rhel7-x86_64 / gcc@4.8.5 -------------------------------
    apr@1.7.0        davix@0.7.6        g4emlow@7.3    ...
    ...

    $ spack load star-env-root6 target=x86_64

Quick start for maintainers:

    # A one-time setup
    $ git clone --recurse-submodules https://github.com/star-bnl/star-spack.git
    $ source star-spack/setup.sh
    $ spack env create star-x86_64 star-spack/environments/star-x86_64.yaml
    $ spack env create star-x86 star-spack/environments/star-x86.yaml

    # Install packages in 64-bit environment
    $ spack env activate star-x86_64
    $ spack install
    $ despacktivate

    # Build 32-bit version
    $ spack env activate star-x86
    $ spack install
    $ despacktivate
