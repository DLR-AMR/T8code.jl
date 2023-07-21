# This file is part of t8code.
# t8code is a C library to manage a collection (a forest) of multiple
# connected adaptive space-trees of general element types in parallel.
#
# Copyright (C) 2023 the developers
#
# t8code is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# t8code is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with t8code; if not, write to the Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.

# See also: https://github.com/DLR-AMR/t8code/wiki/Step-6-Computing-stencils
# 
# This is step6 of the t8code tutorials using the C++ interface of t8code.
# In the following we will store data in the individual elements of our forest. 
# To do this, we will create a uniform forest in 2D, which will get adapted, 
# partitioned, balanced and create ghost elements all in one go.
# After adapting the forest we build a data array and gather data for 
# the local elements. Next, we exchange the data values of the ghost elements and compute
# various stencils resp. finite differences. Finally, vtu files are stored with three
# custom data fields.
# 
# How you can experiment here:
#   - Look at the paraview output files of the adapted forest.
#   - Change the adaptation criterion as you wish to adapt elements or families as desired.
#   - Store even more data per element, for instance the coordinates of its midpoint.
#   - Extend this step to 3D.

using MPI
using T8code
using T8code.Libt8: sc_init
using T8code.Libt8: sc_free
using T8code.Libt8: sc_finalize
using T8code.Libt8: sc_array_new_data
using T8code.Libt8: sc_array_destroy
using T8code.Libt8: SC_LP_ESSENTIAL
using T8code.Libt8: SC_LP_PRODUCTION

include("t8_step3_common.jl")

# The data that we want to store for each element.
struct t8_step6_data_per_element_t
  # The first three data fields are not necessary for our
  # computations in this step, but are left here for reference.

  level :: Cint

  volume :: Cdouble
  midpoint :: NTuple{3,Cdouble}

  # Element length in x- and y-direction.
  dx :: Cdouble
  dy :: Cdouble

  # `Height` which is filled according to the position of the element.
  # in the computational domain.
  height :: Cdouble

  # Storage for our finite difference computations.
  schlieren :: Cdouble
  curvature :: Cdouble
end

# In this function we first allocate a new uniformly refined forest at given
# refinement level. Then a second forest is created, where user data for the
# adaption call (cf. step 3) is registered.  The second forest inherts all
# properties of the first ("root") forest and deallocates it. The final
# adapted and commited forest is returned back to the calling scope.
function t8_step6_build_forest(comm, dim, level)
  cmesh = t8_cmesh_new_periodic(comm, dim)

  scheme = t8_scheme_new_default_cxx()

  adapt_data = t8_step3_adapt_data_t(
    (0.0, 0.0, 0.0),      # Midpoints of the sphere.
    0.5,                  # Refine if inside this radius.
    0.7                   # Coarsen if outside this radius.
  )

  # Start with a uniform forest.
  forest = t8_forest_new_uniform(cmesh, scheme, level, 0, comm)

  forest_apbg_ref = Ref(t8_forest_t())
  t8_forest_init(forest_apbg_ref)
  forest_apbg = forest_apbg_ref[]

  # Adapt, partition, balance and create ghost elements all in one go.
  # See steps 3 and 4 for more details.
  t8_forest_set_user_data(forest_apbg, Ref(adapt_data))
  t8_forest_set_adapt(forest_apbg, forest, @t8_adapt_callback(t8_step3_adapt_callback), 0)
  t8_forest_set_partition(forest_apbg, C_NULL, 0)
  t8_forest_set_balance(forest_apbg, C_NULL, 0)
  t8_forest_set_ghost(forest_apbg, 1, T8_GHOST_FACES)
  t8_forest_commit(forest_apbg)

  return forest_apbg
end

