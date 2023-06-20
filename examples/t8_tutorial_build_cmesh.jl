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

# See also: https://github.com/DLR-AMR/t8code/wiki/Build-Cmesh
#
# This is a tutorial regarding the creation of a cmesh using the C++ interface of t8code.
# In the following we will create two user defined meshes.
# The first example is given by a periodic two dimensional mesh using linear
# geometry consisting of four triangles and and two quads.
# The second example is given by a non-periodic three dimensional mesh 
# with linear geometry constructed using two tetrahedra, two prisms, one pyramid, and one 
# hexaedron.
#
# How you can experiment here:
#   - Look at the paraview output files of the different meshes.
#   - Change the element types of the mesh.
#   - Change the face connections between the different elements.
#   - Create an own mesh.

# Different steps of creating a cmesh
# 1. Defining an array with all vertices
#    The vertices are ordered in a listing for each cell.
#    Thus, there can be duplicates in the List.
#    Example: double vertices[numberOfValues] = {
#               //point values for cell 1
#               x_1,y_1,z_1         //(x,y,z) of first point of cell 1
#               x_2,y_2,z_2         //(x,y,z) of second point of cell 1
#                   .
#                   .
#                   .
#               x_n,y_n,z_n         //(x,y,z) of nth point (last point) of cell 1
#
#               //point values for cell 2
#               x_1,y_1,z_1         //(x,y,z) of first point of cell 2
#               x_2,y_2,z_2         //(x,y,z) of second point of cell 2
#                   .
#                   .
#                   .
#               x_m,y_m,z_m         //(x,y,z) of nth point (last point) of cell 2
#
#                   .
#                   .
#                   .
#
#               //point values for the last cell 
#               x_1,y_1,z_1         //(x,y,z) of first point of the last cell
#               x_2,y_2,z_2         //(x,y,z) of second point of the last cell
#                   .
#                   .
#                   .
#               x_o,y_o,z_o         //(x,y,z) of nth point (last point) of the last cell
#             }
#
# 2. Initialization of the mesh
#    Example: t8_cmesh_t          cmesh
#             t8_cmesh_init (&cmesh)
# 
#
# 3. Definition of the geometry
#             t8_geometry_c      *linear_geom = [defineTheGeometry]
#
# 4. Definition of the classes of the different trees - each tree is defined by one cell
#    Example: //Class of the first tree
#             t8_cmesh_set_tree_class (cmesh, 0, T8_ECLASS_[TYPE])
#             //Class of the second tree
#             t8_cmesh_set_tree_class (cmesh, 1, T8_ECLASS_[TYPE])
#                   .
#                   .
#                   .
#             //Class of the last tree
#             t8_cmesh_set_tree_class (cmesh, x, T8_ECLASS_[TYPE])
#
# 5. Classification of the vertices for each tree
#             // Vertices of the first tree
#             t8_cmesh_set_tree_vertices (cmesh, 0, [pointerToVerticesOfTreeOne], [numberOfVerticesTreeOne])
#             // Vertices of the second tree
#             t8_cmesh_set_tree_vertices (cmesh, 1, [pointerToVerticesOfTreeTwo] , [numberOfVerticesTreeTwo])
#                   .
#                   .
#                   .
#             // Vertices of the last tree
#             t8_cmesh_set_tree_vertices (cmesh, x, [pointerToVerticesOfTree(x+1)] , [numberOfVerticesTree(x+1)])
#
# 6. Definition of the face neighboors between the different trees
#             // List of all face neighboor connections
#             t8_cmesh_set_join (cmesh, [treeId1], [treeId2], [faceIdInTree1], [faceIdInTree2], [orientation])
#             t8_cmesh_set_join (cmesh, [treeId1], [treeId2], [faceIdInTree1], [faceIdInTree2], [orientation])
#                   .
#                   .
#                   .
#             t8_cmesh_set_join (cmesh, [treeId1], [treeId2], [faceIdInTree1], [faceIdInTree2], [orientation])
#
# 7. Commit the mesh
#             t8_cmesh_commit (cmesh, comm)

