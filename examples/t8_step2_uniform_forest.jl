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

# See also: https://github.com/holke/t8code/wiki/Step-2---Creating-a-uniform-forest
# 
# After we learned how to create a cmesh in step1, we will
# now build our first partitioned forest, get its local and global
# element count, and output it into .vtu files.
# 
# When we create a forest from a coarse mesh, the forest will always be
# uniform (every element has the same refinement level) and can then be adapted
# later (see the following steps).
# Together with the cmesh, we also need a refinement scheme. This scheme tells the
# forest how elements of each shape (t8_eclass_t) are refined, what their neighbor
# are etc.
# The default scheme in t8_schemes/t8_default/t8_default_cxx.hxx provides an implementation for
# all element shapes that t8code supports (with pyramids currently under construction).
# 
# How you can experiment here:
#  - Use Paraview to visualize the output files.
#  - Execute this program with different numbers of processes.
#  - Change the initial refinement level.
#  - Use a different cmesh (See step1).
#  - Look into t8_forest.h and try to get different information about the 
#    forest (for example the number of local trees).
# 

using MPI
using T8code
using T8code.Libt8: sc_init
using T8code.Libt8: sc_finalize
using T8code.Libt8: SC_LP_ESSENTIAL
using T8code.Libt8: SC_LP_PRODUCTION

# Builds cmesh of 2 prisms that build up a unit cube. 
# See step1 for a detailed description.
# \param [in] comm   MPI Communicator to use.
# \return            The coarse mesh.
function t8_step2_build_prismcube_coarse_mesh(comm)
  # Build a coarse mesh of 2 prism trees that form a cube.
  cmesh = t8_cmesh_new_hypercube(T8_ECLASS_PRISM, comm, 0, 0, 0)

  t8_global_productionf(" [step2] Constructed coarse mesh with 2 prism trees.\n")

  return cmesh
end

# Build a uniform forest on a cmesh 
# using the default refinement scheme.
# \param [in] comm   MPI Communicator to use.
# \param [in] cmesh  The coarse mesh to use.
# \param [in] level  The initial uniform refinement level.
# \return            A uniform forest with the given refinement level that is
#                    partitioned across the processes in \a comm.
function t8_step2_build_uniform_forest(comm, cmesh, level)
  # /* Create the refinement scheme. */
  scheme = t8_scheme_new_default_cxx()
  # /* Creat the uniform forest. */
  forest = t8_forest_new_uniform(cmesh, scheme, level, 0, comm)

  return forest
end

# Write vtk (or more accurately vtu) files of the forest.
# \param [in] forest   A forest.
# \param [in] prefix   A string that is used as a prefix of the output files.
# 
# This will create the file prefix.pvtu
# and additionally one file prefix_MPIRANK.vtu per MPI rank.
function t8_step2_write_forest_vtk(forest, prefix)
  t8_forest_write_vtk(forest, prefix)
end

# Destroy a forest. This will free all allocated memory.
# \param [in] forest    A forest.
# NOTE: This will also free the memory of the scheme and the cmesh, since
#       the forest took ownership of them.
#       If we do not want this behaviour, but want to reuse for example the cmesh,
#       we need to call t8_cmesh_ref (cmesh) before passing it to t8_forest_new_uniform.
function t8_step2_destroy_forest(forest)
  t8_forest_unref(Ref(forest))
end

# The prefix for our output files.
prefix = "t8_step2_uniform_forest"

# The uniform refinement level of the forest.
level = 3

# Initialize MPI. This has to happen before we initialize sc or t8code.
mpiret = MPI.Init()

# We will use MPI_COMM_WORLD as a communicator.
mpicom = MPI.COMM_WORLD.val

# Initialize the sc library, has to happen before we initialize t8code.
sc_init(mpicom, 1, 1, C_NULL, SC_LP_ESSENTIAL)
# Initialize t8code with log level SC_LP_PRODUCTION. See sc.h for more info on the log levels.
t8_init(SC_LP_PRODUCTION)

# Print a message on the root process.
t8_global_productionf(" [step2] \n")
t8_global_productionf(" [step2] Hello, this is the step2 example of t8code.\n")
t8_global_productionf(" [step2] In this example we build our first uniform forest and output it to vtu files.\n")
t8_global_productionf(" [step2] \n")

# Create the cmesh from step1.
cmesh = t8_step2_build_prismcube_coarse_mesh(mpicom)

# Build the uniform forest, it is automatically partitioned among the processes.
forest = t8_step2_build_uniform_forest(mpicom, cmesh, level)
# Get the local number of elements.
local_num_elements = t8_forest_get_local_num_elements(forest)
# Get the global number of elements.
global_num_elements = t8_forest_get_global_num_elements(forest)

# Print information on the forest.
t8_global_productionf(" [step2] Created uniform forest.\n")
t8_global_productionf(" [step2] Refinement level:\t\t\t%i\n", level)
t8_global_productionf(" [step2] Local number of elements:\t\t%i\n", local_num_elements)
t8_global_productionf(" [step2] Global number of elements:\t%li\n", global_num_elements)

# Write forest to vtu files.
t8_step2_write_forest_vtk(forest, prefix)
t8_global_productionf(" [step2] Wrote forest to vtu files:\t%s*\n", prefix)

# Destroy the forest.
t8_step2_destroy_forest(forest)
t8_global_productionf(" [step2] Destroyed forest.\n")

sc_finalize()