# Allocate and fill the element data array with `heights` from an arbitrary
# mathematical function. Returns a pointer to the array which is then ownded by
# the calling scope.
function t8_step6_create_element_data(forest)
  # Check that the forest is a committed.
  @T8_ASSERT(t8_forest_is_committed(forest) == 1)

  # Get the number of local elements of forest.
  num_local_elements = t8_forest_get_local_num_elements(forest)
  # Get the number of ghost elements of forest.
  num_ghost_elements = t8_forest_get_num_ghosts(forest)

  # Build an array of our data that is as long as the number of elements plus
  # the number of ghosts.
  element_data = Array{t8_step6_data_per_element_t}(undef, num_local_elements + num_ghost_elements)

  # Get the number of trees that have elements of this process.
  num_local_trees = t8_forest_get_num_local_trees(forest)

  # Compute vertex coordinates. Note: Julia has column-major.
  verts = Matrix{Cdouble}(undef,3,3)

  # Element Midpoint
  midpoint = Vector{Cdouble}(undef,3)

  # Loop over all local trees in the forest.
  current_index = 0
  for itree = 0:num_local_trees-1
    tree_class = t8_forest_get_tree_class(forest, itree)
    eclass_scheme = t8_forest_get_eclass_scheme(forest, tree_class)

    # Get the number of elements of this tree.
    num_elements_in_tree = t8_forest_get_tree_num_elements(forest, itree)

    # Loop over all local elements in the tree.
    for ielement = 0:num_elements_in_tree-1
      current_index += 1 # Note: Julia has 1-based indexing, while C/C++ starts with 0.

      element = t8_forest_get_element_in_tree(forest, itree, ielement)

      level = t8_element_level(eclass_scheme, element)
      volume = t8_forest_element_volume(forest, itree, element)

      t8_forest_element_centroid(forest, itree, element, pointer(midpoint))

      t8_element_vertex_reference_coords(eclass_scheme, element, 0, @view(verts[:,1]))
      t8_element_vertex_reference_coords(eclass_scheme, element, 1, @view(verts[:,2]))
      t8_element_vertex_reference_coords(eclass_scheme, element, 2, @view(verts[:,3]))

      dx = verts[1,2] - verts[1,1]
      dy = verts[2,3] - verts[2,1]

      # Shift x and y to the center since the domain is [0,1] x [0,1].
      x = midpoint[1] - 0.5
      y = midpoint[2] - 0.5
      r = sqrt(x * x + y * y) * 20.0      # arbitrarly scaled radius

      # Some 'interesting' height function.
      height = sin(2.0 * r) / r

      element_data[current_index] = t8_step6_data_per_element_t(
        level, volume, Tuple(midpoint), dx, dy, height, 0.0, 0.0
      )
    end
  end

  return element_data
end

