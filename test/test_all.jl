module TestAll

using Test
using MPI: MPI

using T8code
using T8code.Libt8: SC_LP_DEFAULT
using T8code.Libt8: SC_LP_ESSENTIAL
using T8code.Libt8: SC_LP_PRODUCTION

MPI.Init()

comm = MPI.COMM_WORLD

@testset "init" begin
    include("test_init.jl")
end

end # module
