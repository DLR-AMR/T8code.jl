#!/bin/bash

# This script should be executed after generating a new `LibP4est.jl` bindings file using Clang.jl
# via `generator.jl`. It corrects a number of issues that are not (easily) fixable through Clang.jl alone.
# Note for macOS users: This script needs to be run on a Linux machine, since `sed` cannot be
#                       used in a portable manner with `-i` on Linux and macOS systems. Sorry!

LIB_JL="Libt8.jl"

set -euxo pipefail

# Fix MPI types that have been wrongly converted to Julia types
sed -i "s/mpicomm::Cint/mpicomm::MPI_Comm/g" "${LIB_JL}"
sed -i "s/\bcomm::Cint/comm::MPI_Comm/g" "${LIB_JL}"
sed -i "s/\bintranode::Ptr{Cint}/intranode::Ptr{MPI_Comm}/g" "${LIB_JL}"
sed -i "s/\binternode::Ptr{Cint}/internode::Ptr{MPI_Comm}/g" "${LIB_JL}"
sed -i "s/mpifile::Cint/mpifile::MPI_File/g" "${LIB_JL}"

sed -i "s/t8_forest_get_mpicomm(forest::t8_forest_t)::Cint/t8_forest_get_mpicomm(forest::t8_forest_t)::MPI_Comm/g" "${LIB_JL}"

# Remove struct t8_forest definition and replace by forward declaration
sed -i -z 's/\nstruct t8_forest.*stats_computed::Cint\nend/\n# This struct is not supposed to be read and modified directly.\n# Besides, there is a circular dependency with `t8_forest_t`\n# leading to an error output by Julia.\nmutable struct t8_forest end/g' "${LIB_JL}"

# Fix forest type
sed -i "s/forest::Cint/forest::t8_forest_t/" "${LIB_JL}"

# Rename remaining MPI macros
sed -i "s/= MPI_/= MPI./" "${LIB_JL}"
