# STAR Spack Package Repository

## Build caches

The Dockerfile has two explicit Spack buildcache modes. In both modes,
`spack_cache_image` defaults to
`ghcr.io/star-bnl/star-spack:spack-buildcache`, which must contain a Spack
binary mirror at `/opt/spack-buildcache`.

### Consume the buildcache (default)

Normal builds use packages from the mirror first and compile cache misses from
source. Successfully installed packages are also added to the local BuildKit
cache mount named `star-spack-buildcache`, but no buildcache image is exported
or included in the runtime image.

```shell
docker build \
  --build-arg starenv=root5 \
  --build-arg compiler=gcc11 \
  --tag star-spack:root5-gcc11 \
  .
```

Runtime binaries and libraries are stripped by default to minimize the final
image. For a faster validation build that does not optimize image size, add
`--build-arg optimize_runtime=false`.

To consume another compatible mirror image, override
`spack_cache_image=<image>`. The image must provide
`/opt/spack-buildcache/build_cache/index.json` and its referenced package
archives.

### Rebuild and export the buildcache

After a normal build compiles new packages, set
`rebuild_spack_buildcache=true` and select the `spack-buildcache` target. The
installation steps are identical in both modes, so this command can reuse the
completed Spack layers from the normal build. It ensures all installed packages
are present in the named cache mount, rebuilds the mirror index, and exports the
updated mirror image.

```shell
docker build \
  --target spack-buildcache \
  --build-arg rebuild_spack_buildcache=true \
  --build-arg starenv=root5 \
  --build-arg compiler=gcc485 \
  --build-arg spack_cache_export_revision="$(date +%s)" \
  --tag ghcr.io/star-bnl/star-spack:spack-buildcache \
  --push .
```

Use the same builder for successive rebuilds: the
`star-spack-buildcache` cache-mount ID and Docker layer cache are local to a
builder. With the same builder and unchanged build inputs, switching to the
`spack-buildcache` target does not compile the packages again. The exported
image is a shared mirror, so repeat the rebuild command for each affected
environment/compiler combination while pushing the same tag.

For the one-time creation of a cache when no prior image exists, add:

```shell
--build-arg spack_cache_image=spack-cache-empty-stage
```

In CI, every runtime build uses the default cache-first mode with source
fallback. Pull requests build and test all environment/compiler combinations
without stripping the runtime files and do not publish images or the local
mirror. Pushes to `main` perform the size optimization, publish
`latest-<env>-<compiler>` images in parallel, but do not update either cache.
Tags also perform the size optimization and publish `<tag>-<env>-<compiler>`
images without updating the caches. Run the `Update Spack Buildcache` workflow
manually when package or environment changes require a refresh. Its matrix runs
sequentially so each entry consumes the shared mirror published by the previous
entry, and it also updates the separate
`buildkit-cache-<env>-<compiler>` registry caches.
