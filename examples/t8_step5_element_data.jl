# This file is part of t8code.
# t8code is a C library to manage a collection (a forest) of multiple
# connected adaptive space-trees of general element types in parallel.
#
# Copyright (C) 2015 the developers
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

# See also: https://github.com/holke/t8code/wiki/Step-5---Store-element-data
#
# This is step5 of the t8code tutorials using the C interface of t8code.
# In the following we will store data in the individual elements of our forest. 
# To do this, we will again create a uniform forest, which will get adapted as in step4, 
# with the difference that we partition, balance and create ghost elements all in the same step.
# After adapting the forest we will learn how to build a data array and gather data for 
# the local elements. Furthermore, we exchange the data values of the ghost elements and
# output the volume data to vtu.
#
# How you can experiment here:
#   - Look at the paraview output files of the adapted forest.
#     You can apply a clip filter to look into the cube. Also you can apply (in addition) 
#     the threshold filter to display only elements with certain properties.
#     But at first you may just want to enter the tooltip selection mode 'Hover Cells On'
#     to display cell information when hover over them.
#   - Change the adaptation criterion as you wish to adapt elements or families as desired.
#   - Store even more data per element, for instance the coordinates of its midpoint.
#     You can again apply the threshold filter to your new data. Don't forget to write the 
#     data into the output file.

using MPI
using T8code
using T8code.Libt8: sc_init
using T8code.Libt8: sc_finalize
using T8code.Libt8: sc_array_new_data
using T8code.Libt8: sc_array_destroy
using T8code.Libt8: SC_LP_ESSENTIAL
using T8code.Libt8: SC_LP_PRODUCTION

include("t8_step3_common.jl")

# The data that we want to store for each element.
# In this example we want to store the element's level and volume. */
struct t8_step5_data_per_element_t
  level   :: Cint
  volume  :: Cdouble
end

function t8_step5_build_forest(comm, level)
  cmesh = t8_cmesh_new_hypercube_hybrid(comm, 0, 0)
  scheme = t8_scheme_new_default_cxx()

  adapt_data = t8_step3_adapt_data_t(
    (0.5, 0.5, 1.0),      # Midpoints of the sphere.
    0.2,                  # Refine if inside this radius.
    0.4                   # Coarsen if outside this radius.
  )

  # Start with a uniform forest.
  forest = t8_forest_new_uniform(cmesh, scheme, level, 0, comm)

  # Adapt, partition, balance and create ghost elements all in the same step.
  forest_apbg_ref = Ref(t8_forest_t())
  t8_forest_init(forest_apbg_ref)
  forest_apbg = forest_apbg_ref[]

  t8_forest_set_user_data(forest_apbg, Ref(adapt_data))
  t8_forest_set_adapt(forest_apbg, forest, @t8_adapt_callback(t8_step3_adapt_callback), 0)
  t8_forest_set_partition(forest_apbg, C_NULL, 0)
  t8_forest_set_balance(forest_apbg, C_NULL, 0)
  t8_forest_set_ghost(forest_apbg, 1, T8_GHOST_FACES)
  t8_forest_commit(forest_apbg)

  return forest_apbg
end

function t8_step5_create_element_data(forest)
  # Check that forest is a committed, that is valid and usable, forest.
  @T8_ASSERT(t8_forest_is_committed(forest) == 1)

  # Get the number of local elements of forest.
  num_local_elements = t8_forest_get_local_num_elements(forest)
  # Get the number of ghost elements of forest.
  num_ghost_elements = t8_forest_get_num_ghosts(forest)

  # Now we need to build an array of our data that is as long as the number of
  # elements plus the number of ghosts. You can use any allocator such as new,
  # malloc or the t8code provide allocation macro T8_ALLOC.  Note that in the
  # latter case you need to use T8_FREE in order to free the memory.
  element_data = Array{t8_step5_data_per_element_t}(undef, num_local_elements + num_ghost_elements)

  # Note: We will later need to associate this data with an sc_array in order to exchange the values for
  #       the ghost elements, which we can do with sc_array_new_data (see t8_step5_exchange_ghost_data).
  #       We could also have directly allocated the data here in an sc_array with
  #       sc_array_new_count (sizeof (struct data_per_element), num_local_elements + num_ghost_elements)

  # Let us now fill the data with something.  For this, we iterate through all
  # trees and for each tree through all its elements, calling
  # t8_forest_get_element_in_tree to get a pointer to the current element.
  # This is the recommended and most performant way.  An alternative is to
  # iterate over the number of local elements and use t8_forest_get_element.
  # However, this function needs to perform a binary search for the element and
  # the tree it is in, while t8_forest_get_element_in_tree has a constant look
  # up time. You should only use t8_forest_get_element if you do not know in
  # which tree an element is.

  # Get the number of trees that have elements of this process.
  num_local_trees = t8_forest_get_num_local_trees(forest)

  current_index = 0
  for itree = 0:num_local_trees-1
    # This loop iterates through all local trees in the forest.
    # Each tree may have a different element class (quad/tri/hex/tet etc.) and therefore
    # also a different way to interpret its elements. In order to be able to handle elements
    # of a tree, we need to get its eclass_scheme, and in order to so we first get its eclass.
    tree_class = t8_forest_get_tree_class(forest, itree)
    eclass_scheme = t8_forest_get_eclass_scheme(forest, tree_class)

    # Get the number of elements of this tree.
    num_elements_in_tree = t8_forest_get_tree_num_elements(forest, itree)
    # This loop iterates through all the local elements of the forest in the current tree.
    for ielement = 0:num_elements_in_tree-1
      current_index += 1 # Note: Julia has 1-based indexing, while C/C++ starts with 0.

      # We can now write to the position current_index into our array in order
      # to store data for this element. */ Since in this example we want to
      # compute the data based on the element in question, we need to get a
      # pointer to this element.
      element = t8_forest_get_element_in_tree(forest, itree, ielement)

      # We want to store the elements level and its volume as data. We compute these
      # via the eclass_scheme and the forest_element interface.
      level = t8_element_level(eclass_scheme, element)
      volume = t8_forest_element_volume(forest, itree, element)

      element_data[current_index] = t8_step5_data_per_element_t(level,volume)
    end
  end

  return element_data
