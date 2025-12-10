
# This file makes sure to run all examples within the testing suite too.
# It does not add extra sanity checks, assertions etc. to the examples,
# but is intended to make sure the exampples run without throwing errors.

include("../examples/t8_step0_helloworld.jl")

include("../examples/t8_step1_coarsemesh.jl")

include("../examples/t8_step2_uniform_forest.jl")

include("../examples/t8_step3_adapt_forest.jl")

include("../examples/t8_step4_partition_balance_ghost.jl")

include("../examples/t8_step5_element_data.jl")

include("../examples/t8_step6_stencil.jl")

include("../examples/t8_tutorial_build_cmesh.jl")
