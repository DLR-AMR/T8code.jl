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

headers = [joinpath(include_dir, header) for header in readdir(include_dir) if endswith(header, ".h")]
# there is also an experimental `detect_headers` function for auto-detecting top-level headers in the directory
# headers = detect_headers(include_dir, args)

# create context
ctx = create_context(headers, args, options)

# run generator
build!(ctx)
