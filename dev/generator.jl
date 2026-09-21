using Pkg
Pkg.activate(@__DIR__)
Pkg.instantiate()

# This loads the artifact described in `Artifacts.toml`.
# See README.md for instructions on how to update.
using Artifacts
cp(joinpath(artifact"t8code", "include"), "t8code_include"; force = true)

using Glob
using Clang.Generators

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

# `t8_dtri_to_dtet.h` redefines the triangle macros, types and functions to their
# tetrahedron counterparts, so that the triangle implementation can be reused for
# tetrahedra. Parsing it would turn the `t8_dtri_*` functions into mere aliases of
# `t8_dtet_*`, even though both are separate symbols in `libt8`.
filter!(h -> basename(h) != "t8_dtri_to_dtet.h", headers)

# create context
ctx = create_context(headers, args, options)

# run generator
build!(ctx)
