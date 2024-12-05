#!/bin/bash

# This script should be executed after generating a new `LibP4est.jl` bindings file using Clang.jl
# via `generator.jl`. It corrects a number of issues that are not (easily) fixable through Clang.jl alone.
# Note for macOS users: This script needs to be run on a Linux machine, since `sed` cannot be
#                       used in a portable manner with `-i` on Linux and macOS systems. Sorry!

LIB_JL="Libt8.jl"

set -euxo pipefail

sed -i "s/using CEnum/using CEnum: @cenum/g" "${LIB_JL}"

# Remove Fortran macros
sed -i "/INTEGER(KIND/d" "${LIB_JL}"

# Remove other probably unused macros
sed -i "/P4EST_NOTICE/d" "${LIB_JL}"
sed -i "/P4EST_GLOBAL_NOTICE/d" "${LIB_JL}"

# Fix MPI types that have been wrongly converted to Julia types
sed -i "s/mpicomm::Cint/mpicomm::MPI_Comm/g" "${LIB_JL}"
sed -i "s/\bcomm::Cint/comm::MPI_Comm/g" "${LIB_JL}"
sed -i "s/\bintranode::Ptr{Cint}/intranode::Ptr{MPI_Comm}/g" "${LIB_JL}"
sed -i "s/\binternode::Ptr{Cint}/internode::Ptr{MPI_Comm}/g" "${LIB_JL}"
sed -i "s/mpifile::Cint/mpifile::MPI_File/g" "${LIB_JL}"
sed -i "s/mpidatatype::Cint/mpidatatype::MPI_Datatype/g" "${LIB_JL}"
sed -i "s/\bt::Cint/t::MPI_Datatype/g" "${LIB_JL}"

sed -i "s/t8_forest_get_mpicomm\(forest::t8_forest_t\)::Cint/t8_forest_get_mpicomm(forest::t8_forest_t)::MPI_Comm/g" "${LIB_JL}"

sed -i "s/forest::Cint/forest::t8_forest_t/" "${LIB_JL}"


# Use libsc for `sc_*` functions
sed -i "s/libt8\.sc_/libsc.sc_/g" "${LIB_JL}"

# Use libp4est for `p4est_*` functions
sed -i "s/libt8\.p4est_/libp4est.p4est_/g" "${LIB_JL}"

# Use libp4est for `p6est_*` functions
sed -i "s/libt8\.p6est_/libp4est.p6est_/g" "${LIB_JL}"

# Use libp4est for `p8est_*` functions
sed -i "s/libt8\.p8est_/libp4est.p8est_/g" "${LIB_JL}"


# Fix type of `sc_array` field `array`
sed -i "s/array::Cstring/array::Ptr{Int8}/g" "${LIB_JL}"

