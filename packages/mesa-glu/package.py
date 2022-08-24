# Copyright 2013-2022 Lawrence Livermore National Security, LLC and other
# Spack Project Developers. See the top-level COPYRIGHT file for details.
#
# SPDX-License-Identifier: (Apache-2.0 OR MIT)

from spack import *


class MesaGlu(AutotoolsPackage):
    """This package provides the Mesa OpenGL Utility library."""

    homepage = "https://www.mesa3d.org"
    url      = "https://www.mesa3d.org/archive/glu/glu-9.0.0.tar.gz"

    version('9.0.2', sha256='24effdfb952453cc00e275e1c82ca9787506aba0282145fff054498e60e19a65')
    version('9.0.1', sha256='f6f484cfcd51e489afe88031afdea1e173aa652697e4c19ddbcb8260579a10f7')
    version('9.0.0', sha256='4387476a1933f36fec1531178ea204057bbeb04cc2d8396c9ea32720a1f7e264')

    variant('osmesa', default=False, description='Enable OSMesa instead of libGL')

    depends_on('gl@3:')
    depends_on('osmesa', when='+osmesa')

    # Since pacakges like mesa provide both gl and osmesa this will prevent
    # consuming packages from getting a glu tied to a differnt gl library
    provides('glu@1.3', when='~osmesa')

    def configure_args(self):
        args = []
        args.extend(self.enable_or_disable('osmesa'))

        return args

    @property
    def libs(self):
        for dir in ['lib64', 'lib']:
            libs = find_libraries('libGLU', join_path(self.prefix, dir),
                                  shared=True, recursive=False)
            if libs:
                return libs

    def configure_args(self):
        if self.spec.target == 'x86':
            return ['CFLAGS=-m32', 'CPPFLAGS=-m32', 'CXXFLAGS=-m32', 'LDFLAGS=-m32']

        return []
