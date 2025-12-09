using Test

using MPI: MPI, mpiexec

import MPIPreferences
@info "Testing T8code.jl with" MPIPreferences.binary MPIPreferences.abi

@time @testset "T8code.jl tests" begin
    include("test_aqua.jl")
    # For some weird reason, the MPI tests must come first since they fail
    # otherwise with a custom MPI installation.
    @time @testset "MPI" begin
        # Do a dummy `@test true`:
        # If the process errors out the testset would error out as well,
        # cf. https://github.com/JuliaParallel/MPI.jl/pull/391
        @test true

        @info "Starting parallel tests"

        run(`$(mpiexec()) -n 2 $(Base.julia_cmd()) --threads=1 --check-bounds=yes --project=$(dirname(@__DIR__)) $(abspath("test_all.jl"))`)

        @info "Finished parallel tests"
    end

    @time @testset "serial" begin
        @info "Starting serial tests"

        # For another weird reason, we observe a segmentation fault if the tests are simply run by "include" rather than as external thread.
        run(`$(Base.julia_cmd()) --threads=1 --check-bounds=yes --project=$(dirname(@__DIR__)) $(abspath("test_all.jl"))`)

        @info "Finished serial tests"
    end
end
