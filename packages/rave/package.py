# Copyright 2013-2021 Lawrence Livermore National Security, LLC and other
# Spack Project Developers. See the top-level COPYRIGHT file for details.
#
# SPDX-License-Identifier: (Apache-2.0 OR MIT)

from spack import *


class Rave(AutotoolsPackage):
    """ Rave package """

    homepage = "https://github.com/WolfgangWaltenberger/rave"
    git      = "https://github.com/WolfgangWaltenberger/rave.git"

    version('2020-08-11', commit='21e3e1')

    depends_on('autoconf', type='build')
    depends_on('automake', type='build')
    depends_on('libtool',  type='build')
    depends_on('m4',       type='build')

    depends_on('boost')
    depends_on('clhep')

    def autoreconf(self, spec, prefix):
        cmd = which('./bootstrap')
        cmd()

    def setup_build_environment(self, env):
        env.append_flags('CXXFLAGS', "-std=c++11 -O2")

    def configure_args(self):
        args = [
            '--disable-java',
            '--with-clhep=' + self.spec['clhep'].prefix
        ]

        if self.spec.target == 'x86':
            args.extend(['--build=i686', 'LDFLAGS=-m32'])

        return args
