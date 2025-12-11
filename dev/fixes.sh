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

sed -i "s/forest::Cint/forest::t8_forest_t/" "${LIB_JL}"

# Remove Fortran macros
sed -i "/INTEGER(KIND/d" "${LIB_JL}"

# Remove local arrays
sed -i "/T8_.*_VALUES/d" "${LIB_JL}"

# Remove misc
sed -i "/T8_VERSION_POINT/d" "${LIB_JL}"

sed -i "/P4EST_GLOBAL_NOTICE/d" "${LIB_JL}"
sed -i "/P4EST_NOTICE/d" "${LIB_JL}"

sed -i "/_sc_const/d" "${LIB_JL}"
sed -i "/_sc_restrict/d" "${LIB_JL}"

# Remove MPI macros not available in MPI.jl
sed -i "/sc_MPI_PACKED/d" "${LIB_JL}"
sed -i "/sc_MPI_Pack/d" "${LIB_JL}"
sed -i "/sc_MPI_Unpack/d" "${LIB_JL}"
sed -i "/sc_MPI_DOUBLE_INT/d" "${LIB_JL}"

sed -i "/= MPI_MODE_/d" "${LIB_JL}"
sed -i "/= MPI_SEEK_/d" "${LIB_JL}"
sed -i "/= MPI_ERR_/d" "${LIB_JL}"
sed -i "/= MPI_MAX_/d" "${LIB_JL}"
sed -i "/= MPI_Type_/d" "${LIB_JL}"
sed -i "/= MPI_Offset/d" "${LIB_JL}"
sed -i "/= MPI_File_/d" "${LIB_JL}"
sed -i "/= MPI_Aint/d" "${LIB_JL}"

sed -i "s/= MPI_/= MPI./" "${LIB_JL}"
