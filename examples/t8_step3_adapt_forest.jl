# This is step3 of the t8code tutorials.
# After generating a coarse mesh (step1) and building a uniform forest
# on it (step2), we will now adapt (= refine and coarsen) the forest
# according to our own criterion.
# 
# The geometry (coarse mesh) is again a cube, this time modelled with
# 6 tetrahedra, 6 prisms and 4 cubes.
# We refine an element if its midpoint is whithin a sphere of given radius
# around the point (0.5, 0.5, 1) and we coarsen outside of a given radius.
# We will use non-recursive refinement, that means that the refinement level
# of any element will change by at most +-1.
# 
# How you can experiment here:
#   - Look at the paraview output files of the unifomr and the adapted forest.
#     For the adapted forest you can apply a slice filter to look into the cube.
#   - Run the program with different process numbers. You should see that refining is
#     independent of the number of processes, but coarsening is not.
#     This is due to the face that a family can only be coarsened if it is completely
#     local to a single process and the distribution among the process may break this property.
#   - Change the midpoint coordinates and the radii.
#   - Change the adaptation criterion such that elements inside the sphere are coarsened
#     and elements outside are refined.
#   - Use t8_productionf to print the local number of elements on each process.
#     Notice, that the uniform forest is evenly distributed, but that the adapted forest
#     is not. This is due to the fact that we do not repartition our forest here.
#   - Add a maximum refinement level to the adapt_data struct and use non-recursive refinement.
#     Do not refine an element if it has reached the maximum level. (Hint: ts->t8_element_level)

using MPI
using P4est
using T8code

# This is our own defined data that we will pass on to the
# adaptation callback.
mutable struct t8_step3_adapt_data_t
  midpoint                    :: NTuple{3,Cdouble}
  refine_if_inside_radius     :: Cdouble
  coarsen_if_outside_radius   :: Cdouble 
end

# The adaptation callback function. This function will be called once for each element
# and the return value decides whether this element should be refined or not.
#   return > 0 -> This element should get refined.
#   return = 0 -> This element should not get refined.
# If the current element is the first element of a family (= all level l elements that arise from refining
# the same level l-1 element) then this function is called with the whole family of elements
# as input and the return value additionally decides whether the whole family should get coarsened.
#   return > 0 -> The first element should get refined.
#   return = 0 -> The first element should not get refined.
#   return < 0 -> The whole family should get coarsened.
#  
# \param [in] forest       The current forest that is in construction.
# \param [in] forest_from  The forest from which we adapt the current forest (in our case, the uniform forest)
# \param [in] which_tree   The process local id of the current tree.
# \param [in] lelement_id  The tree local index of the current element (or the first of the family).
# \param [in] ts           The refinement scheme for this tree's element class.
# \param [in] is_family    if 1, the first \a num_elements entries in \a elements form a family. If 0, they do not.
# \param [in] num_elements The number of entries in \a elements elements that are defined.
# \param [in] elements     The element or family of elements to consider for refinement/coarsening.
function t8_step3_adapt_callback(forest, forest_from, which_tree, lelement_id,
                                  ts, is_family, num_elements, elements_ptr) :: Cint
  # Our adaptation criterion is to look at the midpoint coordinates of the current element and if
  # they are inside a sphere around a given midpoint we refine, if they are outside, we coarsen.

  centroid = Vector{Cdouble}(undef,3) # Will hold the element midpoint.
  # In t8_step3_adapt_forest we pass a t8_step3_adapt_data pointer as user data to the
  # t8_forest_new_adapt function. This pointer is stored as the used data of the new forest
  # and we can now access it with t8_forest_get_user_data (forest).
  adapt_data_ptr = Ptr{t8_step3_adapt_data_t}(t8_forest_get_user_data(forest))

  # You can use assert for assertions that are active in debug mode (when configured with --enable-debug).
  # If the condition is not true, then the code will abort.
  # In this case, we want to make sure that we actually did set a user pointer to forest and thus
  # did not get the NULL pointer from t8_forest_get_user_data.
  @T8_ASSERT(adapt_data_ptr != C_NULL)

  adapt_data = unsafe_load(adapt_data_ptr)

  elements = unsafe_wrap(Array, elements_ptr, num_elements)

  # Compute the element's centroid coordinates.
  t8_forest_element_centroid(forest_from, which_tree, elements[1], pointer(centroid))

  # Compute the distance to our sphere midpoint.
  dist = t8_vec_dist(centroid, Ref(adapt_data.midpoint[1]))
  if dist < adapt_data.refine_if_inside_radius
    # Refine this element.
    return 1
  elseif is_family == 1 && dist > adapt_data.coarsen_if_outside_radius
    # Coarsen this family. Note that we check for is_family before, since returning < 0
    # if we do not have a family as input is illegal. 
    return -1
  end

  # Do not change this element.
  return 0
