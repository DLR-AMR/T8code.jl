@testset "Conditional loading of t8code_jll" begin
    t8code_jll_loaded = any(m -> nameof(m) === :t8code_jll, values(Base.loaded_modules))
    @test (JULIA_MPI_PROVIDER == "SYSTEM_MPI") != t8code_jll_loaded
end

@testset "T8code.uses_mpi" begin
    @test T8code.uses_mpi() == true
end
