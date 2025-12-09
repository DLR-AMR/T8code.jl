function t8_supported_msh_file(cmesh)

    # Description of the properties of the example msh-files.
    number_elements = 4
    elem_type = T8_ECLASS_TRIANGLE

    vertex = [
        [0, 0],
        [2, 0],
        [4, 0],
        [1, 2],
        [3, 2],
        [2, 4]
    ]

    # 0-based indexing
    elements = [
        [0, 1, 3],
        [1, 4, 3],
        [1, 2, 4],
        [3, 4, 5]
    ]

    face_neigh_elem = [
        [1, -1, -1],
        [3, 0, 2],
        [-1, 1, -1],
        [-1, -1, 1]
    ]

    @assert cmesh != C_NULL

    # Checks if the cmesh was committed.
    @assert t8_cmesh_is_committed(cmesh) == 1

    # `t8_cmesh_is_face_consistend` is not part of the public API.
    # Checks for face consistency.
    # @assert t8_cmesh_trees_is_face_consistend(cmesh, cmesh->trees) "Cmesh face consistency failed."

    # Checks if the number of elements was read correctly.
    @test t8_cmesh_get_num_trees(cmesh) == number_elements

    # Number of local trees.
    lnum_trees = t8_cmesh_get_num_local_trees(cmesh)
    # Iterate through the local elements and check if they were read properly.
    # All trees should be local to the master rank.
    for ltree_it in 0:(lnum_trees - 1)
        tree_class = t8_cmesh_get_tree_class(cmesh, ltree_it)
        @test t8_eclass_compare(tree_class, elem_type) == 0 ||
              "Element type in msh-file was read incorrectly."

        # Get pointer to the vertices of the tree.
        vertices_ptr = t8_cmesh_get_tree_vertices(cmesh, ltree_it)
        vertices = unsafe_wrap(Array, vertices_ptr, 9)
        # Checking the msh-files elements and nodes.
        for i in 0:2
            # Checks if x and y coordinate of the nodes are not read correctly.
            @test vertex[elements[ltree_it + 1][i + 1] + 1][1] == vertices[3 * i + 1] ||
                  "x coordinate was read incorrectly."
            @test vertex[elements[ltree_it + 1][i + 1] + 1][2] == vertices[3 * i + 2] ||
                  "y coordinate was read incorrectly"

            # Checks whether the face neighbor elements are not read correctly.
            ltree_id = t8_cmesh_get_face_neighbor(cmesh, ltree_it, i, C_NULL, C_NULL)
            @test ltree_id == face_neigh_elem[ltree_it + 1][i + 1] ||
                  "The face neighbor element in the example test file was not read correctly."
        end
    end
end

@testset "readmshfile" begin
    @testset "test_msh_file_vers2_ascii" begin
        fileprefix = "cmesh/testfiles/test_msh_file_vers2_ascii"
        filename = fileprefix * ".msh"

        @assert isfile(filename) "File not found: "*filename

        cmesh = t8_cmesh_from_msh_file(fileprefix, 1, comm, 2, 0, 0)

        @assert cmesh!=C_NULL "Could not read cmesh from ascii version 2, but should be able to: "*filename

        t8_supported_msh_file(cmesh)
        t8_cmesh_destroy(Ref(cmesh))
    end

    @testset "test_msh_file_vers4_ascii" begin
        fileprefix = "cmesh/testfiles/test_msh_file_vers4_ascii"
        filename = fileprefix * ".msh"

        @assert isfile(filename) "File not found: "*filename

        cmesh = t8_cmesh_from_msh_file(fileprefix, 1, comm, 2, 0, 0)

        @assert cmesh!=C_NULL "Could not read cmesh from ascii version 4, but should be able to: "*filename

        t8_cmesh_destroy(Ref(cmesh))
    end

end