# Gather the 3x3 stencil for each element and compute finite difference approximations
# for schlieren and curvature of the stored heights in the elements.
function t8_step6_compute_stencil(forest, element_data)
  # Check that forest is a committed, that is valid and usable, forest.
  @T8_ASSERT(t8_forest_is_committed(forest) == 1)

  # Get the number of trees that have elements of this process. 
  num_local_trees = t8_forest_get_num_local_trees(forest)

  stencil = Matrix{Cdouble}(undef, 3, 3)
  dx = Vector{Cdouble}(undef, 3)
  dy = Vector{Cdouble}(undef, 3)

  # Loop over all local trees in the forest. For each local tree the element
  # data (level, midpoint[3], dx, dy, volume, height, schlieren, curvature) of
  # each element is calculated and stored into the element data array.
  current_index = 0
  for itree = 0:num_local_trees-1
    tree_class = t8_forest_get_tree_class(forest, itree)
    eclass_scheme = t8_forest_get_eclass_scheme(forest, tree_class)

    num_elements_in_tree = t8_forest_get_tree_num_elements(forest, itree)

    # Loop over all local elements in the tree.
    for ielement = 0:num_elements_in_tree-1
      current_index += 1 # Note: Julia has 1-based indexing, while C/C++ starts with 0.

      element = t8_forest_get_element_in_tree(forest, itree, ielement)

      # Gather center point of the 3x3 stencil.
      stencil[2,2] = element_data[current_index].height
      dx[2] = element_data[current_index].dx
      dy[2] = element_data[current_index].dy

      # Loop over all faces of an element.
      num_faces = t8_element_num_faces(eclass_scheme, element)
      for iface = 1:num_faces
        neighids_ref = Ref{Ptr{t8_locidx_t}}()
        neighbors_ref = Ref{Ptr{Ptr{t8_element}}}()
        neigh_scheme_ref = Ref{Ptr{t8_eclass_scheme}}()

        dual_faces_ref = Ref{Ptr{Cint}}()
        num_neighbors_ref = Ref{Cint}()

        forest_is_balanced = Cint(1)

        t8_forest_leaf_face_neighbors(forest, itree, element,
          neighbors_ref, iface-1, dual_faces_ref, num_neighbors_ref,
          neighids_ref, neigh_scheme_ref, forest_is_balanced)

        num_neighbors = num_neighbors_ref[]
        dual_faces    = 1 .+ unsafe_wrap(Array, dual_faces_ref[], num_neighbors)
        neighids      = 1 .+ unsafe_wrap(Array, neighids_ref[], num_neighbors)
        neighbors     = unsafe_wrap(Array, neighbors_ref[], num_neighbors)
        neigh_scheme  = neigh_scheme_ref[]

        # Retrieve the `height` of the face neighbor. Account for two neighbors
        # in case of a non-conforming interface by computing the average.
        height = 0.0
        if num_neighbors > 0
          for ineigh = 1:num_neighbors
            height = height + element_data[neighids[ineigh]].height
          end
          height = height / num_neighbors
        end

        # Fill in the neighbor information of the 3x3 stencil.
        if iface == 1 # NORTH
          stencil[1,2] = height
          dx[1] = element_data[neighids[1]].dx
        elseif iface == 2 # SOUTH
          stencil[3,2] = height
          dx[3] = element_data[neighids[1]].dx
        elseif iface == 3 # WEST
          stencil[2,1] = height
          dy[1] = element_data[neighids[1]].dy
        elseif iface == 4 # EAST
          stencil[2,3] = height
          dy[3] = element_data[neighids[1]].dy
        end

        # Free allocated memory.
        sc_free(t8_get_package_id(), neighbors_ref[])
        sc_free(t8_get_package_id(), dual_faces_ref[])
        sc_free(t8_get_package_id(), neighids_ref[])
      end

      # Prepare finite difference computations. The code also accounts for non-conforming interfaces.
      xslope_m = 0.5 / (dx[1] + dx[2]) * (stencil[2,2] - stencil[1,2])
      xslope_p = 0.5 / (dx[2] + dx[3]) * (stencil[3,2] - stencil[2,2])

      yslope_m = 0.5 / (dy[1] + dy[2]) * (stencil[2,2] - stencil[2,1])
      yslope_p = 0.5 / (dy[2] + dy[3]) * (stencil[2,3] - stencil[2,2])

      xslope = 0.5 * (xslope_m + xslope_p)
      yslope = 0.5 * (yslope_m + yslope_p)

      # TODO: Probably still not optimal at non-conforming interfaces.
      xcurve = (xslope_p - xslope_m) * 4 / (dx[1] + 2.0 * dx[2] + dx[3])
      ycurve = (yslope_p - yslope_m) * 4 / (dy[1] + 2.0 * dy[2] + dy[3])

      # Compute schlieren and curvature norm.
      schlieren = sqrt(xslope * xslope + yslope * yslope)
      curvature = sqrt(xcurve * xcurve + ycurve * ycurve)

      element_data[current_index] = t8_step6_data_per_element_t(
        element_data[current_index].level, 
        element_data[current_index].volume,
        element_data[current_index].midpoint,
        element_data[current_index].dx,
        element_data[current_index].dy,
        element_data[current_index].height,
        schlieren, 
        curvature
      )
    end
  end
end

# Each process has computed the data entries for its local elements.  In order
# to get the values for the ghost elements, we use
# t8_forest_ghost_exchange_data.  Calling this function will fill all the ghost
# entries of our element data array with the value on the process that owns the
# corresponding element. */
function t8_step6_exchange_ghost_data(forest, element_data)
  # t8_forest_ghost_exchange_data expects an sc_array (of length num_local_elements + num_ghosts).
  # We wrap our data array to an sc_array.
  sc_array_wrapper = sc_array_new_data(pointer(element_data), sizeof(t8_step6_data_per_element_t), length(element_data))

  # Carry out the data exchange. The entries with indices > num_local_elements will get overwritten.
  t8_forest_ghost_exchange_data(forest, sc_array_wrapper)

  # Destroy the wrapper array. This will not free the data memory since we used sc_array_new_data.
  sc_array_destroy(sc_array_wrapper)
