@testset "test forestwrapper" begin

    # Clean up t8code before MPI shuts down.
    MPI.add_finalize_hook!() do
        T8code.clean_up()
        status = T8code.Libt8.sc_finalize_noabort()
        # If the following test fails the allocated objects were not cleaned up
        # properly before shutting down.
        @test status == 0
    end

    # Create a forest and wrap by `ForestWrapper`
    scheme = t8_scheme_new_default_cxx()
    cmesh = t8_cmesh_new_hypercube(T8_ECLASS_QUAD, comm, 0, 0, 0)
    forest = t8_forest_new_uniform(cmesh, scheme, 0, 0, comm)
    wrapper_A = T8code.ForestWrapper(forest)

    # Create another forest and wrap by `ForestWrapper`
    scheme = t8_scheme_new_default_cxx()
    cmesh = t8_cmesh_new_hypercube(T8_ECLASS_TRIANGLE, comm, 0, 0, 0)
    forest = t8_forest_new_uniform(cmesh, scheme, 0, 0, comm)
    wrapper_B = T8code.ForestWrapper(forest)

    # Finalize the first wrapper.
    finalize(wrapper_A)

    # The second wrapper should be finalized automatically when Julia shuts down.
    # ... finalize(wrapper_B) ...
end
