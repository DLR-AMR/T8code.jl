
# This file makes sure to run all examples within the testing suite too.
# It does not add extra sanity checks, assertions etc. to the examples,
# but is intended to make sure the exampples run without throwing errors.

@testset "t8_step0_helloworld" begin
  include("../examples/t8_step0_helloworld.jl")
end

@testset "t8_step1_coarsemesh" begin
  include("../examples/t8_step1_coarsemesh.jl")
end

@testset "t8_step2_uniform_forest" begin
  include("../examples/t8_step2_uniform_forest.jl")
end

@testset "t8_step3_adapt_forest" begin
  include("../examples/t8_step3_adapt_forest.jl")
end

@testset "t8_step4_partition_balance_ghost" begin
  include("../examples/t8_step4_partition_balance_ghost.jl")
end

if !Sys.iswindows()
  @testset "t8_step5_element_data" begin
    include("../examples/t8_step5_element_data.jl")
  end
end

if !Sys.iswindows()
  @testset "t8_step6_stencil" begin
    include("../examples/t8_step6_stencil.jl")
  end
end

@testset "t8_tutorial_build_cmesh" begin
  include("../examples/t8_tutorial_build_cmesh.jl")
end
