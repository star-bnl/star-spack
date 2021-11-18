from spack import *


class StarEnv(BundlePackage):
    """External packages STAR software depends on"""

    version('0.1')

    depends_on('python')
    depends_on('eigen')
    depends_on('genfit')
    depends_on('kfparticle')
    depends_on('kitrack')
    depends_on('log4cxx')
    depends_on('rave')
    depends_on('root')
    depends_on('vc')
    depends_on('vc_')
    depends_on('star-table', when='^root@6.18.00:')

    def setup_run_environment(self, env):
        # Set env variable used by STAR cons
        env.set('USE_64BITS', '0' if self.spec.target == 'x86' else '1')

        env.append_path('CPATH', self.spec['genfit'].prefix.include)
        env.append_path('CPATH', self.spec['kfparticle'].prefix.include)
        env.append_path('CPATH', self.spec['kitrack'].prefix.include)
        env.append_path('CPATH', self.spec['log4cxx'].prefix.include)
        env.append_path('CPATH', self.spec['rave'].prefix.include)
        env.append_path('CPATH', self.spec['root'].prefix.include)
        env.append_path('CPATH', self.spec['vc'].prefix.include)

        if self.spec['root'].satisfies('@6.18.00:'):
            env.append_path('CPATH', self.spec['star-table'].prefix.include)
            env.prepend_path('LD_LIBRARY_PATH', self.spec['star-table'].prefix.lib)

        # We prepend because the user's LD_LIBRARY_PATH may already include
        # a path to some other ROOT directory
        env.prepend_path('LD_LIBRARY_PATH', self.spec['root'].prefix.lib)

        # Add some ROOT dependencies to LD_LIBRARY_PATH. Missing RPATH?
        env.append_path('LD_LIBRARY_PATH', self.spec['zlib'].prefix.lib)
        env.append_path('LD_LIBRARY_PATH', self.spec['libiconv'].prefix.lib)
        env.append_path('LD_LIBRARY_PATH', self.spec['libbsd'].prefix.lib)
        env.append_path('LD_LIBRARY_PATH', self.spec['libmd'].prefix.lib)

        # Based on ROOT version pick default Vc from the two available options
        if self.spec['root'].satisfies('@6.16'):
            env.set('Vc_DIR', self.spec['vc_'].prefix)
        else:
            env.set('Vc_DIR', self.spec['vc'].prefix)