using MPI
using T8code
using T8code.Libt8: sc_init
using T8code.Libt8: sc_finalize
using T8code.Libt8: SC_LP_PRODUCTION

# Definition of a two dimensional mesh with linear geometry and periodic boundaries.
# The mesh consists of four triangles and two quads.
#
#  This is how the cmesh looks like. The numbers are the tree numbers:
#
#   +---+---+
#   |   |5 /|
#   | 3 | / |
#   |   |/ 4|
#   +---+---+
#   |1 /|   |
#   | / | 2 |
#   |/0 |   |
#   +---+---+

function t8_cmesh_new_periodic_hybrid_2d(comm)
  # 1. Defining an array with all vertices.
  # Just all vertices of all trees. partly duplicated.
  vertices = [
    0, 0, 0,                    # tree 0, triangle
    0.5, 0, 0,
    0.5, 0.5, 0,
    0, 0, 0,                    # tree 1, triangle
    0.5, 0.5, 0,
    0, 0.5, 0,
    0.5, 0, 0,                  # tree 2, quad
    1, 0, 0,
    0.5, 0.5, 0,
    1, 0.5, 0,
    0, 0.5, 0,                  # tree 3, quad
    0.5, 0.5, 0,
    0, 1, 0,
    0.5, 1, 0,
    0.5, 0.5, 0,                # tree 4, triangle
    1, 0.5, 0,
    1, 1, 0,
    0.5, 0.5, 0,                # tree 5, triangle
    1, 1, 0,
    0.5, 1, 0
  ]

  # 2. Initialization of the mesh.
  cmesh_ref = Ref(t8_cmesh_t())
  t8_cmesh_init(cmesh_ref)
  cmesh = cmesh_ref[]

  # 3. Definition of the geometry.
  linear_geom = t8_geometry_linear_new(2)
  t8_cmesh_register_geometry(cmesh, linear_geom)      # Use linear geometry.

  # 4. Definition of the classes of the different trees.
  t8_cmesh_set_tree_class(cmesh, 0, T8_ECLASS_TRIANGLE)
  t8_cmesh_set_tree_class(cmesh, 1, T8_ECLASS_TRIANGLE)
  t8_cmesh_set_tree_class(cmesh, 2, T8_ECLASS_QUAD)
  t8_cmesh_set_tree_class(cmesh, 3, T8_ECLASS_QUAD)
  t8_cmesh_set_tree_class(cmesh, 4, T8_ECLASS_TRIANGLE)
  t8_cmesh_set_tree_class(cmesh, 5, T8_ECLASS_TRIANGLE)

  # 5. Classification of the vertices for each tree.
  t8_cmesh_set_tree_vertices(cmesh, 0, vertices, 3)
  t8_cmesh_set_tree_vertices(cmesh, 1, vertices + 9, 3)
  t8_cmesh_set_tree_vertices(cmesh, 2, vertices + 18, 4)
  t8_cmesh_set_tree_vertices(cmesh, 3, vertices + 30, 4)
  t8_cmesh_set_tree_vertices(cmesh, 4, vertices + 42, 3)
  t8_cmesh_set_tree_vertices(cmesh, 5, vertices + 51, 3)

  # 6. Definition of the face neighbors between the different trees.
  t8_cmesh_set_join(cmesh, 0, 1, 1, 2, 0)
  t8_cmesh_set_join(cmesh, 0, 2, 0, 0, 0)
  t8_cmesh_set_join(cmesh, 0, 3, 2, 3, 0)

  t8_cmesh_set_join(cmesh, 1, 3, 0, 2, 1)
  t8_cmesh_set_join(cmesh, 1, 2, 1, 1, 0)

  t8_cmesh_set_join(cmesh, 2, 4, 3, 2, 0)
  t8_cmesh_set_join(cmesh, 2, 5, 2, 0, 1)

  t8_cmesh_set_join(cmesh, 3, 5, 1, 1, 0)
  t8_cmesh_set_join(cmesh, 3, 4, 0, 0, 0)

  t8_cmesh_set_join(cmesh, 4, 5, 1, 2, 0)

  # 7. Commit the mesh.
  t8_cmesh_commit(cmesh, comm)

  return cmesh
end

