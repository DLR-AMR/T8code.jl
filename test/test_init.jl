@testset "T8code.uses_mpi" begin
  @test T8code.uses_mpi() == true
end

@testset "T8code.init" begin
  @test_nowarn T8code.Libt8.sc_init(comm, 1, 1, C_NULL, SC_LP_DEFAULT)
  @test_nowarn t8_init(SC_LP_DEFAULT)
end

@testset "sc_ functions" begin
  @test_nowarn T8code.Libt8.sc_version()
  @test_nowarn T8code.Libt8.sc_version_major()
  @test_nowarn T8code.Libt8.sc_version_minor()
end
