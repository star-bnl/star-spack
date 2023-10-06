from spack import *


class StarEnv(BundlePackage):
    """External packages STAR software depends on"""

    homepage = "https://github.com/star-bnl/star-spack/"

    version('0.3.0')

    depends_on('boost')
    depends_on('eigen')
    depends_on('fastjet')
    depends_on('genfit')
    depends_on('gsl')
    depends_on('kitrack')
    depends_on('libxml2')
    depends_on('libiconv')
    depends_on('log4cxx')
    depends_on('mysql')
    depends_on('python')
    depends_on('py-pyparsing')
    depends_on('rave')
    depends_on('root')
    depends_on('vc@0.7.4')
    depends_on('star-table', when='root@6.16:')
    depends_on('zlib')

    def setup_run_environment(self, env):
        # Set env variable used by STAR cons
        env.set('USE_64BITS', '0' if self.spec.target == 'x86' else '1')