# Definition of a three dimensional mesh with linear geometry.
# The mesh consists of two tetrahedra, two prisms, one pyramid, and one hexahedron.
function t8_cmesh_new_hybrid_gate_3d(comm)
  vertices = Vector{Cdouble}(undef, 24)
  linear_geom = t8_geometry_linear_new(3)

  # Initialization of the mesh.
  cmesh_ref = Ref(t8_cmesh_t())
  t8_cmesh_init(cmesh_ref)
  cmesh = cmesh_ref[]

  # Definition of the geometry.
  t8_cmesh_register_geometry(cmesh, linear_geom)      # Use linear geometry.

  # Defitition of the classes of the different trees.
  t8_cmesh_set_tree_class(cmesh, 0, T8_ECLASS_TET)
  t8_cmesh_set_tree_class(cmesh, 1, T8_ECLASS_TET)
  t8_cmesh_set_tree_class(cmesh, 2, T8_ECLASS_PRISM)
  t8_cmesh_set_tree_class(cmesh, 3, T8_ECLASS_PRISM)
  t8_cmesh_set_tree_class(cmesh, 4, T8_ECLASS_PYRAMID)
  t8_cmesh_set_tree_class(cmesh, 5, T8_ECLASS_HEX)

  # Classification of the vertices for each tree.
  t8_cmesh_set_join(cmesh, 0, 2, 0, 4, 0)
  t8_cmesh_set_join(cmesh, 1, 3, 0, 4, 0)
  t8_cmesh_set_join(cmesh, 2, 5, 0, 0, 0)
  t8_cmesh_set_join(cmesh, 3, 5, 1, 1, 0)
  t8_cmesh_set_join(cmesh, 4, 5, 4, 2, 0)

  #  
  #  Definition of the first tree
  #  

  # Tetrahedron 1 vertices.
  vertices[1] = 0.43
  vertices[2] = 0
  vertices[3] = 2

  vertices[4] = 0
  vertices[5] = 0
  vertices[6] = 1

  vertices[7] = 0.86
  vertices[8] = -0.5
  vertices[9] = 1

  vertices[10] = 0.86
  vertices[11] = 0.5
  vertices[12] = 1

  # Classification of the vertices for the first tree.
  t8_cmesh_set_tree_vertices(cmesh, 0, vertices, 4)

  # 
  #  Definition of the second tree
  #

  # Tetrahedron 2 vertices.
  for itet = 0:2
    vertices[ 1 + itet] = vertices[ 1 + itet] + (itet == 0 ? 1 + 0.86 : 0)
    vertices[ 4 + itet] = vertices[ 7 + itet] + (itet == 0 ? 1 : 0)
    vertices[10 + itet] = vertices[10 + itet] + (itet == 0 ? 1 : 0)
  end

  vertices[7] = 1 + 2 * 0.86
  vertices[8] = 0
  vertices[9] = 1

  # Classification of the vertices for the second tree.
  t8_cmesh_set_tree_vertices(cmesh, 1, vertices, 4)

  # 
  # Definition of the third tree
  # 

  # Prism 1 vertices.
  vertices[1] = 0
  vertices[2] = 0
  vertices[3] = 0

  vertices[4] = 0.86
  vertices[5] = -0.5
  vertices[6] = 0

  vertices[7] = 0.86
  vertices[8] = 0.5
  vertices[9] = 0

  # Translate +1 in z-axis for the upper vertices.
  for iprism1 = 0:2
    vertices[10 + 3 * iprism1    ] = vertices[3 * iprism1 + 1]
    vertices[10 + 3 * iprism1 + 1] = vertices[3 * iprism1 + 2]
    vertices[10 + 3 * iprism1 + 2] = vertices[3 * iprism1 + 3] + 1
  end

  # Classification of the vertices for the third tree.
  t8_cmesh_set_tree_vertices(cmesh, 2, vertices, 6)

  # 
  #  Definition of the fourth tree
  #

  # Prism 2 vertices.
  for iprism2 = 0:2
    vertices[4 + iprism2] = vertices[1 + iprism2] + (iprism2 == 0 ? 1 + 2 * 0.86 : 0)
    vertices[7 + iprism2] = vertices[7 + iprism2] + (iprism2 == 0 ? 1 : 0)
  end

  vertices[1] = 0.86 + 1
  vertices[2] = -0.5
  vertices[3] = 0

  # Translate +1 in z-axis for the upper vertices.
  for iprism2 = 0:2
    vertices[10 + 3 * iprism2    ] = vertices[3 * iprism2 + 1]
    vertices[10 + 3 * iprism2 + 1] = vertices[3 * iprism2 + 2]
    vertices[10 + 3 * iprism2 + 2] = vertices[3 * iprism2 + 3] + 1
  end

  # Classification of the vertices for the fourth tree.
  t8_cmesh_set_tree_vertices(cmesh, 3, vertices, 6)

  # 
  #  Definition of the fifth tree
  #

  # Pyramid vertices.
  vertices[1] = 0.86
  vertices[2] = 0.5
  vertices[3] = 0

  vertices[4] = 1.86
  vertices[5] = 0.5
  vertices[6] = 0

  vertices[7] = 0.86
  vertices[8] = -0.5
  vertices[9] = 0

  vertices[10] = 1.86
  vertices[11] = -0.5
  vertices[12] = 0

  vertices[13] = 1.36
  vertices[14] = 0
  vertices[15] = -0.5

  # Classification of the vertices for the fifth tree.
  t8_cmesh_set_tree_vertices(cmesh, 4, vertices, 5)

  # 
  #  Definition of the sixth tree
  #

  # Hex coordinates.
  for hex = 0:3
    vertices[3 * hex +  2] = vertices[3 * hex + 2] * (-1)
    vertices[3 * hex + 13] = vertices[3 * hex + 1]
    vertices[3 * hex + 14] = vertices[3 * hex + 2]
    vertices[3 * hex + 15] = vertices[3 * hex + 3] + 1
  end

  # Classification of the vertices for the fifth tree.
  t8_cmesh_set_tree_vertices(cmesh, 5, vertices, 8)

  # Commit the mesh.
  t8_cmesh_commit(cmesh, comm)
  return cmesh
