@testset "test forestwrapper" begin

    # Clean up t8code before MPI shuts down.
    MPI.add_finalize_hook!() do
        T8code.clean_up()
        @test length(T8code.T8CODE_OBJECT_TRACKER) == 0
        status = T8code.Libt8.sc_finalize_noabort()
        # If the following test fails the allocated objects were not cleaned up
        # properly before shutting down.
        @test status == 0
    end

    @test length(T8code.T8CODE_OBJECT_TRACKER) == 0

    # Create a forest and wrap by `ForestWrapper`
    scheme = t8_scheme_new_default_cxx()
    cmesh = t8_cmesh_new_hypercube(T8_ECLASS_QUAD, comm, 0, 0, 0)
    forest = t8_forest_new_uniform(cmesh, scheme, 0, 0, comm)
    wrapper_A = T8code.ForestWrapper(forest)

    @test length(T8code.T8CODE_OBJECT_TRACKER) == 1

    # Create another forest and wrap by `ForestWrapper`
    scheme = t8_scheme_new_default_cxx()
    cmesh = t8_cmesh_new_hypercube(T8_ECLASS_TRIANGLE, comm, 0, 0, 0)
    forest = t8_forest_new_uniform(cmesh, scheme, 0, 0, comm)
    wrapper_B = T8code.ForestWrapper(forest)

    @test length(T8code.T8CODE_OBJECT_TRACKER) == 2

    # Finalize the first wrapper.
    finalize(wrapper_A)

    @test length(T8code.T8CODE_OBJECT_TRACKER) == 1

    finalize(wrapper_B)

    # The second wrapper should be finalized automatically when Julia shuts down.
    # ... finalize(wrapper_B) ...
end
