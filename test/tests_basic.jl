module TestsBasic

using Test
using MPI: MPI
using P4est
using T8code

@testset "basic tests" begin
  MPI.Init()

  @testset "T8code.uses_mpi" begin
    @test T8code.uses_mpi() == true
  end
  
  @testset "T8code.init" begin
    @test_nowarn sc_init(MPI.COMM_WORLD.val, 1, 1, C_NULL, SC_LP_DEFAULT)
    @test_nowarn t8_init(SC_LP_DEFAULT)
  end

  @testset "sc_ functions" begin
    @test_nowarn sc_version()
    @test_nowarn sc_version_major()
    @test_nowarn sc_version_minor()
    @test unsafe_load(cglobal((:sc_package_id, P4est.LibP4est.libsc), Cint)) == 0
  end
end

@testset "general tests" begin
  include("test_refcount.jl")
end

@testset "cmesh" begin
  include("test_cmesh_readmshfile.jl")
end

end # module
