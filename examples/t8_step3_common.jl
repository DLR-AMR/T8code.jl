# This is our own defined data that we will pass on to the
# adaptation callback.
mutable struct t8_step3_adapt_data_t
    midpoint                  :: NTuple{3, Cdouble}
    refine_if_inside_radius   :: Cdouble
    coarsen_if_outside_radius :: Cdouble
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
# \param [in] tree_class   The eclass of \a which_tree.
# \param [in] lelement_id  The tree local index of the current element (or the first of the family).
# \param [in] scheme       The refinement scheme for this tree's element class.
# \param [in] is_family    If 1, the first \a num_elements entries in \a elements form a family. If 0, they do not.
# \param [in] num_elements The number of entries in \a elements elements that are defined.
# \param [in] elements     The element or family of elements to consider for refinement/coarsening.
function t8_step3_adapt_callback(forest, forest_from, which_tree, tree_class, lelement_id,
                                 scheme, is_family, num_elements, elements_ptr)::Cint
    # Our adaptation criterion is to look at the midpoint coordinates of the current element and if
    # they are inside a sphere around a given midpoint we refine, if they are outside, we coarsen.

    centroid = Vector{Cdouble}(undef, 3) # Will hold the element midpoint.
    # In t8_step3_adapt_forest we pass a t8_step3_adapt_data pointer as user data to the
    # t8_forest_new_adapt function. This pointer is stored as the used data of the new forest
    # and we can now access it with t8_forest_get_user_data (forest).
    adapt_data_ptr = Ptr{t8_step3_adapt_data_t}(t8_forest_get_user_data(forest))

    # You can use assert for assertions that are active in debug mode (when configured with --enable-debug).
    # If the condition is not true, then the code will abort.
    # In this case, we want to make sure that we actually did set a user pointer to forest and thus
    # did not get the NULL pointer from t8_forest_get_user_data.
    @T8_ASSERT(adapt_data_ptr!=C_NULL)

    adapt_data = unsafe_load(adapt_data_ptr)

    elements = unsafe_wrap(Array, elements_ptr, num_elements)

    # Compute the element's centroid coordinates.
    t8_forest_element_centroid(forest_from, which_tree, elements[1], pointer(centroid))

    # Compute the distance to our sphere midpoint.
    dist = sqrt(sum((centroid .- adapt_data.midpoint) .^ 2))
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
    adapt_data = t8_step3_adapt_data_t((0.5, 0.5, 1.0),      # Midpoints of the sphere.
                                       0.2,                  # Refine if inside this radius.
                                       0.4)

    # Check that forest is a committed, that is valid and usable, forest.
    @T8_ASSERT(t8_forest_is_committed(forest)==1)

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
    forest_adapt = t8_forest_new_adapt(forest, @t8_adapt_callback(t8_step3_adapt_callback),
                                       0, 0, Ref(adapt_data))

    return forest_adapt
end

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
