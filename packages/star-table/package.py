from spack import *

class StarTable(CMakePackage):
    """A C++ library used by STAR experiment to deal with hierarchical data
    structures based on ROOT's TDataSet class"""

    homepage = "https://github.com/star-bnl/star-table"
    git      = "https://github.com/star-bnl/star-table"
    url      = "https://github.com/star-bnl/star-table/archive/main.tar.gz"

    version('main', branch='main')

    depends_on('cmake@3.6:', type='build')
    depends_on('root')

    def cmake_args(self):
        args = []
        args.append(self.define('CMAKE_CXX_STANDARD', self.spec['root'].variants['cxxstd'].value))
        return args
