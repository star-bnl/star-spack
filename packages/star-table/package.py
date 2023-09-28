from spack import *

class StarTable(CMakePackage):
    """A C++ library used by STAR experiment to deal with hierarchical data
    structures based on ROOT's TDataSet class"""

    homepage = "https://github.com/star-bnl/star-table"
    git      = "https://github.com/star-bnl/star-table.git"
    url      = "https://github.com/star-bnl/star-table/archive/0.1.1.tar.gz"

    version('0.1.1', sha256='208d29224fc9bf9ebae66d88a3914192eea2761d5bbe40d551abd1bcff596ad2')
    version('0.1.0', sha256='46a3f75076c48e3e04a48ffb2392d70aa250111feb9ae1c6580376d7a8441027')

    depends_on('cmake@3.6:', type='build')
    depends_on('root')

    def cmake_args(self):
        args = []
        args.append(self.define('CMAKE_CXX_STANDARD', self.spec['root'].variants['cxxstd'].value))
        return args
