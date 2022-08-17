from spack import *


class Kfparticle(CMakePackage):

    url = "https://git.cbm.gsi.de/m.zyzak/KFParticle/-/archive/v1.1/KFParticle-v1.1.tar.gz"

    version('1.1', sha256='f06005ec67df35e3c64a377a4e720dc73d7c487519dbd1d96ff98e3a7d22f2ed')

    depends_on('cmake', type='build')
    depends_on('root')
