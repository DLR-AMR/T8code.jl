@testset "Conditional loading of t8code_jll" begin
    @test (JULIA_MPI_PROVIDER == "SYSTEM_MPI") && !(:t8code_jll in names(Main; imported=true))
end

@testset "T8code.uses_mpi" begin
    @test T8code.uses_mpi() == true
end