end

# Each process has computed the data entries for its local elements.  In order
# to get the values for the ghost elements, we use
# t8_forest_ghost_exchange_data.  Calling this function will fill all the ghost
# entries of our element data array with the value on the process that owns the
# corresponding element. */
function t8_step5_exchange_ghost_data(forest, element_data)
  # t8_forest_ghost_exchange_data expects an sc_array (of length num_local_elements + num_ghosts).
  # We wrap our data array to an sc_array.
  sc_array_wrapper = sc_array_new_data(pointer(element_data), sizeof(t8_step5_data_per_element_t), length(element_data))

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
# We support two types: T8_VTK_SCALAR - One double per element
#                  and  T8_VTK_VECTOR - 3 doubles per element
function t8_step5_output_data_to_vtu(forest, element_data, prefix)
  num_elements = t8_forest_get_local_num_elements(forest)
  # We need to allocate a new array to store the volumes on their own.
  # This array has one entry per local element. */
  element_volumes = Vector{Cdouble}(undef, num_elements)

  # Copy the elment's volumes from our data array to the output array.
  for ielem = 1:num_elements
    element_volumes[ielem] = element_data[ielem].volume
  end

  # The number of user defined data fields to write.
  num_data = 1

  # WARNING: This code hangs for Julia v1.8.* or older. Use at least Julia v1.9.
  # For each user defined data field we need one t8_vtk_data_field_t variable.
  vtk_data = t8_vtk_data_field_t(
    T8_VTK_SCALAR, # Set the type of this variable. Since we have one value per element, we pick T8_VTK_SCALAR.
    NTuple{8192, Cchar}(rpad("Element volume\0", 8192, ' ')), # The name of the field as should be written to the file.
    pointer(element_volumes), # Pointer to the data.
  )

  # To write user defined data, we need to extended output function
  # t8_forest_vtk_write_file from t8_forest_vtk.h. Despite writin user data,
  # it also offers more control over which properties of the forest to write.
  write_treeid = 1
  write_mpirank = 1
  write_level = 1
  write_element_id = 1
  write_ghosts = 0
  t8_forest_write_vtk_ext(forest, prefix, write_treeid, write_mpirank,
                           write_level, write_element_id, write_ghosts,
                           0, 0, num_data, Ref(vtk_data))
end

# The prefix for our output files.
prefix_forest = "t8_step5_forest"
prefix_forest_with_data = "t8_step5_forest_with_volume_data"

# The uniform refinement level of the forest.
level = 3

# Initialize MPI. This has to happen before we initialize sc or t8code.
mpiret = MPI.Init()

# We will use MPI_COMM_WORLD as a communicator.
comm = MPI.COMM_WORLD

# Initialize the sc library, has to happen before we initialize t8code.
sc_init(comm, 1, 1, C_NULL, SC_LP_ESSENTIAL)
# Initialize t8code with log level SC_LP_PRODUCTION. See sc.h for more info on the log levels.
t8_init(SC_LP_PRODUCTION)

# Print a message on the root process.
t8_global_productionf(" [step5] \n")
t8_global_productionf(" [step5] Hello, this is the step5 example of t8code.\n")
t8_global_productionf(" [step5] In this example we will store data on our elements and exchange the data of ghost elements.\n")
t8_global_productionf(" [step5] \n")

#
# Setup.
# Build cmesh and uniform forest.
# Adapt forest similar to step 3 & 4.
#

t8_global_productionf(" [step5] \n")
t8_global_productionf(" [step5] Creating an adapted forest as in step3.\n")
t8_global_productionf(" [step5] \n")

forest = t8_step5_build_forest(comm, level)
t8_forest_write_vtk(forest, prefix_forest)
t8_global_productionf(" [step5] Wrote forest to vtu files: %s*\n", prefix_forest)

#
# Build data array and gather data for the local elements.
#
element_data = t8_step5_create_element_data(forest)

t8_global_productionf(" [step5] Computed level and volume data for local elements.\n")

if t8_forest_get_local_num_elements(forest) > 0
  # Output the stored data of the first local element (if it exists).
  t8_global_productionf(" [step5] Element 0 has level %i and volume %e.\n", element_data[1].level, element_data[1].volume)
end

#
# Exchange the data values of the ghost elements.
#
t8_step5_exchange_ghost_data(forest, element_data)
t8_global_productionf(" [step5] Exchanged ghost data.\n")

if t8_forest_get_num_ghosts(forest) > 0
  # Output the data of the first ghost element (if it exists).
  first_ghost_index = t8_forest_get_local_num_elements(forest)
  t8_global_productionf(" [step5] Ghost 0 has level %i and volume %e.\n",
                         element_data[first_ghost_index + 1].level,
                         element_data[first_ghost_index + 1].volume)
end

# Output the volume data to vtu.
t8_step5_output_data_to_vtu(forest, element_data, prefix_forest_with_data)
t8_global_productionf(" [step5] Wrote forest and volume data to %s*.\n", prefix_forest_with_data)

#
# Clean-up.
#

# Destroy the forest.
t8_forest_unref(Ref(forest))
t8_global_productionf(" [step5] Destroyed forest.\n")

sc_finalize()
