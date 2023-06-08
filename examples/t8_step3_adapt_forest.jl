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
using T8code
using T8code.Libt8: sc_init
using T8code.Libt8: sc_finalize
using T8code.Libt8: SC_LP_ESSENTIAL
using T8code.Libt8: SC_LP_PRODUCTION

include("t8_step3_common.jl")

# The prefix for our output files.
prefix_uniform = "t8_step3_uniform_forest"
prefix_adapt = "t8_step3_adapted_forest"
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
t8_global_productionf(" [step3] \n")
t8_global_productionf(" [step3] Hello, this is the step3 example of t8code.\n")
t8_global_productionf(" [step3] In this example we will refine and coarsen a forest.\n")
t8_global_productionf(" [step3] \n")

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
