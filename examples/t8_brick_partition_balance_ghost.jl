using MPI
using T8code
using T8code.Libt8: sc_init
using T8code.Libt8: sc_finalize
using T8code.Libt8: SC_LP_ESSENTIAL
using T8code.Libt8: SC_LP_PRODUCTION


# Print the local and global number of elements of a forest.
function t8_step3_print_forest_information(forest)
    # Check that forest is a committed, that is valid and usable, forest.
    @T8_ASSERT(t8_forest_is_committed(forest)==1)

    # Get the local number of elements.
    local_num_elements = t8_forest_get_local_num_leaf_elements(forest)
    # Get the global number of elements.
    global_num_elements = t8_forest_get_global_num_leaf_elements(forest)

    t8_global_productionf(" [step3] Local number of elements:\t\t%i\n", local_num_elements)
    t8_global_productionf(" [step3] Global number of elements:\t%li\n", global_num_elements)
end


# Gather the 3x3 stencil for each element and compute finite difference approximations
# for schlieren and curvature of the stored heights in the elements.
function t8_traverse_forest(forest, comm)
    # Check that forest is a committed, that is valid and usable, forest.
    @T8_ASSERT(t8_forest_is_committed(forest)==1)

    # Get the number of trees that have elements of this process.
    num_local_trees = t8_forest_get_num_local_trees(forest)

    scheme = t8_forest_get_scheme(forest)

    # Loop over all local trees in the forest.
    for itree in 0:(num_local_trees - 1)
        tree_class = t8_forest_get_tree_class(forest, itree)
        num_elements_in_tree = t8_forest_get_tree_num_leaf_elements(forest, itree)

        # Loop over all local elements in the tree.
        for ielement in 0:(num_elements_in_tree - 1)

            element = t8_forest_get_leaf_element_in_tree(forest, itree, ielement)

            level = t8_element_get_level(scheme, tree_class, element)

            # Loop over all faces of an element.
            num_faces = t8_element_get_num_faces(scheme, tree_class, element)
            for iface in 1:num_faces
                neighids_ref = Ref{Ptr{t8_locidx_t}}()
                neighbors_ref = Ref{Ptr{Ptr{t8_element}}}()
                neigh_scheme_ref = Ref{t8_eclass_t}()

                dual_faces_ref = Ref{Ptr{Cint}}()
                num_neighbors_ref = Ref{Cint}()

                t8_forest_leaf_face_neighbors(forest, itree, element,
                                              neighbors_ref, iface - 1, dual_faces_ref,
                                              num_neighbors_ref,
                                              neighids_ref, neigh_scheme_ref)

                num_neighbors = num_neighbors_ref[]
                dual_faces = 1 .+ unsafe_wrap(Array, dual_faces_ref[], num_neighbors)
                neighids = 1 .+ unsafe_wrap(Array, neighids_ref[], num_neighbors)
                neighbors = unsafe_wrap(Array, neighbors_ref[], num_neighbors)
                neigh_scheme = neigh_scheme_ref[]

                if num_neighbors > 0 
                     neighbor_level = t8_element_get_level(scheme, neigh_scheme,
                                                          neighbors[1])
                    @info MPI.Comm_rank(comm), itree, ielement, iface, level, neighbor_level
                end

                # Free allocated memory.
                t8_free(dual_faces_ref[])
                t8_free(neighbors_ref[])
                t8_free(neighids_ref[])
            end
        end
    end
end


# In this function we create a new forest that repartitions a given forest
# and has a layer of ghost elements.
function t8_step4_partition_ghost(forest)
    # Check that forest is a committed, that is a valid and usable, forest.
    @T8_ASSERT(t8_forest_is_committed(forest)==1)

    # Initialize.
    new_forest_ref = Ref(t8_forest_t())
    t8_forest_init(new_forest_ref)
    new_forest = new_forest_ref[]

    # Tell the new_forest that is should partition the existing forest.
    # This will change the distribution of the forest elements among the processes
    # in such a way that afterwards each process has the same number of elements
    # (+- 1 if the number of elements is not divisible by the number of processes).
    #
    # The third 0 argument is the flag 'partition_for_coarsening' which is currently not
    # implemented. Once it is, this will ensure that a family of elements will not be split
    # across multiple processes and thus one level coarsening is always possible (see also the
    # comments on coarsening in t8_step3).
    t8_forest_set_partition(new_forest, forest, 1)

    # Tell the new_forest to create a ghost layer.
    # This will gather those face neighbor elements of process local element that reside
    # on a different process.
    #
    # We currently support ghost mode T8_GHOST_FACES that creates face neighbor ghost elements
    # and will in future also support other modes for edge/vertex neighbor ghost elements.
    t8_forest_set_ghost(new_forest, 1, T8_GHOST_FACES)

    # Commit the forest, this step will perform the partitioning and ghost layer creation.
    t8_forest_commit(new_forest)

    return new_forest
end

# In this function we adapt a forest as in step3 and balance it.  In our main
# program the input forest is already adapted and then the resulting twice
# adapted forest will be unbalanced.
function t8_step4_balance(forest)
   
    # Initialize new forest.
    balanced_forest_ref = Ref(t8_forest_t())
    t8_forest_init(balanced_forest_ref)
    balanced_forest = balanced_forest_ref[]

    # Specify that this forest should result from balancing unbalanced_forest.
    # The last argument is the flag 'no_repartition'.
    # Since balancing will refine elements, the load-balance will be broken afterwards.
    # Setting this flag to false (no_repartition = false -> yes repartition) will repartition
    # the forest after balance, such that every process has the same number of elements afterwards.
    t8_forest_set_balance(balanced_forest, forest, 1)
    t8_forest_set_ghost(balanced_forest, 1, T8_GHOST_FACES)

    # Commit the forest.
    t8_forest_commit(balanced_forest)

    return balanced_forest
end

#include("t8_step3_common.jl")




# The uniform refinement level of the forest.
level = 0

# Initialize MPI. This has to happen before we initialize sc or t8code.
mpiret = MPI.Init()

# We will use MPI_COMM_WORLD as a communicator.
comm = MPI.COMM_WORLD

# Initialize the sc library, has to happen before we initialize t8code.
sc_init(comm, 0, 1, C_NULL, SC_LP_ESSENTIAL)

# Initialize t8code with log level SC_LP_PRODUCTION. See sc.h for more info on the log levels.
t8_init(SC_LP_PRODUCTION)


# Build a cube cmesh with tet, hex, and prism trees.
cmesh = t8_cmesh_new_brick_2d(3, 7, 0, 0, comm)
t8_global_productionf(" [step4] Created coarse mesh.\n")

forest = t8_forest_new_uniform(cmesh, t8_scheme_new_default(), level, 1, comm)

# Print information of the forest.
t8_step3_print_forest_information(forest);



#
# Balance
#
forest = t8_step4_balance(forest)
t8_global_productionf(" [step4] Balanced forest.\n")
t8_step3_print_forest_information(forest)


#
# Partition and create ghost elements.
#
forest = t8_step4_partition_ghost(forest)

t8_global_productionf(" [step4] Repartitioned forest and built ghost layer.\n")
t8_step3_print_forest_information(forest)


t8_traverse_forest(forest, comm)

#
# clean-up
#

# Destroy the forest.
t8_forest_unref(Ref(forest))

sc_finalize()