end

# Adapt a forest according to our t8_step3_adapt_callback function.
# This will create a new forest and return it.
function t8_step3_adapt_forest(forest)
  adapt_data = t8_step3_adapt_data_t(
    (0.5, 0.5, 1.0),      # Midpoints of the sphere.
    0.2,                  # Refine if inside this radius.
    0.4                   # Coarsen if outside this radius.
  )

  # Check that forest is a committed, that is valid and usable, forest.
  @T8_ASSERT(t8_forest_is_committed(forest) == 1)

  # Create a new forest that is adapted from \a forest with our adaptation callback.
  # We provide the adapt_data as user data that is stored as the used_data pointer of the
  # new forest (see also t8_forest_set_user_data).
  # The 0, 0 arguments are flags that control
  #   recursive  -    If non-zero adaptation is recursive, thus if an element is adapted the children
  #                   or parents are plugged into the callback again recursively until the forest does not
  #                   change any more. If you use this you should ensure that refinement will stop eventually.
  #                   One way is to check the element's level against a given maximum level.
  #   do_face_ghost - If non-zero additionally a layer of ghost elements is created for the forest.
  #                   We will discuss ghost in later steps of the tutorial.
  forest_adapt = t8_forest_new_adapt(forest, @t8_adapt_callback(t8_step3_adapt_callback), 0, 0, Ref(adapt_data))

  return forest_adapt
end

# Print the local and global number of elements of a forest.
function t8_step3_print_forest_information(forest)
  # Check that forest is a committed, that is valid and usable, forest.
  @T8_ASSERT(t8_forest_is_committed(forest) == 1)

  # Get the local number of elements.
  local_num_elements = t8_forest_get_local_num_elements(forest)
  # Get the global number of elements.
  global_num_elements = t8_forest_get_global_num_elements(forest)

  t8_global_productionf(" [step3] Local number of elements:\t\t%i\n", local_num_elements)
  t8_global_productionf(" [step3] Global number of elements:\t%li\n", global_num_elements)
end

# The prefix for our output files.
prefix_uniform = "t8_step3_uniform_forest"
prefix_adapt = "t8_step3_adapted_forest"
# The uniform refinement level of the forest.
level = 3

# Initialize MPI. This has to happen before we initialize sc or t8code.
mpiret = MPI.Init()

# Initialize the sc library, has to happen before we initialize t8code.
sc_init(sc_MPI_COMM_WORLD, 1, 1, C_NULL, SC_LP_ESSENTIAL)
# Initialize t8code with log level SC_LP_PRODUCTION. See sc.h for more info on the log levels.
t8_init(SC_LP_PRODUCTION)

# Print a message on the root process.
t8_global_productionf(" [step3] \n")
t8_global_productionf(" [step3] Hello, this is the step3 example of t8code.\n")
t8_global_productionf(" [step3] In this example we will refine and coarsen a forest.\n")
t8_global_productionf(" [step3] \n")

# We will use MPI_COMM_WORLD as a communicator.
comm = MPI.COMM_WORLD

## Setup. Build cmesh and uniform forest.

# Build a cube cmesh with tet, hex, and prism trees.
cmesh = t8_cmesh_new_hypercube_hybrid(comm, 0, 0)
t8_global_productionf(" [step3] Created coarse mesh.\n")
forest = t8_forest_new_uniform(cmesh, t8_scheme_new_default_cxx(), level, 0, comm)

# Print information of the forest.
t8_global_productionf(" [step3] Created uniform forest.\n")
t8_global_productionf(" [step3] Refinement level:\t%i\n", level)
t8_step3_print_forest_information(forest)

# Write forest to vtu files.
t8_forest_write_vtk(forest, prefix_uniform)
t8_global_productionf(" [step3] Wrote uniform forest to vtu files: %s*\n", prefix_uniform)

## Adapt the forest.

# Adapt the forest. We can reuse the forest variable, since the new adapted
# forest will take ownership of the old forest and destroy it.
# Note that the adapted forest is a new forest, though. */
forest = t8_step3_adapt_forest(forest)

## Output.

# Print information of our new forest.
t8_global_productionf(" [step3] Adapted forest.\n")
t8_step3_print_forest_information(forest)

# Write forest to vtu files.
t8_forest_write_vtk(forest, prefix_adapt)
t8_global_productionf(" [step3] Wrote adapted forest to vtu files: %s*\n", prefix_adapt)

## Clean-up.

# Destroy the forest.
t8_forest_unref(Ref(forest))
t8_global_productionf(" [step3] Destroyed forest.\n")

sc_finalize()
