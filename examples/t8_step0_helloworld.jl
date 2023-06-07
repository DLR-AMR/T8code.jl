# See also: https://github.com/DLR-AMR/t8code/wiki/Step-0---Hello-World
# 
# In this example we initialize t8code and print a small welcome message.
# This is the t8code equivalent of HelloWorld. */

using MPI
using P4est
using T8code

# Initialize MPI. This has to happen before we initialize sc or t8code.
mpiret = MPI.Init()

# Initialize the sc library, has to happen before we initialize t8code.
sc_init(MPI.COMM_WORLD, 1, 1, C_NULL, SC_LP_ESSENTIAL)

# Initialize t8code with log level SC_LP_PRODUCTION. See sc.h for more info on the log levels.
t8_init(SC_LP_PRODUCTION)

# Print a message on the root process.
t8_global_productionf(" [step0] \n")
t8_global_productionf(" [step0] Hello, this is t8code :)\n")
t8_global_productionf(" [step0] \n")

sc_finalize()
