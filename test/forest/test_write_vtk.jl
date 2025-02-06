# This file tests the writing of data to vtk files.
# All t8code eclasses are tested with a basic forest with elements of level 0 to 3.
@testset "test_write_vtk" begin
    outdir = "out_test"
    isdir(outdir) && rm(outdir, recursive = true)
    mkpath(outdir)

    for eclass in T8_ECLASS_ZERO:t8_eclass(T8_ECLASS_COUNT - 1)
        @testset "eclass $eclass" begin
            for level in 0:3
                scheme = t8_scheme_new_default_cxx()
                cmesh = t8_cmesh_new_hypercube(t8_eclass(eclass), comm, 0, 0, 0)
                forest = t8_forest_new_uniform(cmesh, scheme, level, 0, comm)

                num_elements = t8_forest_get_local_num_elements(forest)

                data = rand(num_elements)

                vtk_data = t8_vtk_data_field_t(T8_VTK_SCALAR,
                                               NTuple{8192, Cchar}(rpad("data_1)\0", 8192,
                                                                        ' ')),
                                               pointer(data))

                # The number of user defined data fields to write.
                num_data = 1

                # Write user defined data to vtu file.
                write_treeid = 1
                write_mpirank = 1
                write_level = 1
                write_element_id = 1
                write_ghosts = 0
                file = joinpath(outdir, "data_" * string(eclass) * "_" * string(level))
                t8_forest_write_vtk_ext(forest, file, write_treeid, write_mpirank,
                                        write_level, write_element_id, write_ghosts,
                                        0, 0, num_data, Ref(vtk_data))
                # TODO: Add MPI barrier
                @test isfile(file * ".pvtu")
                @test isfile(file * "_0000.vtu")
                # TODO: Check file * "0001.vtu" for MPI parallel run

                t8_forest_unref(Ref(forest))
            end
        end
    end

    @test_nowarn rm(outdir, recursive = true)
end
