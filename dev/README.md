# Generating Julia bindings of `t8code` with `Clang.jl`

Working with or deploying a new release of `T8code.jl` involves creating a new build of the
binary package `t8code_jll.jl`, and generating new bindings in `T8code.jl`.


## Updating `t8code_jll.jl`

### For local development

If you are developing `t8code`, you will probably want to use your locally compiled version
instead of `t8code_jll.jl`, as documented here:
https://github.com/DLR-AMR/T8code.jl?tab=readme-ov-file#using-a-custom-version-of-mpi-andor-t8code


### For deployment

If you want to provide a new `t8code` release for the Julia community, you need to trigger a
new build of the `t8code_jll.jl` bindary package. Building the binaries happens via
BinaryBuilder, documented here:
https://docs.binarybuilder.org/stable/.
It boils down to checking out
https://github.com/JuliaPackaging/Yggdrasil/tree/master/T/t8code,
editing `build_tarballs.jl` to at least reflect the latest version, tarball URL, and hash,
committing, and opening a pull request.

Even a draft PR will already trigger the buildkite
pipelines. Check the builds for any errors. Successful runs will produce the binary
packages as artifacts. You can find an URL to such an artifact in the buildkite output,
along with its tree hash and SHA256 hash, which can be used in `Artifacts.toml` described
below.

If you instead want to run BinaryBuilder locally you can do so by executing

```shell
julia +1.7 build_tarballs.jl --debug --verbose x86_64-linux-gnu --deploy=local
```

This requires a local Julia installation and Julia version 1.7. You can use any other
eligible platform triple instead of `x86_64-linux-gnu`. Adding `--deploy=local` will add
the created binaries to your local Julia artifacts folder.


## Updating `Tcode.jl`

Bindings are created using `Clang.jl`. The general process is as follows:

1. Create a `generator.jl` file with the relevant Julia code (not a lot).
2. Create a corresponding `generator.toml` file with certain settings.
3. Run `julia generator.jl` to create a new file `Libt8.jl`.
4. Apply manual fixes using `./fixes.sh`
5. Run `julia Libt8.jl`.
6. Get error(s).
7. Try to finagle something with `generator.toml`, `prologue.jl`, `epilogue.jl`,
   or `fixes.sh`.
8. Go back to 3.

The crucial ingredients are the `t8code` header files, which are expected in a subdirectory
`t8code_include` of the folder of this README. You have the following options:
- If you are developing `t8code` locally, you can copy and rename `t8code`'s `include`
  directory from its current prefix path. You will have to comment lines 5 and 6 (dealing with artifacts) in `generator.jl` then.
- If your pull request to Yggdrasil has already been merged, you can find the newly built
  binary packages at https://github.com/JuliaBinaryWrappers/t8code_jll.jl/releases. Copy an
  entry of https://github.com/JuliaBinaryWrappers/t8code_jll.jl/blob/main/Artifacts.toml to
  the local `Artifacts.toml` file. The exact choice of the platform triplet should not
  matter since we use only the header files which are the same on each system. However,
  they may matter in the presence of MPI headers since we apply some custom `fixes.sh`
  afterwards.
- If your pull request has not yet been accepted, you can instead use artifacts of the
  buildkite pipeline, see above.  
- If you ran BindaryBuilder locally, you can somehow use your local artifacts. But how?

In any case run
```shell
julia --project generator.jl && ./fixes.sh
```
next. If all goes well, move the new `Libt8.jl` file to `src/` and adapt the compat entry
in `Project.toml` to reflect the new version of `t8code_jll.jl`.

At this point you can test your new `T8code.jl` version locally, e.g. by creating a
subdirectory `run` at the `T8code.jl` root folder, and from there executing

```shell
julia --project=.

julia> using Pkg
julia> Pkg.develop(path="..")
julia> Pkg.test("T8code")
```

If actually all went well, go ahead and open a pull request.

Once this pull request has been merged, downstream packages can start adopting your new
t8code release!
