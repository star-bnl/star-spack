from spack import *


class StarEnvRoot6(BundlePackage):
    """Packages STAR sowftware depends on."""

    version('0.1')

    depends_on('genfit')
    depends_on('kfparticle')
    depends_on('kitrack')
    depends_on('log4cxx')
    depends_on('root')
    depends_on('star-table')

    def setup_run_environment(self, env):
        env.append_path('CPATH', self.spec['genfit'].prefix.include)
        env.append_path('CPATH', self.spec['kfparticle'].prefix.include)
        env.append_path('CPATH', self.spec['kitrack'].prefix.include)
        env.append_path('CPATH', self.spec['log4cxx'].prefix.include)
        env.append_path('CPATH', self.spec['root'].prefix.include)
        env.append_path('CPATH', self.spec['star-table'].prefix.include)
