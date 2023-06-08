using Pkg
Pkg.activate(@__DIR__)
Pkg.instantiate()

using Artifacts
cp(joinpath(artifact"t8code", "include"), "t8code_include"; force = true)

# cp("/usr/include/math.h", joinpath(@__DIR__, "t8code_include/math.h"))

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

# add compiler flags, e.g. "-DXXXXXXXXX"
# args = get_default_args()  # Note you must call this function firstly and then append your own flags

args = get_default_args("x86_64-linux-gnu")

# push!(args, "-I/usr/include")
push!(args, "-I$include_dir")
# push!(args, "-include math.h")
# push!(args, "-D__GLIBC_USE\\(...\\)=0")

# push!(args, "-D__MATHDECL_VEC(type, function,suffix, args) __SIMD_DECL (__MATH_PRECNAME (function, suffix)) __MATHDECL(type, function,suffix, args)")

headers_rel = [
  # "/usr/include/math.h"
  "t8.h"
  "t8_cmesh.h"
  "t8_cmesh_netcdf.h"
  "t8_cmesh_readmshfile.h"
  "t8_cmesh_tetgen.h"
  "t8_cmesh_triangle.h"
  "t8_cmesh_vtk_writer.h"
  "t8_config.h"
  "t8_eclass.h"
  "t8_element.h"
  "t8_element_c_interface.h"
  "t8_element_shape.h"
  "t8_example_common.h"
  "t8_mesh.h"
  "t8_netcdf.h"
  "t8_vec.h"
  "t8_vtk.h"
  "t8_forest_netcdf.h"
  joinpath("t8_cmesh", "t8_cmesh_examples.h")
  joinpath("t8_cmesh", "t8_cmesh_geometry.h")
  joinpath("t8_cmesh", "t8_cmesh_save.h")
  joinpath("t8_cmesh", "t8_cmesh_testcases.h")
  # joinpath("t8_cmesh", "t8_cmesh_trees.h")
  joinpath("t8_forest", "t8_forest_adapt.h")
  # joinpath("t8_forest", "t8_forest_balance.h")
  # joinpath("t8_forest", "t8_forest_cxx.h")
  joinpath("t8_forest", "t8_forest_general.h")
  joinpath("t8_forest", "t8_forest_geometrical.h")
  # joinpath("t8_forest", "t8_forest_ghost.h")
  joinpath("t8_forest", "t8_forest_io.h")
  joinpath("t8_forest", "t8_forest_iterate.h")
  joinpath("t8_forest", "t8_forest_partition.h")
  joinpath("t8_forest", "t8_forest_profiling.h")
  # joinpath("t8_forest", "t8_forest_types.h")
  joinpath("t8_forest", "t8_forest_vtk.h")
  joinpath("t8_geometry", "t8_geometry.h")
  joinpath("t8_geometry", "t8_geometry_base.h")
  joinpath("t8_geometry", "t8_geometry_helpers.h")
  joinpath("t8_schemes", "t8_default", "t8_default_c_interface.h")
]
headers = [joinpath(include_dir, header) for header in headers_rel]

# create context
ctx = create_context(headers, args, options)

# run generator
build!(ctx)
