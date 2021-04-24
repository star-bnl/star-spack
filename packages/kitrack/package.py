from spack import *

class Kitrack(CMakePackage):
    """KiTrack is a c++ toolkit that provides implementation of a cellular
       automaton and a Hopfield neural network for charged particle tracking"""

    homepage = "https://github.com/star-bnl/KiTrack"
    url      = "https://github.com/star-bnl/KiTrack/archive/master.tar.gz"

    version('01-10-star-1', sha256='eab327bdfb839105272305a13c47a4ae2f120017ccefde0a88e2c0807ec550cf')

    depends_on('root')
