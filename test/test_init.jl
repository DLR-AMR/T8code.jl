@testset "T8code.uses_mpi" begin
  @test T8code.uses_mpi() == true
end

@testset "T8code.init" begin
  @test_nowarn sc_init(comm, 1, 1, C_NULL, SC_LP_DEFAULT)
  @test_nowarn t8_init(SC_LP_DEFAULT)
end

@testset "sc_ functions" begin
  @test_nowarn sc_version()
  @test_nowarn sc_version_major()
  @test_nowarn sc_version_minor()
  @test unsafe_load(cglobal((:sc_package_id, P4est.LibP4est.libsc), Cint)) == 0
end
