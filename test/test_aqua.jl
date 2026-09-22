module TestAqua

using Aqua
using Test
using T8code

# When run in CI, check if we are running with system MPI or Julia artifacts
JULIA_MPI_PROVIDER = get(ENV, "JULIA_MPI_PROVIDER", "JLL_MPI")

# in case we are running with system MPI t8code_jll will not be loaded
if JULIA_MPI_PROVIDER == "JLL_MPI"
    @testset "Aqua.jl" begin
        Aqua.test_all(T8code)
    end
end

end #module