# Remove cross references that are not found
sed -i "s/\[\`p4est\`](@ref)/\`p4est\`/g" "${LIB_JL}"
sed -i "s/\[\`p6est\`](@ref)/\`p6est\`/g" "${LIB_JL}"
sed -i "s/\[\`p8est\`](@ref)/\`p8est\`/g" "${LIB_JL}"
sed -i "s/\[\`P4EST_QMAXLEVEL\`](@ref)/\`P4EST_QMAXLEVEL\`/g" "${LIB_JL}"
sed -i "s/\[\`P8EST_QMAXLEVEL\`](@ref)/\`P8EST_QMAXLEVEL\`/g" "${LIB_JL}"
sed -i "s/\[\`P4EST_CONN_DISK_PERIODIC\`](@ref)/\`P4EST_CONN_DISK_PERIODIC\`/g" "${LIB_JL}"
sed -i "s/\[\`p8est_iter_corner_side_t\`](@ref)/\`p8est_iter_corner_side_t\`/g" "${LIB_JL}"
sed -i "s/\[\`p8est_iter_edge_side_t\`](@ref)/\`p8est_iter_edge_side_t\`/g" "${LIB_JL}"
sed -i "s/\[\`p4est_corner_info_t\`](@ref)/\`p4est_corner_info_t\`/g" "${LIB_JL}"
sed -i "s/\[\`p8est_corner_info_t\`](@ref)/\`p8est_corner_info_t\`/g" "${LIB_JL}"
sed -i "s/\[\`p8est_edge_info_t\`](@ref)/\`p8est_edge_info_t\`/g" "${LIB_JL}"
sed -i "s/\[\`sc_MPI_Barrier\`](@ref)/\`sc_MPI_Barrier\`/g" "${LIB_JL}"
sed -i "s/\[\`sc_MPI_COMM_NULL\`](@ref)/\`sc_MPI_COMM_NULL\`/g" "${LIB_JL}"
sed -i "s/\[\`SC_CHECK_ABORT\`](@ref)/\`SC_CHECK_ABORT\`/g" "${LIB_JL}"
sed -i "s/\[\`SC_LP_DEFAULT\`](@ref)/\`SC_LP_DEFAULT\`/g" "${LIB_JL}"
sed -i "s/\[\`SC_LC_NORMAL\`](@ref)/\`SC_LC_NORMAL\`/g" "${LIB_JL}"
sed -i "s/\[\`SC_LC_GLOBAL\`](@ref)/\`SC_LC_GLOBAL\`/g" "${LIB_JL}"
sed -i "s/\[\`SC_LP_ALWAYS\`](@ref)/\`SC_LP_ALWAYS\`/g" "${LIB_JL}"
sed -i "s/\[\`SC_LP_SILENT\`](@ref)/\`SC_LP_SILENT\`/g" "${LIB_JL}"
sed -i "s/\[\`SC_LP_THRESHOLD\`](@ref)/\`SC_LP_THRESHOLD\`/g" "${LIB_JL}"
sed -i "s/\[\`sc_logf\`](@ref)/\`sc_logf\`/g" "${LIB_JL}"

# For nicer docstrings
sed -i "s/\`p4est\`.h/\`p4est.h\`/g" "${LIB_JL}"
sed -i "s/\`p8est\`.h/\`p8est.h\`/g" "${LIB_JL}"

sed -i "/_sc_const/d" "${LIB_JL}"
sed -i "/_sc_restrict/d" "${LIB_JL}"
sed -i "/sc_keyvalue_t/d" "${LIB_JL}"

sed -i "/T8_VERSION_POINT/d" "${LIB_JL}"
sed -i "/P4EST_VERSION_POINT/d" "${LIB_JL}"

sed -i "/P4EST_GLOBAL_NOTICE/d" "${LIB_JL}"
sed -i "/P4EST_NOTICE/d" "${LIB_JL}"

sed -i "/P4EST_F90_QCOORD/d" "${LIB_JL}"
sed -i "/P4EST_F90_TOPIDX/d" "${LIB_JL}"
sed -i "/P4EST_F90_LOCIDX/d" "${LIB_JL}"
sed -i "/P4EST_F90_GLOIDX/d" "${LIB_JL}"

sed -i "/MPI_ERR_GROUP/d" "${LIB_JL}"

sed -i "/SC_VERSION_POINT/d" "${LIB_JL}"

sed -i "/sc_MPI_PACKED/d" "${LIB_JL}"
sed -i "/sc_MPI_Pack/d" "${LIB_JL}"
sed -i "/sc_MPI_Unpack/d" "${LIB_JL}"

sed -i "/= MPI_MODE_/d" "${LIB_JL}"
sed -i "/= MPI_SEEK_/d" "${LIB_JL}"
sed -i "/= MPI_ERR_/d" "${LIB_JL}"
sed -i "/= MPI_MAX_/d" "${LIB_JL}"
sed -i "/= MPI_Type_/d" "${LIB_JL}"
sed -i "/= MPI_Offset/d" "${LIB_JL}"
sed -i "/= MPI_File_/d" "${LIB_JL}"

sed -i "s/= MPI_/= MPI./" "${LIB_JL}"

sed -i "s/packageid/package_id/" "${LIB_JL}"

cat << EOT >&2

# !!!!!! #
# !!!!!! #

# Manual fix. #

Additionally, comment out

  struct t8_forest
    [...]
  end

and add

  mutable struct t8_forest end

in order to avoid error output due to
circular dependency of 't8_forest_t'.

# !!!!!! #
# !!!!!! #
EOT
