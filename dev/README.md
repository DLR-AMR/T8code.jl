# Building Julia bindings of `t8code` with Clang.jl

The general process for creating bindings with Clang.jl is as follows:

1. Create a `generator.jl` file with the relevant Julia code (not a lot).
2. Create a corresponding `generator.toml` file with certain settings.
3. Run `julia generator.jl` to create new file `Libt8.jl`.
4. Apply manual fixes using `./fixes.sh`
5. Run `julia Libt8.jl`.
6. Get error(s).
7. Try to finagle something with `generator.toml`, `prologue.jl`/`epilogue.jl`,
   or `fixes.sh`.
8. Go back to 3.

To generate new bindings, run
```shell
julia --project generator.jl && ./fixes.sh
```
to create a new `Libt8.jl` file.

More information can be found in https://github.com/trixi-framework/P4est.jl
