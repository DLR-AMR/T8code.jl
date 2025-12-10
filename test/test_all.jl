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

@testset "general" begin
    if !Sys.iswindows()
        # These tests do not work in Windows since the DLL loader does not search for symbols beyond libt8.dll.
        include("test_refcount.jl")
    end
end

@testset "cmesh" begin
    include("cmesh/test_readmshfile.jl")
end

@testset "forest" begin
    include("forest/test_element_volume.jl")
end

# NOTE: We have to call sc_finalize before running the examples, since the examples come 
#       with their own sc_init to allow their standalone execution.
@testset "finalize" begin
    @test_nowarn T8code.Libt8.sc_finalize()
end

@testset "examples" begin
    include("test_examples.jl")
end

# CAUTION: The forestWrapper test also covers a MPI hook executed upon finalization of MPI.
#          It therefore has to be executed after all other test cases to avoid a memory balance 
#          error in the next sc_finalize call.
@testset "forestwrapper" begin
    include("test_forestwrapper.jl")
end

end # module
