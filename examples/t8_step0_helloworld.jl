# See also: https://github.com/DLR-AMR/t8code/wiki/Step-0---Hello-World
# 
# In this example we initialize t8code and print a small welcome message.
# This is the t8code equivalent of HelloWorld. */

using MPI
using T8code
using T8code.Libt8: sc_init
using T8code.Libt8: sc_finalize
using T8code.Libt8: SC_LP_ESSENTIAL
using T8code.Libt8: SC_LP_PRODUCTION

# Initialize MPI. This has to happen before we initialize sc or t8code.
mpiret = MPI.Init()

comm = MPI.COMM_WORLD

# Initialize the sc library, has to happen before we initialize t8code.
sc_init(comm, 0, 1, C_NULL, SC_LP_ESSENTIAL)

# Initialize t8code with log level SC_LP_PRODUCTION. See sc.h for more info on the log levels.
t8_init(SC_LP_PRODUCTION)

# Print a message on the root process.
t8_global_productionf(" [step0] \n")
t8_global_productionf(" [step0] Hello, this is t8code :)\n")
t8_global_productionf(" [step0] \n")

sc_finalize()