end

# The prefix for our output files.
prefix_2D = "t8_step8_user_defined_mesh_2D"
prefix_3D = "t8_step8_user_defined_mesh_3D"

# 
# Initialization.
# 

# Initialize MPI. This has to happen before we initialize sc or t8code.
mpiret = MPI.Init()
comm = MPI.COMM_WORLD

# Initialize the sc library, has to happen before we initialize t8code.
sc_init(comm, 1, 1, C_NULL, SC_LP_PRODUCTION)

# Initialize t8code with log level SC_LP_PRODUCTION. See sc.h for more info on the log levels. */
t8_init(SC_LP_PRODUCTION)

# We will use MPI_COMM_WORLD as a communicator.

# 
# Definition of the meshes.
# 

# Creation of a two dimensional cmesh with periodic boundaries. */
cmesh_2D = t8_cmesh_new_periodic_hybrid_2d(comm)

t8_global_productionf("[tutorial] A 2D hybrid cmesh with periodic boundaries has been created.\n")

# Creation of a three dimensional cmesh.
cmesh_3D = t8_cmesh_new_hybrid_gate_3d(comm)

t8_global_productionf("[tutorial] A 3D hybrid cmesh (in style of a gate) has been created.\n")

# Output the meshes to vtu files.
t8_cmesh_vtk_write_file(cmesh_2D, prefix_2D, 1.0)
t8_global_productionf("[tutorial] Wrote the 2D cmesh to vtu files.\n")
t8_cmesh_vtk_write_file(cmesh_3D, prefix_3D, 1.0)
t8_global_productionf("[tutorial] Wrote the 3D cmesh to vtu files.\n")

# 
# Clean-up
# 

# Deallocate the cmeshes.
t8_cmesh_destroy(Ref(cmesh_2D))
t8_global_productionf("[tutorial] The 2D cmesh has been deallocated.\n")

t8_cmesh_destroy(Ref(cmesh_3D))
t8_global_productionf("[tutorial] The 3D cmesh has been deallocated.\n")

# Finalize the sc library.
sc_finalize()