end

# Write the forest as vtu and also write the element's volumes in the file.
# 
# t8code supports writing element based data to vtu as long as its stored
# as doubles. Each of the data fields to write has to be provided in its own
# array of length num_local_elements.
# We support two types: T8_VTK_SCALAR - One double per element.
#                  and  T8_VTK_VECTOR - Three doubles per element.
function t8_step6_output_data_to_vtu(forest, element_data, prefix)
  num_elements = length(element_data)

  # We need to allocate a new array to store the data on their own.
  # These arrays have one entry per local element.
  heights = Vector{Cdouble}(undef, num_elements)
  schlieren = Vector{Cdouble}(undef, num_elements)
  curvature = Vector{Cdouble}(undef, num_elements)

  # Copy the elment's volumes from our data array to the output array.
  for ielem = 1:num_elements
    heights[ielem] = element_data[ielem].height
    schlieren[ielem] = element_data[ielem].schlieren
    curvature[ielem] = element_data[ielem].curvature
  end

  # WARNING: This code hangs for Julia v1.8.* or older. Use at least Julia v1.9.
  vtk_data = [
    t8_vtk_data_field_t(
      T8_VTK_SCALAR,
      NTuple{8192, Cchar}(rpad("height\0", 8192, ' ')),
      pointer(heights),
    ),
    t8_vtk_data_field_t(
      T8_VTK_SCALAR,
      NTuple{8192, Cchar}(rpad("schlieren\0", 8192, ' ')),
      pointer(schlieren),
    ),
    t8_vtk_data_field_t(
      T8_VTK_SCALAR,
      NTuple{8192, Cchar}(rpad("curvature\0", 8192, ' ')),
      pointer(curvature),
    )
  ]

  # The number of user defined data fields to write.
  num_data = length(vtk_data)

  # Write user defined data to vtu file.
  write_treeid = 1
  write_mpirank = 1
  write_level = 1
  write_element_id = 1
  write_ghosts = 0
  t8_forest_write_vtk_ext(forest, prefix, write_treeid, write_mpirank,
                           write_level, write_element_id, write_ghosts,
                           0, 0, num_data, pointer(vtk_data))
end

# The prefix for our output files.
prefix_forest_with_data = "t8_step6_stencil"

# The uniform refinement level of the forest.
dim = 2
level = 6

#
# Initialization.
#

# Initialize MPI. This has to happen before we initialize sc or t8code.
mpiret = MPI.Init()

# We will use MPI_COMM_WORLD as a communicator.
comm = MPI.COMM_WORLD

# Initialize the sc library, has to happen before we initialize t8code.
sc_init(comm, 1, 1, C_NULL, SC_LP_ESSENTIAL)
# Initialize t8code with log level SC_LP_PRODUCTION. See sc.h for more info on the log levels.
t8_init(SC_LP_PRODUCTION)

# Initialize an adapted forest with periodic boundaries.
forest = t8_step6_build_forest(comm, dim, level)

#
# Data handling and computation.
#

# Build data array and gather data for the local elements.
element_data = t8_step6_create_element_data(forest)

# Exchange the neighboring data at MPI process boundaries.
t8_step6_exchange_ghost_data(forest, element_data)

# Compute stencil.
t8_step6_compute_stencil(forest, element_data)

# Output the data to vtu files.
t8_step6_output_data_to_vtu(forest, element_data, prefix_forest_with_data)
t8_global_productionf(" Wrote forest and data to %s*.\n", prefix_forest_with_data)

#
# Clean-up
#

# Destroy the forest.
t8_forest_unref(Ref(forest))
t8_global_productionf(" Destroyed forest.\n")

sc_finalize()
