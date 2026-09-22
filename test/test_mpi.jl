@testset "Conditional loading of t8code_jll"
    # TODO adapt once implemented
    if JULIA_MPI_PROVIDER == "SYSTEM_MPI"
        @test :t8code_jll in names(Main; imported=true)
    else
        @test :t8code_jll in names(Main; imported=true)
    end
end

@testset "T8code.uses_mpi" begin
    @test T8code.uses_mpi() == true
end
