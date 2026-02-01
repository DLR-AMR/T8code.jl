using Pkg
Pkg.activate(@__DIR__)
Pkg.instantiate()

using Artifacts
cp(joinpath(artifact"t8code", "include"), "t8code_include"; force = true)

using Glob

# This loads the artifact described in `Artifacts.toml`.
# See README.md for instructions on how to update.

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
