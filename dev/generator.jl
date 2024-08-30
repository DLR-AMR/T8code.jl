using Pkg
Pkg.activate(@__DIR__)
Pkg.instantiate()

using Artifacts
cp(joinpath(artifact"t8code", "include"), "t8code_include"; force = true)

using Glob

# This loads the artifact described in `P4est/dev/Artifacts.toml`.
# When a new release of P4est_jll.jl is created and you would like to update
# the headers, you can copy one of the entries of
# https://github.com/JuliaBinaryWrappers/P4est_jll.jl/blob/main/Artifacts.toml
# to this file. Here, we chose the version
# linux - x86_64 - glibc - mpich
# The exact choice should not matter since we use only the header files which
# are the same on each system. However, they may matter in the presence of
# MPI headers since we apply some custom `fixes.sh` afterwards.

using Clang.Generators
# using Clang.LibClang.Clang_jll  # replace this with your jll package

cd(@__DIR__)

include_dir = joinpath(@__DIR__, "t8code_include")

options = load_options(joinpath(@__DIR__, "generator.toml"))

args = get_default_args()  # Note you must call this function firstly and then append your own flags
push!(args, "-I$include_dir")

headers = [
  glob("t8_*.h", include_dir) ; 
  glob("**/t8_*.h", include_dir) ; 
  glob("**/**/t8_*.h", include_dir) ;
  # glob("**/**/**/t8_*.h", include_dir)
]

# create context
ctx = create_context(headers, args, options)

# run generator
build!(ctx)
