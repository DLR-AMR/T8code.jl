using Pkg
Pkg.activate(@__DIR__)
Pkg.instantiate()

# This loads the artifact described in `Artifacts.toml`.
# See README.md for instructions on how to update.
using Artifacts
cp(joinpath(artifact"t8code", "include"), "t8code_include"; force = true)

using Clang.Generators

cd(@__DIR__)

include_dir = joinpath(@__DIR__, "t8code_include")

options = load_options(joinpath(@__DIR__, "generator.toml"))

args = get_default_args()  # Note you must call this function firstly and then append your own flags
push!(args, "-I$include_dir")

filter_out = (x -> !startswith(basename(x), "t8_") ||
                   !endswith(basename(x), ".h") ||
                   basename(x) == "t8_dtri_to_dtet.h")  # this header contains redefinitions which seem harmful

headers = detect_headers(include_dir, args, Dict(), filter_out)

# create context
ctx = create_context(headers, args, options)

# run generator
build!(ctx)
