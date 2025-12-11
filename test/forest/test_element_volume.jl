# This file tests the volume-computation of elements.

# Compute the volume of a pyramid descending of a root-pyramid with volume 1/3
# Pyramids need a special handling of the control-volume computation, because
# they subdivide into pyramids and tetrahedra. Therefore in every refinement three 
# types of elements occur:
# 
# 1. A pyramid with 1/8 of its parents volume
# 2. A tetrahedron with a pyramid parent, having 1/16th of its parents volume.
# 3. A tetrahedron with a tet-parent, having 1/8th of its parents volume.
# 
# On a leaf-level we therefore can have many different volumes for the
# elements and compute it element-specific. 
# \param[in] pyra A pyramid
# \return The volume of the pyramid 
function pyramid_control_volume(scheme::Ptr{t8_scheme},
                                tree_class::t8_eclass,
                                pyra::Ptr{t8_element})::Cdouble
    level = t8_element_get_level(scheme, tree_class, pyra)
    # Both pyramids and tets have 1/8th of the parents volume, if the shape does not switch.
    control_volume = 1.0 / 3.0 / (1 << (level * 3))

    # Ancestors switch the shape. A tetrahedron has a 1/16th of its parents
    # volume.  For all levels we already divided the control-volume by 8, hence
    # we divide it by 2 once.
    # NOTE: T8code.jl does not support this operation.
    # if (pyra->switch_shape_at_level > 0)
    #   control_volume /= 2
    # end

    return control_volume
end

@testset "element volume" begin
    epsilon = 1e-9

    for eclass in T8_ECLASS_ZERO:t8_eclass(T8_ECLASS_COUNT - 1)
        for level in 0:4
            scheme = t8_scheme_new_default()
            cmesh = t8_cmesh_new_hypercube(t8_eclass(eclass), comm, 0, 0, 0)
            forest = t8_forest_new_uniform(cmesh, scheme, level, 0, comm)

            # Compute the global number of elements.
            global_num_elements = t8_forest_get_global_num_leaf_elements(forest)

            # Vertices have a volume of 0.
            control_volume = (eclass == T8_ECLASS_VERTEX) ? 0.0 :
                             (1.0 / global_num_elements)

            local_num_trees = t8_forest_get_num_local_trees(forest)

            # Get the scheme used by this forest
            scheme = t8_forest_get_scheme(forest)

            # Iterate over all elements.
            for itree in 0:(local_num_trees - 1)
                tree_class = t8_forest_get_tree_class(forest, itree)
                tree_elements = t8_forest_get_tree_num_leaf_elements(forest, itree)
                for ielement in 0:(tree_elements - 1)
                    element = t8_forest_get_leaf_element_in_tree(forest, itree, ielement)
                    volume = t8_forest_element_volume(forest, itree, element)
                    if eclass == T8_ECLASS_PYRAMID
                        shape_volume = pyramid_control_volume(scheme, tree_class, element)
                        # WORKAROUND: See `function pyramid_control_volume` for a comment
                        # why the following test is split into two.
                        @test abs(shape_volume - volume) <= epsilon ||
                              abs(shape_volume / 2 - volume) <= epsilon
                    else
                        @test abs(volume - control_volume) <= epsilon
                    end
                end # ielement
            end # itree

            t8_forest_unref(Ref(forest))
        end # level
    end # eclass
end # testset
