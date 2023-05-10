using Test

using MPI: MPI, mpiexec
using T8code

import MPIPreferences
@info "Testing T8code.jl with" MPIPreferences.binary MPIPreferences.abi


@time @testset "T8code.jl tests" begin
  # For some weird reason, the MPI tests must come first since they fail
  # otherwise with a custom MPI installation.
  @time @testset "MPI" begin
    # Do a dummy `@test true`:
    # If the process errors out the testset would error out as well,
    # cf. https://github.com/JuliaParallel/MPI.jl/pull/391
    @test true

    @info "Starting parallel tests"

    mpiexec() do cmd
      run(`$cmd -n 2 $(Base.julia_cmd()) --threads=1 --check-bounds=yes --project=$(dirname(@__DIR__)) $(abspath("tests_basic.jl"))`)
    end

    @info "Finished parallel tests"
  end

  @time @testset "serial" begin
    @info "Starting serial tests"

    include("tests_basic.jl")

    @info "Finished serial tests"
  end
end
