from spack import *

class StarTable(CMakePackage):
    """A C++ library used by STAR experiment to deal with hierarchical data
    structures based on ROOT's TDataSet class"""

    homepage = "https://github.com/star-bnl/star-table"
    git      = "https://github.com/star-bnl/star-table"
    url      = "https://github.com/star-bnl/star-table/archive/main.tar.gz"

    version('main', branch='main')

    depends_on('cmake@3.6:', type='build')
    depends_on('root@6.18:')
