# This file makes sure to run all examples within the testing suite too.
# It does not add extra sanity checks, assertions etc. to the examples,
# but is intended to make sure the examples run without throwing errors.

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

# Unfortunately, step 5 and step 6 currently crash (1.) in Windows, (2.) in MacOS,
# and (3.) with Julia older than 1.9, see related issues
# https://github.com/DLR-AMR/T8code.jl/issues/26,
# https://github.com/DLR-AMR/T8code.jl/issues/30,
# https://github.com/DLR-AMR/T8code.jl/issues/104.
# Until they are resolved, the two cases are skipped.

# @testset "t8_step5_element_data" begin
#     include("../examples/t8_step5_element_data.jl")
# end

# @testset "t8_step6_stencil" begin
#     include("../examples/t8_step6_stencil.jl")
# end

@testset "t8_tutorial_build_cmesh" begin
    include("../examples/t8_tutorial_build_cmesh.jl")
end
