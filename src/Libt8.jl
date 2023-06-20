module Libt8

using CEnum

to_c_type(t::Type) = t
to_c_type_pairs(va_list) = map(enumerate(to_c_type.(va_list))) do (ind, type)
    :(va_list[$ind]::$type)
end

using t8code_jll: t8code_jll
export t8code_jll

using ..T8code: _PREFERENCE_LIBT8, _PREFERENCE_LIBP4EST, _PREFERENCE_LIBSC

@static if _PREFERENCE_LIBT8 == "t8code_jll"
    const libt8 = t8code_jll.libt8
else
    const libt8 = _PREFERENCE_LIBT8
end

@static if _PREFERENCE_LIBP4EST == "t8code_jll"
    const libp4est = t8code_jll.libp4est
else
    const libp4est = _PREFERENCE_LIBP4EST
end

@static if _PREFERENCE_LIBSC == "t8code_jll"
    const libsc = t8code_jll.libsc
else
    const libsc = _PREFERENCE_LIBSC
end

# Define missing types
const ptrdiff_t = Cptrdiff_t

# Definitions used from MPI.jl
using MPI: MPI, MPI_Datatype, MPI_Comm, MPI_Group, MPI_File

const MPI_COMM_WORLD = MPI.COMM_WORLD
const MPI_COMM_SELF = MPI.COMM_SELF
const MPI_CHAR = MPI.CHAR
const MPI_SIGNED_CHAR = MPI.SIGNED_CHAR
const MPI_UNSIGNED_CHAR = MPI.UNSIGNED_CHAR
const MPI_BYTE = MPI.BYTE
const MPI_SHORT = MPI.SHORT
const MPI_UNSIGNED_SHORT = MPI.UNSIGNED_SHORT
const MPI_INT = MPI.INT
const MPI_UNSIGNED = MPI.UNSIGNED
const MPI_LONG = MPI.LONG
const MPI_UNSIGNED_LONG = MPI.UNSIGNED_LONG
const MPI_LONG_LONG_INT = MPI.LONG_LONG_INT
const MPI_UNSIGNED_LONG_LONG = MPI.UNSIGNED_LONG_LONG
const MPI_FLOAT = MPI.FLOAT
const MPI_DOUBLE = MPI.DOUBLE

# Other definitions
const INT32_MIN = typemin(Cint)
const INT32_MAX = typemax(Cint)
const INT64_MIN = typemin(Clonglong)
const INT64_MAX = typemax(Clonglong)


"""
    sc_abort_verbose(filename, lineno, msg)

Print a message to stderr and then call [`sc_abort`](@ref) ().

### Prototype
```c
void sc_abort_verbose (const char *filename, int lineno, const char *msg) __attribute__ ((noreturn));
```
"""
function sc_abort_verbose(filename, lineno, msg)
    @ccall libsc.sc_abort_verbose(filename::Cstring, lineno::Cint, msg::Cstring)::Cvoid
end

# automatic type deduction for variadic arguments may not be what you want, please use with caution
@generated function sc_abort_verbosef(filename, lineno, fmt, va_list...)
        :(@ccall(libsc.sc_abort_verbosef(filename::Cstring, lineno::Cint, fmt::Cstring; $(to_c_type_pairs(va_list)...))::Cvoid))
    end

"""
    sc_malloc(package, size)

### Prototype
```c
void *sc_malloc (int package, size_t size);
```
"""
function sc_malloc(package, size)
    @ccall libsc.sc_malloc(package::Cint, size::Csize_t)::Ptr{Cvoid}
end

"""
    sc_calloc(package, nmemb, size)

### Prototype
```c
void *sc_calloc (int package, size_t nmemb, size_t size);
```
"""
function sc_calloc(package, nmemb, size)
    @ccall libsc.sc_calloc(package::Cint, nmemb::Csize_t, size::Csize_t)::Ptr{Cvoid}
end

"""
    sc_realloc(package, ptr, size)

### Prototype
```c
void *sc_realloc (int package, void *ptr, size_t size);
```
"""
function sc_realloc(package, ptr, size)
    @ccall libsc.sc_realloc(package::Cint, ptr::Ptr{Cvoid}, size::Csize_t)::Ptr{Cvoid}
end

"""
    sc_strdup(package, s)

### Prototype
```c
char *sc_strdup (int package, const char *s);
```
"""
function sc_strdup(package, s)
    @ccall libsc.sc_strdup(package::Cint, s::Cstring)::Cstring
end

"""
    sc_free(package, ptr)

### Prototype
```c
void sc_free (int package, void *ptr);
```
"""
function sc_free(package, ptr)
    @ccall libsc.sc_free(package::Cint, ptr::Ptr{Cvoid})::Cvoid
end

"""
    sc_log(filename, lineno, package, category, priority, msg)

The central log function to be called by all packages. Dispatches the log calls by package and filters by category and priority.

### Parameters
* `package`:\\[in\\] Must be a registered package id or -1.
* `category`:\\[in\\] Must be `SC_LC_NORMAL` or `SC_LC_GLOBAL`.
* `priority`:\\[in\\] Must be > `SC_LP_ALWAYS` and < `SC_LP_SILENT`.
### Prototype
```c
void sc_log (const char *filename, int lineno, int package, int category, int priority, const char *msg);
```
"""
function sc_log(filename, lineno, package, category, priority, msg)
    @ccall libsc.sc_log(filename::Cstring, lineno::Cint, package::Cint, category::Cint, priority::Cint, msg::Cstring)::Cvoid
end

# automatic type deduction for variadic arguments may not be what you want, please use with caution
@generated function sc_logf(filename, lineno, package, category, priority, fmt, va_list...)
        :(@ccall(libsc.sc_logf(filename::Cstring, lineno::Cint, package::Cint, category::Cint, priority::Cint, fmt::Cstring; $(to_c_type_pairs(va_list)...))::Cvoid))
    end

"""
    sc_array

The [`sc_array`](@ref) object provides a dynamic array of equal-size elements. Elements are accessed by their 0-based index. Their address may change. The number of elements (== elem\\_count) of the array can be changed by  sc_array_resize and sc_array_rewind. Elements can be sorted with sc_array_sort. If the array is sorted, it can be searched with sc_array_bsearch. A priority queue is implemented with pqueue\\_add and pqueue\\_pop (untested).

| Field        | Note                                                                                                                                            |
| :----------- | :---------------------------------------------------------------------------------------------------------------------------------------------- |
| elem\\_size  | size of a single element                                                                                                                        |
| elem\\_count | number of valid elements                                                                                                                        |
| byte\\_alloc | number of allocated bytes or -(number of viewed bytes + 1) if this is a view: the "+ 1" distinguishes an array of size 0 from a view of size 0  |
| array        | linear array to store elements                                                                                                                  |
"""
struct sc_array
    elem_size::Csize_t
    elem_count::Csize_t
    byte_alloc::Cssize_t
    array::Ptr{Int8}
end

"""The [`sc_array`](@ref) object provides a dynamic array of equal-size elements. Elements are accessed by their 0-based index. Their address may change. The number of elements (== elem\\_count) of the array can be changed by  sc_array_resize and sc_array_rewind. Elements can be sorted with sc_array_sort. If the array is sorted, it can be searched with sc_array_bsearch. A priority queue is implemented with pqueue\\_add and pqueue\\_pop (untested)."""
const sc_array_t = sc_array

"""
    sc_array_new_count(elem_size, elem_count)

Creates a new array structure with a given length (number of elements).

### Parameters
* `elem_size`:\\[in\\] Size of one array element in bytes.
* `elem_count`:\\[in\\] Initial number of array elements.
### Returns
Return an allocated array with allocated but uninitialized elements.
### Prototype
```c
sc_array_t *sc_array_new_count (size_t elem_size, size_t elem_count);
```
"""
function sc_array_new_count(elem_size, elem_count)
    @ccall libsc.sc_array_new_count(elem_size::Csize_t, elem_count::Csize_t)::Ptr{sc_array_t}
end

"""
    t8_get_package_id()

Query the package identity as registered in libsc.

### Returns
This is -1 before t8_init has been called and a proper package identifier afterwards.
### Prototype
```c
int t8_get_package_id (void);
```
"""
function t8_get_package_id()
    @ccall libt8.t8_get_package_id()::Cint
end

"""A type for processor-local indexing."""
const t8_locidx_t = Int32

"""
    sc_int32_compare(v1, v2)

### Prototype
```c
int sc_int32_compare (const void *v1, const void *v2);
```
"""
function sc_int32_compare(v1, v2)
    @ccall libsc.sc_int32_compare(v1::Ptr{Cvoid}, v2::Ptr{Cvoid})::Cint
end

"""A type for global indexing that holds really big numbers."""
const t8_gloidx_t = Int64

"""
    sc_int64_compare(v1, v2)

### Prototype
```c
int sc_int64_compare (const void *v1, const void *v2);
```
"""
function sc_int64_compare(v1, v2)
    @ccall libsc.sc_int64_compare(v1::Ptr{Cvoid}, v2::Ptr{Cvoid})::Cint
end

"""
    sc_shmem_malloc(package, elem_size, elem_count, comm)

### Prototype
```c
void *sc_shmem_malloc (int package, size_t elem_size, size_t elem_count, sc_MPI_Comm comm);
```
"""
function sc_shmem_malloc(package, elem_size, elem_count, comm)
    @ccall libsc.sc_shmem_malloc(package::Cint, elem_size::Csize_t, elem_count::Csize_t, comm::MPI_Comm)::Ptr{Cvoid}
end

"""
    sc_shmem_free(package, array, comm)

### Prototype
```c
void sc_shmem_free (int package, void *array, sc_MPI_Comm comm);
```
"""
function sc_shmem_free(package, array, comm)
    @ccall libsc.sc_shmem_free(package::Cint, array::Ptr{Cvoid}, comm::MPI_Comm)::Cvoid
end

"""
    sc_tag_t

Enumerate all MPI tags used internally to the sc library.

| Enumerator                        | Note                               |
| :-------------------------------- | :--------------------------------- |
| SC\\_TAG\\_FIRST                  | Anything really.                   |
| SC\\_TAG\\_AG\\_ALLTOALL          | Used in MPI alltoall replacement.  |
| SC\\_TAG\\_AG\\_RECURSIVE\\_A     | Internal tag; do not use.          |
| SC\\_TAG\\_AG\\_RECURSIVE\\_B     |                                    |
| SC\\_TAG\\_AG\\_RECURSIVE\\_C     |                                    |
| SC\\_TAG\\_NOTIFY\\_CENSUS        | Internal tag to sc_notify.         |
| SC\\_TAG\\_NOTIFY\\_CENSUSV       |                                    |
| SC\\_TAG\\_NOTIFY\\_NBX           |                                    |
| SC\\_TAG\\_NOTIFY\\_NBXV          |                                    |
| SC\\_TAG\\_NOTIFY\\_WRAPPER       |                                    |
| SC\\_TAG\\_NOTIFY\\_WRAPPERV      |                                    |
| SC\\_TAG\\_NOTIFY\\_RANGES        |                                    |
| SC\\_TAG\\_NOTIFY\\_PAYLOAD       |                                    |
| SC\\_TAG\\_NOTIFY\\_SUPER\\_TRUE  |                                    |
| SC\\_TAG\\_NOTIFY\\_SUPER\\_EXTRA |                                    |
| SC\\_TAG\\_NOTIFY\\_RECURSIVE     |                                    |
| SC\\_TAG\\_NOTIFY\\_NARY          |                                    |
| SC\\_TAG\\_REDUCE                 | Used in MPI reduce replacement.    |
| SC\\_TAG\\_PSORT\\_LO             | Internal tag to sc_psort.          |
| SC\\_TAG\\_PSORT\\_HI             |                                    |
| SC\\_TAG\\_LAST                   | End marker of tag enumeration.     |
"""
@cenum sc_tag_t::UInt32 begin
    SC_TAG_FIRST = 214
    SC_TAG_AG_ALLTOALL = 214
    SC_TAG_AG_RECURSIVE_A = 215
    SC_TAG_AG_RECURSIVE_B = 216
    SC_TAG_AG_RECURSIVE_C = 217
    SC_TAG_NOTIFY_CENSUS = 218
    SC_TAG_NOTIFY_CENSUSV = 219
    SC_TAG_NOTIFY_NBX = 220
    SC_TAG_NOTIFY_NBXV = 221
    SC_TAG_NOTIFY_WRAPPER = 222
    SC_TAG_NOTIFY_WRAPPERV = 223
    SC_TAG_NOTIFY_RANGES = 224
    SC_TAG_NOTIFY_PAYLOAD = 225
    SC_TAG_NOTIFY_SUPER_TRUE = 226
    SC_TAG_NOTIFY_SUPER_EXTRA = 227
    SC_TAG_NOTIFY_RECURSIVE = 228
    SC_TAG_NOTIFY_NARY = 260
    SC_TAG_REDUCE = 292
    SC_TAG_PSORT_LO = 293
    SC_TAG_PSORT_HI = 294
    SC_TAG_LAST = 295
end

"""
    sc_MPI_Testall(arg1, arg2, arg3, arg4)

### Prototype
```c
int sc_MPI_Testall (int, sc_MPI_Request *, int *, sc_MPI_Status *);
```
"""
function sc_MPI_Testall(arg1, arg2, arg3, arg4)
    @ccall libsc.sc_MPI_Testall(arg1::Cint, arg2::Ptr{Cint}, arg3::Ptr{Cint}, arg4::Ptr{Cint})::Cint
end

"""
    sc_MPI_Error_class(errorcode, errorclass)

Turn an MPI error code into its error class. When MPI is enabled, we pass version 1.1 errors to MPI\\_Error\\_class. When MPI I/O is not enabled, we process file errors outside of MPI. Thus, within libsc, it is always legal to call this function with any errorcode defined above in this header file.

### Parameters
* `errorcode`:\\[in\\] Returned from a direct MPI call or libsc.
* `errorclass`:\\[out\\] Non-NULL pointer. Filled with matching error class on success.
### Returns
[`sc_MPI_SUCCESS`](@ref) on successful conversion, Other MPI error code otherwise.
### Prototype
```c
int sc_MPI_Error_class (int errorcode, int *errorclass);
```
"""
function sc_MPI_Error_class(errorcode, errorclass)
    @ccall libsc.sc_MPI_Error_class(errorcode::Cint, errorclass::Ptr{Cint})::Cint
end

"""
    sc_MPI_Error_string(errorcode, string, resultlen)

Turn MPI error code into a string.

### Parameters
* `errorcode`:\\[in\\] This (MPI) error code is converted.
* `string`:\\[in,out\\] At least [`sc_MPI_MAX_ERROR_STRING`](@ref) bytes.
* `resultlen`:\\[out\\] Length of string on return.
### Returns
[`sc_MPI_SUCCESS`](@ref) on success or other MPI error cocde on invalid arguments.
### Prototype
```c
int sc_MPI_Error_string (int errorcode, char *string, int *resultlen);
```
"""
function sc_MPI_Error_string(errorcode, string, resultlen)
    @ccall libsc.sc_MPI_Error_string(errorcode::Cint, string::Cstring, resultlen::Ptr{Cint})::Cint
end

"""
    sc_mpi_sizeof(t)

### Prototype
```c
size_t sc_mpi_sizeof (sc_MPI_Datatype t);
```
"""
function sc_mpi_sizeof(t)
    @ccall libsc.sc_mpi_sizeof(t::MPI_Datatype)::Csize_t
end

"""
    sc_mpi_comm_attach_node_comms(comm, processes_per_node)

### Prototype
```c
void sc_mpi_comm_attach_node_comms (sc_MPI_Comm comm, int processes_per_node);
```
"""
function sc_mpi_comm_attach_node_comms(comm, processes_per_node)
    @ccall libsc.sc_mpi_comm_attach_node_comms(comm::MPI_Comm, processes_per_node::Cint)::Cvoid
end

"""
    sc_mpi_comm_detach_node_comms(comm)

### Prototype
```c
void sc_mpi_comm_detach_node_comms (sc_MPI_Comm comm);
```
"""
function sc_mpi_comm_detach_node_comms(comm)
    @ccall libsc.sc_mpi_comm_detach_node_comms(comm::MPI_Comm)::Cvoid
end

"""
    sc_mpi_comm_get_node_comms(comm, intranode, internode)

### Prototype
```c
void sc_mpi_comm_get_node_comms (sc_MPI_Comm comm, sc_MPI_Comm * intranode, sc_MPI_Comm * internode);
```
"""
function sc_mpi_comm_get_node_comms(comm, intranode, internode)
    @ccall libsc.sc_mpi_comm_get_node_comms(comm::MPI_Comm, intranode::Ptr{MPI_Comm}, internode::Ptr{MPI_Comm})::Cvoid
end

"""
    sc_mpi_comm_get_and_attach(comm)

### Prototype
```c
int sc_mpi_comm_get_and_attach (sc_MPI_Comm comm);
```
"""
function sc_mpi_comm_get_and_attach(comm)
    @ccall libsc.sc_mpi_comm_get_and_attach(comm::MPI_Comm)::Cint
end

# typedef void ( * sc_handler_t ) ( void * data )
const sc_handler_t = Ptr{Cvoid}

# typedef void ( * sc_log_handler_t ) ( FILE * log_stream , const char * filename , int lineno , int package , int category , int priority , const char * msg )
const sc_log_handler_t = Ptr{Cvoid}

# typedef void ( * sc_abort_handler_t ) ( void )
"""Type of the abort handler function."""
const sc_abort_handler_t = Ptr{Cvoid}

"""
    sc_memory_status(package)

### Prototype
```c
int sc_memory_status (int package);
```
"""
function sc_memory_status(package)
    @ccall libsc.sc_memory_status(package::Cint)::Cint
end

"""
    sc_memory_check(package)

### Prototype
```c
void sc_memory_check (int package);
```
"""
function sc_memory_check(package)
    @ccall libsc.sc_memory_check(package::Cint)::Cvoid
end

"""
    sc_memory_check_noerr(package)

Return error count or zero if all is ok.

### Prototype
```c
int sc_memory_check_noerr (int package);
```
"""
function sc_memory_check_noerr(package)
    @ccall libsc.sc_memory_check_noerr(package::Cint)::Cint
end

"""
    sc_int_compare(v1, v2)

### Prototype
```c
int sc_int_compare (const void *v1, const void *v2);
```
"""
function sc_int_compare(v1, v2)
    @ccall libsc.sc_int_compare(v1::Ptr{Cvoid}, v2::Ptr{Cvoid})::Cint
end

"""
    sc_int8_compare(v1, v2)

### Prototype
```c
int sc_int8_compare (const void *v1, const void *v2);
```
"""
function sc_int8_compare(v1, v2)
    @ccall libsc.sc_int8_compare(v1::Ptr{Cvoid}, v2::Ptr{Cvoid})::Cint
end

"""
    sc_int16_compare(v1, v2)

### Prototype
```c
int sc_int16_compare (const void *v1, const void *v2);
```
"""
function sc_int16_compare(v1, v2)
    @ccall libsc.sc_int16_compare(v1::Ptr{Cvoid}, v2::Ptr{Cvoid})::Cint
end

"""
    sc_double_compare(v1, v2)

### Prototype
```c
int sc_double_compare (const void *v1, const void *v2);
```
"""
function sc_double_compare(v1, v2)
    @ccall libsc.sc_double_compare(v1::Ptr{Cvoid}, v2::Ptr{Cvoid})::Cint
end

"""
    sc_atoi(nptr)

Safe version of the standard library atoi (3) function.

### Parameters
* `nptr`:\\[in\\] NUL-terminated string.
### Returns
Converted integer value. 0 if no valid number. INT\\_MAX on overflow, INT\\_MIN on underflow.
### Prototype
```c
int sc_atoi (const char *nptr);
```
"""
function sc_atoi(nptr)
    @ccall libsc.sc_atoi(nptr::Cstring)::Cint
end

"""
    sc_atol(nptr)

Safe version of the standard library atol (3) function.

### Parameters
* `nptr`:\\[in\\] NUL-terminated string.
### Returns
Converted long value. 0 if no valid number. LONG\\_MAX on overflow, LONG\\_MIN on underflow.
### Prototype
```c
long sc_atol (const char *nptr);
```
"""
function sc_atol(nptr)
    @ccall libsc.sc_atol(nptr::Cstring)::Clong
end

"""
    sc_set_log_defaults(log_stream, log_handler, log_threshold)

Controls the default SC log behavior.

### Parameters
* `log_stream`:\\[in\\] Set stream to use by `sc_logf` (or NULL for stdout).
* `log_handler`:\\[in\\] Set default SC log handler (NULL selects builtin).
* `log_threshold`:\\[in\\] Set default SC log threshold (or `SC_LP_DEFAULT`). May be `SC_LP_ALWAYS` or `SC_LP_SILENT`.
### Prototype
```c
void sc_set_log_defaults (FILE * log_stream, sc_log_handler_t log_handler, int log_threshold);
```
"""
function sc_set_log_defaults(log_stream, log_handler, log_threshold)
    @ccall libsc.sc_set_log_defaults(log_stream::Ptr{Libc.FILE}, log_handler::sc_log_handler_t, log_threshold::Cint)::Cvoid
end

"""
    sc_set_abort_handler(abort_handler)

Set the default SC abort behavior.

### Parameters
* `abort_handler`:\\[in\\] Set default SC above handler (NULL selects builtin). If it returns, we abort (2) then.
### Prototype
```c
void sc_set_abort_handler (sc_abort_handler_t abort_handler);
```
"""
function sc_set_abort_handler(abort_handler)
    @ccall libsc.sc_set_abort_handler(abort_handler::sc_abort_handler_t)::Cvoid
end

"""
    sc_log_indent_push_count(package, count)

Add spaces to the start of a package's default log format.

### Prototype
```c
void sc_log_indent_push_count (int package, int count);
```
"""
function sc_log_indent_push_count(package, count)
    @ccall libsc.sc_log_indent_push_count(package::Cint, count::Cint)::Cvoid
end

"""
    sc_log_indent_pop_count(package, count)

Remove spaces from the start of a package's default log format.

### Prototype
```c
void sc_log_indent_pop_count (int package, int count);
```
"""
function sc_log_indent_pop_count(package, count)
    @ccall libsc.sc_log_indent_pop_count(package::Cint, count::Cint)::Cvoid
end

"""
    sc_log_indent_push()

Add one space to the start of sc's default log format.

### Prototype
```c
void sc_log_indent_push (void);
```
"""
function sc_log_indent_push()
    @ccall libsc.sc_log_indent_push()::Cvoid
end

"""
    sc_log_indent_pop()

Remove one space from the start of a sc's default log format.

### Prototype
```c
void sc_log_indent_pop (void);
```
"""
function sc_log_indent_pop()
    @ccall libsc.sc_log_indent_pop()::Cvoid
end

"""
    sc_abort()

Print a stack trace, call the abort handler and then call abort ().

### Prototype
```c
void sc_abort (void) __attribute__ ((noreturn));
```
"""
function sc_abort()
    @ccall libsc.sc_abort()::Cvoid
end

"""
    sc_abort_collective(msg)

Collective abort where only root prints a message

### Prototype
```c
void sc_abort_collective (const char *msg) __attribute__ ((noreturn));
```
"""
function sc_abort_collective(msg)
    @ccall libsc.sc_abort_collective(msg::Cstring)::Cvoid
end

"""
    sc_package_register(log_handler, log_threshold, name, full)

Register a software package with SC. This function must only be called before additional threads are created. The logging parameters are as in [`sc_set_log_defaults`](@ref).

### Returns
Returns a unique package id.
### Prototype
```c
int sc_package_register (sc_log_handler_t log_handler, int log_threshold, const char *name, const char *full);
```
"""
function sc_package_register(log_handler, log_threshold, name, full)
    @ccall libsc.sc_package_register(log_handler::sc_log_handler_t, log_threshold::Cint, name::Cstring, full::Cstring)::Cint
end

"""
    sc_package_is_registered(package_id)

Query whether an identifier matches a registered package.

### Parameters
* `package_id`:\\[in\\] Only a non-negative id can be registered.
### Returns
True if and only if the package id is non-negative and package is registered.
### Prototype
```c
int sc_package_is_registered (int package_id);
```
"""
function sc_package_is_registered(package_id)
    @ccall libsc.sc_package_is_registered(package_id::Cint)::Cint
end

"""
    sc_package_lock(package_id)

Acquire a pthread mutex lock. If configured without --enable-pthread, this function does nothing. This function must be followed with a matching sc_package_unlock.

### Parameters
* `package_id`:\\[in\\] Either -1 for an undefined package or an id returned from sc_package_register. Depending on the value, the appropriate mutex is chosen. Thus, we may overlap locking calls with distinct package\\_id.
### Prototype
```c
void sc_package_lock (int package_id);
```
"""
function sc_package_lock(package_id)
    @ccall libsc.sc_package_lock(package_id::Cint)::Cvoid
end

"""
    sc_package_unlock(package_id)

Release a pthread mutex lock. If configured without --enable-pthread, this function does nothing. This function must be follow a matching sc_package_lock.

### Parameters
* `package_id`:\\[in\\] Either -1 for an undefined package or an id returned from sc_package_register. Depending on the value, the appropriate mutex is chosen. Thus, we may overlap locking calls with distinct package\\_id.
### Prototype
```c
void sc_package_unlock (int package_id);
```
"""
function sc_package_unlock(package_id)
    @ccall libsc.sc_package_unlock(package_id::Cint)::Cvoid
end

"""
    sc_package_set_verbosity(package_id, log_priority)

Set the logging verbosity of a registered package. This can be called at any point in the program, any number of times. It can only lower the verbosity at and below the value of `SC_LP_THRESHOLD`.

### Parameters
* `package_id`:\\[in\\] Must be a registered package identifier.
### Prototype
```c
void sc_package_set_verbosity (int package_id, int log_priority);
```
"""
function sc_package_set_verbosity(package_id, log_priority)
    @ccall libsc.sc_package_set_verbosity(package_id::Cint, log_priority::Cint)::Cvoid
end

"""
    sc_package_set_abort_alloc_mismatch(package_id, set_abort)

Set the unregister behavior of [`sc_package_unregister`](@ref)().

### Parameters
* `package_id`:\\[in\\] Must be -1 for the default package or the identifier of a registered package.
* `set_abort`:\\[in\\] True if [`sc_package_unregister`](@ref)() should abort if the number of allocs does not match the number of frees; false otherwise.
### Prototype
```c
void sc_package_set_abort_alloc_mismatch (int package_id, int set_abort);
```
"""
function sc_package_set_abort_alloc_mismatch(package_id, set_abort)
    @ccall libsc.sc_package_set_abort_alloc_mismatch(package_id::Cint, set_abort::Cint)::Cvoid
end

"""
    sc_package_unregister(package_id)

Unregister a software package with SC. This function must only be called after additional threads are finished.

### Prototype
```c
void sc_package_unregister (int package_id);
```
"""
function sc_package_unregister(package_id)
    @ccall libsc.sc_package_unregister(package_id::Cint)::Cvoid
end

"""
    sc_package_print_summary(log_priority)

Print a summary of all packages registered with SC. Uses the `SC_LC_GLOBAL` log category which by default only prints on rank 0.

### Parameters
* `log_priority`:\\[in\\] Priority passed to sc log functions.
### Prototype
```c
void sc_package_print_summary (int log_priority);
```
"""
function sc_package_print_summary(log_priority)
    @ccall libsc.sc_package_print_summary(log_priority::Cint)::Cvoid
end

"""
    sc_init(mpicomm, catch_signals, print_backtrace, log_handler, log_threshold)

### Prototype
```c
void sc_init (sc_MPI_Comm mpicomm, int catch_signals, int print_backtrace, sc_log_handler_t log_handler, int log_threshold);
```
"""
function sc_init(mpicomm, catch_signals, print_backtrace, log_handler, log_threshold)
    @ccall libsc.sc_init(mpicomm::MPI_Comm, catch_signals::Cint, print_backtrace::Cint, log_handler::sc_log_handler_t, log_threshold::Cint)::Cvoid
end

"""
    sc_finalize()

Unregisters all packages, runs the memory check, removes the signal handlers and resets sc\\_identifier and sc\\_root\\_*. This function aborts on any inconsistency found unless the global variable default\\_abort\\_mismatch is false. This function is optional. This function does not require [`sc_init`](@ref) to be called first.

### Prototype
```c
void sc_finalize (void);
```
"""
function sc_finalize()
    @ccall libsc.sc_finalize()::Cvoid
end

"""
    sc_finalize_noabort()

Unregisters all packages, runs the memory check, removes the signal handlers and resets sc\\_identifier and sc\\_root\\_*. This function never aborts but returns the number of errors encountered. This function is optional. This function does not require [`sc_init`](@ref) to be called first.

### Returns
0 when everything is consistent, nonzero otherwise.
### Prototype
```c
int sc_finalize_noabort (void);
```
"""
function sc_finalize_noabort()
    @ccall libsc.sc_finalize_noabort()::Cint
end

"""
    sc_is_root()

Identify the root process. Only meaningful between [`sc_init`](@ref) and [`sc_finalize`](@ref) and with a communicator that is not `sc_MPI_COMM_NULL` (otherwise always true).

### Returns
Return true for the root process and false otherwise.
### Prototype
```c
int sc_is_root (void);
```
"""
function sc_is_root()
    @ccall libsc.sc_is_root()::Cint
end

"""
    sc_strcopy(dest, size, src)

Provide a string copy function.

### Parameters
* `dest`:\\[out\\] Buffer of length at least *size*. On output, not touched if NULL or *size* == 0. Otherwise, *src* is copied to *dest* and *dest* is padded with '\\0' from the right if strlen (src) < size - 1.
* `size`:\\[in\\] Allocation length of *dest*.
* `src`:\\[in\\] Null-terminated string.
### Returns
Equivalent to sc_snprintf (dest, size, "s", src).
### Prototype
```c
void sc_strcopy (char *dest, size_t size, const char *src);
```
"""
function sc_strcopy(dest, size, src)
    @ccall libsc.sc_strcopy(dest::Cstring, size::Csize_t, src::Cstring)::Cvoid
end

# automatic type deduction for variadic arguments may not be what you want, please use with caution
@generated function sc_snprintf(str, size, format, va_list...)
        :(@ccall(libsc.sc_snprintf(str::Cstring, size::Csize_t, format::Cstring; $(to_c_type_pairs(va_list)...))::Cvoid))
    end

"""
    sc_version()

Return the full version of libsc.

### Returns
Return the version of libsc using the format `VERSION\\_MAJOR.VERSION\\_MINOR.VERSION\\_POINT`, where `VERSION_POINT` can contain dots and characters, e.g. to indicate the additional number of commits and a git commit hash.
### Prototype
```c
const char *sc_version (void);
```
"""
function sc_version()
    @ccall libsc.sc_version()::Cstring
end

"""
    sc_version_major()

Return the major version of libsc.

### Returns
Return the major version of libsc.
### Prototype
```c
int sc_version_major (void);
```
"""
function sc_version_major()
    @ccall libsc.sc_version_major()::Cint
end

"""
    sc_version_minor()

Return the minor version of libsc.

### Returns
Return the minor version of libsc.
### Prototype
```c
int sc_version_minor (void);
```
"""
function sc_version_minor()
    @ccall libsc.sc_version_minor()::Cint
end

"""
    sc_have_json()

Return whether we have found a JSON library at configure time.

### Returns
True if and only if SC\\_HAVE\\_JSON is defined.
### Prototype
```c
int sc_have_json (void);
```
"""
function sc_have_json()
    @ccall libsc.sc_have_json()::Cint
end

# typedef unsigned int ( * sc_hash_function_t ) ( const void * v , const void * u )
"""
Function to compute a hash value of an object.

### Parameters
* `v`:\\[in\\] The object to hash.
* `u`:\\[in\\] Arbitrary user data.
### Returns
Returns an unsigned integer.
"""
const sc_hash_function_t = Ptr{Cvoid}

# typedef int ( * sc_equal_function_t ) ( const void * v1 , const void * v2 , const void * u )
"""
Function to check equality of two objects.

### Parameters
* `u`:\\[in\\] Arbitrary user data.
### Returns
Returns false if *v1 is unequal *v2 and true otherwise.
"""
const sc_equal_function_t = Ptr{Cvoid}

# typedef int ( * sc_hash_foreach_t ) ( void * * v , const void * u )
"""
Function to call on every data item of a hash table.

### Parameters
* `v`:\\[in\\] The address of the pointer to the current object.
* `u`:\\[in\\] Arbitrary user data.
### Returns
Return true if the traversal should continue, false to stop.
"""
const sc_hash_foreach_t = Ptr{Cvoid}

"""
    sc_array_memory_used(array, is_dynamic)

Calculate the memory used by an array.

### Parameters
* `array`:\\[in\\] The array.
* `is_dynamic`:\\[in\\] True if created with [`sc_array_new`](@ref), false if initialized with [`sc_array_init`](@ref)
### Returns
Memory used in bytes.
### Prototype
```c
size_t sc_array_memory_used (sc_array_t * array, int is_dynamic);
```
"""
function sc_array_memory_used(array, is_dynamic)
    @ccall libsc.sc_array_memory_used(array::Ptr{sc_array_t}, is_dynamic::Cint)::Csize_t
end

"""
    sc_array_new(elem_size)

Creates a new array structure with 0 elements.

### Parameters
* `elem_size`:\\[in\\] Size of one array element in bytes.
### Returns
Return an allocated array of zero length.
### Prototype
```c
sc_array_t *sc_array_new (size_t elem_size);
```
"""
function sc_array_new(elem_size)
    @ccall libsc.sc_array_new(elem_size::Csize_t)::Ptr{sc_array_t}
end

"""
    sc_array_new_view(array, offset, length)

Creates a new view of an existing [`sc_array_t`](@ref).

### Parameters
* `array`:\\[in\\] The array must not be resized while view is alive.
* `offset`:\\[in\\] The offset of the viewed section in element units. This offset cannot be changed until the view is reset.
* `length`:\\[in\\] The length of the viewed section in element units. The view cannot be resized to exceed this length.
### Prototype
```c
sc_array_t *sc_array_new_view (sc_array_t * array, size_t offset, size_t length);
```
"""
function sc_array_new_view(array, offset, length)
    @ccall libsc.sc_array_new_view(array::Ptr{sc_array_t}, offset::Csize_t, length::Csize_t)::Ptr{sc_array_t}
end

"""
    sc_array_new_data(base, elem_size, elem_count)

Creates a new view of an existing plain C array.

### Parameters
* `base`:\\[in\\] The data must not be moved while view is alive.
* `elem_size`:\\[in\\] Size of one array element in bytes.
* `elem_count`:\\[in\\] The length of the view in element units. The view cannot be resized to exceed this length.
### Prototype
```c
sc_array_t *sc_array_new_data (void *base, size_t elem_size, size_t elem_count);
```
"""
function sc_array_new_data(base, elem_size, elem_count)
    @ccall libsc.sc_array_new_data(base::Ptr{Cvoid}, elem_size::Csize_t, elem_count::Csize_t)::Ptr{sc_array_t}
end

"""
    sc_array_destroy(array)

Destroys an array structure.

### Parameters
* `array`:\\[in\\] The array to be destroyed.
### Prototype
```c
void sc_array_destroy (sc_array_t * array);
```
"""
function sc_array_destroy(array)
    @ccall libsc.sc_array_destroy(array::Ptr{sc_array_t})::Cvoid
end

"""
    sc_array_destroy_null(parray)

Destroys an array structure and sets the pointer to NULL.

### Parameters
* `parray`:\\[in,out\\] Pointer to address of array to be destroyed. On output, *parray is NULL.
### Prototype
```c
void sc_array_destroy_null (sc_array_t ** parray);
```
"""
function sc_array_destroy_null(parray)
    @ccall libsc.sc_array_destroy_null(parray::Ptr{Ptr{sc_array_t}})::Cvoid
end

"""
    sc_array_init(array, elem_size)

Initializes an already allocated (or static) array structure.

### Parameters
* `array`:\\[in,out\\] Array structure to be initialized.
* `elem_size`:\\[in\\] Size of one array element in bytes.
### Prototype
```c
void sc_array_init (sc_array_t * array, size_t elem_size);
```
"""
function sc_array_init(array, elem_size)
    @ccall libsc.sc_array_init(array::Ptr{sc_array_t}, elem_size::Csize_t)::Cvoid
end

"""
    sc_array_init_size(array, elem_size, elem_count)

Initializes an already allocated (or static) array structure and allocates a given number of elements. Deprecated: use sc_array_init_count.

### Parameters
* `array`:\\[in,out\\] Array structure to be initialized.
* `elem_size`:\\[in\\] Size of one array element in bytes.
* `elem_count`:\\[in\\] Number of initial array elements.
### Prototype
```c
void sc_array_init_size (sc_array_t * array, size_t elem_size, size_t elem_count);
```
"""
function sc_array_init_size(array, elem_size, elem_count)
    @ccall libsc.sc_array_init_size(array::Ptr{sc_array_t}, elem_size::Csize_t, elem_count::Csize_t)::Cvoid
end

"""
    sc_array_init_count(array, elem_size, elem_count)

Initializes an already allocated (or static) array structure and allocates a given number of elements. This function supersedes sc_array_init_size.

### Parameters
* `array`:\\[in,out\\] Array structure to be initialized.
* `elem_size`:\\[in\\] Size of one array element in bytes.
* `elem_count`:\\[in\\] Number of initial array elements.
### Prototype
```c
void sc_array_init_count (sc_array_t * array, size_t elem_size, size_t elem_count);
```
"""
function sc_array_init_count(array, elem_size, elem_count)
    @ccall libsc.sc_array_init_count(array::Ptr{sc_array_t}, elem_size::Csize_t, elem_count::Csize_t)::Cvoid
end

"""
    sc_array_init_view(view, array, offset, length)

Initializes an already allocated (or static) view from existing [`sc_array_t`](@ref). The array view returned does not require [`sc_array_reset`](@ref) (doesn't hurt though).

### Parameters
* `view`:\\[in,out\\] Array structure to be initialized.
* `array`:\\[in\\] The array must not be resized while view is alive.
* `offset`:\\[in\\] The offset of the viewed section in element units. This offset cannot be changed until the view is reset.
* `length`:\\[in\\] The length of the view in element units. The view cannot be resized to exceed this length. It is not necessary to call [`sc_array_reset`](@ref) later.
### Prototype
```c
void sc_array_init_view (sc_array_t * view, sc_array_t * array, size_t offset, size_t length);
```
"""
function sc_array_init_view(view, array, offset, length)
    @ccall libsc.sc_array_init_view(view::Ptr{sc_array_t}, array::Ptr{sc_array_t}, offset::Csize_t, length::Csize_t)::Cvoid
end

"""
    sc_array_init_reshape(view, array, elem_size, elem_count)

Initialize an already allocated (or static) view from existing [`sc_array_t`](@ref). The total data size of the view is the same, but size and count may differ. The array view returned does not require [`sc_array_reset`](@ref) (doesn't hurt though).

### Parameters
* `view`:\\[in,out\\] Array structure to be initialized.
* `array`:\\[in\\] The array must not be resized while view is alive.
* `elem_size`:\\[in\\] Size of one array element of the view in bytes. The product of size and count of *array* must be the same as *elem_size* * *elem_count*.
* `elem_count`:\\[in\\] The length of the view in element units. The view cannot be resized to exceed this length. It is not necessary to call [`sc_array_reset`](@ref) later.
### Prototype
```c
void sc_array_init_reshape (sc_array_t * view, sc_array_t * array, size_t elem_size, size_t elem_count);
```
"""
function sc_array_init_reshape(view, array, elem_size, elem_count)
    @ccall libsc.sc_array_init_reshape(view::Ptr{sc_array_t}, array::Ptr{sc_array_t}, elem_size::Csize_t, elem_count::Csize_t)::Cvoid
end

"""
    sc_array_init_data(view, base, elem_size, elem_count)

Initializes an already allocated (or static) view from given plain C data. The array view returned does not require [`sc_array_reset`](@ref) (doesn't hurt though).

### Parameters
* `view`:\\[in,out\\] Array structure to be initialized.
* `base`:\\[in\\] The data must not be moved while view is alive.
* `elem_size`:\\[in\\] Size of one array element in bytes.
* `elem_count`:\\[in\\] The length of the view in element units. The view cannot be resized to exceed this length. It is not necessary to call [`sc_array_reset`](@ref) later.
### Prototype
```c
void sc_array_init_data (sc_array_t * view, void *base, size_t elem_size, size_t elem_count);
```
"""
function sc_array_init_data(view, base, elem_size, elem_count)
    @ccall libsc.sc_array_init_data(view::Ptr{sc_array_t}, base::Ptr{Cvoid}, elem_size::Csize_t, elem_count::Csize_t)::Cvoid
end

"""
    sc_array_memset(array, c)

Run memset on the array storage. We pass the character to memset unchanged. Thus, care must be taken when setting values below -1 or above 127, just as with standard memset (3).

### Parameters
* `array`:\\[in,out\\] This array's storage will be overwritten.
* `c`:\\[in\\] Character to overwrite every byte with.
### Prototype
```c
void sc_array_memset (sc_array_t * array, int c);
```
"""
function sc_array_memset(array, c)
    @ccall libsc.sc_array_memset(array::Ptr{sc_array_t}, c::Cint)::Cvoid
end

"""
    sc_array_reset(array)

Sets the array count to zero and frees all elements. This function turns a view into a newly initialized array.

!!! note

    Calling [`sc_array_init`](@ref), then any array operations, then [`sc_array_reset`](@ref) is memory neutral. As an exception, the two functions [`sc_array_init_view`](@ref) and [`sc_array_init_data`](@ref) do not require a subsequent call to [`sc_array_reset`](@ref). Regardless, it is legal to call [`sc_array_reset`](@ref) anyway.

### Parameters
* `array`:\\[in,out\\] Array structure to be reset.
### Prototype
```c
void sc_array_reset (sc_array_t * array);
```
"""
function sc_array_reset(array)
    @ccall libsc.sc_array_reset(array::Ptr{sc_array_t})::Cvoid
end

"""
    sc_array_truncate(array)

Sets the array count to zero, but does not free elements. Not allowed for views.

!!! note

    This is intended to allow an [`sc_array`](@ref) to be used as a reusable buffer, where the "high water mark" of the buffer is preserved, so that O(log (max n)) reallocs occur over the life of the buffer.

### Parameters
* `array`:\\[in,out\\] Array structure to be truncated.
### Prototype
```c
void sc_array_truncate (sc_array_t * array);
```
"""
function sc_array_truncate(array)
    @ccall libsc.sc_array_truncate(array::Ptr{sc_array_t})::Cvoid
end

"""
    sc_array_rewind(array, new_count)

Shorten an array without reallocating it.

### Parameters
* `array`:\\[in,out\\] The element count of this array is modified.
* `new_count`:\\[in\\] Must be less or equal than the **array**'s count. If it is less, the number of elements in the array is reduced without reallocating memory. The exception is a **new_count** of zero specified for an array that is not a view: In this case sc_array_reset is equivalent.
### Prototype
```c
void sc_array_rewind (sc_array_t * array, size_t new_count);
```
"""
function sc_array_rewind(array, new_count)
    @ccall libsc.sc_array_rewind(array::Ptr{sc_array_t}, new_count::Csize_t)::Cvoid
end

"""
    sc_array_resize(array, new_count)

Sets the element count to new\\_count. If the array is not a view, reallocation takes place occasionally. If the array is a view, new\\_count must not be greater than the element count of the view when it was created. The original offset of the view cannot be changed.

### Parameters
* `array`:\\[in,out\\] The element count and address is modified.
* `new_count`:\\[in\\] New element count of the array. If it is zero and the array is not a view, the effect equals sc_array_reset.
### Prototype
```c
void sc_array_resize (sc_array_t * array, size_t new_count);
```
"""
function sc_array_resize(array, new_count)
    @ccall libsc.sc_array_resize(array::Ptr{sc_array_t}, new_count::Csize_t)::Cvoid
end

"""
    sc_array_copy(dest, src)

Copy the contents of one array into another. Both arrays must have equal element sizes. The source array may be a view. We use memcpy (3): If the two arrays overlap, results are undefined.

### Parameters
* `dest`:\\[in\\] Array (not a view) will be resized and get new data.
* `src`:\\[in\\] Array used as source of new data, will not be changed.
### Prototype
```c
void sc_array_copy (sc_array_t * dest, sc_array_t * src);
```
"""
function sc_array_copy(dest, src)
    @ccall libsc.sc_array_copy(dest::Ptr{sc_array_t}, src::Ptr{sc_array_t})::Cvoid
end

"""
    sc_array_copy_into(dest, dest_offset, src)

Copy the contents of one array into some portion of another. Both arrays must have equal element sizes. Either array may be a view. The destination array must be large enough. We use memcpy (3): If the two arrays overlap, results are undefined.

### Parameters
* `dest`:\\[in\\] Array will be written into. Its element count must be at least **dest_offset** + **src**->elem_count.
* `dest_offset`:\\[in\\] First index in **dest** array to be overwritten. As every index, it refers to elements, not bytes.
* `src`:\\[in\\] Array used as source of new data, will not be changed.
### Prototype
```c
void sc_array_copy_into (sc_array_t * dest, size_t dest_offset, sc_array_t * src);
```
"""
function sc_array_copy_into(dest, dest_offset, src)
    @ccall libsc.sc_array_copy_into(dest::Ptr{sc_array_t}, dest_offset::Csize_t, src::Ptr{sc_array_t})::Cvoid
end

"""
    sc_array_move_part(dest, dest_offset, src, src_offset, count)

Copy part of one array into another using memmove (3). Both arrays must have equal element sizes. Either array may be a view. The destination array must be large enough. We use memmove (3): The two arrays may overlap.

### Parameters
* `dest`:\\[in\\] Array will be written into. Its element count must be at least **dest_offset** + **count**.
* `dest_offset`:\\[in\\] First index in **dest** array to be overwritten. As every index, it refers to elements, not bytes.
* `src`:\\[in\\] Array will be read from. Its element count must be at least **src_offset** + **count**.
* `src_offset`:\\[in\\] First index in **src** array to be used. As every index, it refers to elements, not bytes.
* `count`:\\[in\\] Number of entries copied.
### Prototype
```c
void sc_array_move_part (sc_array_t * dest, size_t dest_offset, sc_array_t * src, size_t src_offset, size_t count);
```
"""
function sc_array_move_part(dest, dest_offset, src, src_offset, count)
    @ccall libsc.sc_array_move_part(dest::Ptr{sc_array_t}, dest_offset::Csize_t, src::Ptr{sc_array_t}, src_offset::Csize_t, count::Csize_t)::Cvoid
end

"""
    sc_array_sort(array, compar)

Sorts the array in ascending order wrt. the comparison function.

### Parameters
* `array`:\\[in\\] The array to sort.
* `compar`:\\[in\\] The comparison function to be used.
### Prototype
```c
void sc_array_sort (sc_array_t * array, int (*compar) (const void *, const void *));
```
"""
function sc_array_sort(array, compar)
    @ccall libsc.sc_array_sort(array::Ptr{sc_array_t}, compar::Ptr{Cvoid})::Cvoid
end

"""
    sc_array_is_sorted(array, compar)

Check whether the array is sorted wrt. the comparison function.

### Parameters
* `array`:\\[in\\] The array to check.
* `compar`:\\[in\\] The comparison function to be used.
### Returns
True if array is sorted, false otherwise.
### Prototype
```c
int sc_array_is_sorted (sc_array_t * array, int (*compar) (const void *, const void *));
```
"""
function sc_array_is_sorted(array, compar)
    @ccall libsc.sc_array_is_sorted(array::Ptr{sc_array_t}, compar::Ptr{Cvoid})::Cint
end

"""
    sc_array_is_equal(array, other)

Check whether two arrays have equal size, count, and content. Either array may be a view. Both arrays will not be changed.

### Parameters
* `array`:\\[in\\] One array to be compared.
* `other`:\\[in\\] A second array to be compared.
### Returns
True if array and other are equal, false otherwise.
### Prototype
```c
int sc_array_is_equal (sc_array_t * array, sc_array_t * other);
```
"""
function sc_array_is_equal(array, other)
    @ccall libsc.sc_array_is_equal(array::Ptr{sc_array_t}, other::Ptr{sc_array_t})::Cint
end

"""
    sc_array_uniq(array, compar)

Removed duplicate entries from a sorted array. This function is not allowed for views.

### Parameters
* `array`:\\[in,out\\] The array size will be reduced as necessary.
* `compar`:\\[in\\] The comparison function to be used.
### Prototype
```c
void sc_array_uniq (sc_array_t * array, int (*compar) (const void *, const void *));
```
"""
function sc_array_uniq(array, compar)
    @ccall libsc.sc_array_uniq(array::Ptr{sc_array_t}, compar::Ptr{Cvoid})::Cvoid
end

"""
    sc_array_bsearch(array, key, compar)

Performs a binary search on an array. The array must be sorted.

### Parameters
* `array`:\\[in\\] A sorted array to search in.
* `key`:\\[in\\] An element to be searched for.
* `compar`:\\[in\\] The comparison function to be used.
### Returns
Returns the index into array for the item found, or -1.
### Prototype
```c
ssize_t sc_array_bsearch (sc_array_t * array, const void *key, int (*compar) (const void *, const void *));
```
"""
function sc_array_bsearch(array, key, compar)
    @ccall libsc.sc_array_bsearch(array::Ptr{sc_array_t}, key::Ptr{Cvoid}, compar::Ptr{Cvoid})::Cssize_t
end

# typedef size_t ( * sc_array_type_t ) ( sc_array_t * array , size_t index , void * data )
"""
Function to determine the enumerable type of an object in an array.

### Parameters
* `array`:\\[in\\] Array containing the object.
* `index`:\\[in\\] The location of the object.
* `data`:\\[in\\] Arbitrary user data.
"""
const sc_array_type_t = Ptr{Cvoid}

"""
    sc_array_split(array, offsets, num_types, type_fn, data)

Compute the offsets of groups of enumerable types in an array.

### Parameters
* `array`:\\[in\\] Array that is sorted in ascending order by type. If k indexes *array*, then 0 <= *type_fn* (*array*, k, *data*) < *num_types*.
* `offsets`:\\[in,out\\] An initialized array of type size\\_t that is resized to *num_types* + 1 entries. The indices j of *array* that contain objects of type k are *offsets*[k] <= j < *offsets*[k + 1]. If there are no objects of type k, then *offsets*[k] = *offset*[k + 1].
* `num_types`:\\[in\\] The number of possible types of objects in *array*.
* `type_fn`:\\[in\\] Returns the type of an object in the array.
* `data`:\\[in\\] Arbitrary user data passed to *type_fn*.
### Prototype
```c
void sc_array_split (sc_array_t * array, sc_array_t * offsets, size_t num_types, sc_array_type_t type_fn, void *data);
```
"""
function sc_array_split(array, offsets, num_types, type_fn, data)
    @ccall libsc.sc_array_split(array::Ptr{sc_array_t}, offsets::Ptr{sc_array_t}, num_types::Csize_t, type_fn::sc_array_type_t, data::Ptr{Cvoid})::Cvoid
end

"""
    sc_array_is_permutation(array)

Determine whether *array* is an array of size\\_t's whose entries include every integer 0 <= i < array->elem\\_count.

### Parameters
* `array`:\\[in\\] An array.
### Returns
Returns 1 if array contains size\\_t elements whose entries include every integer 0 <= i < *array*->elem_count, 0 otherwise.
### Prototype
```c
int sc_array_is_permutation (sc_array_t * array);
```
"""
function sc_array_is_permutation(array)
    @ccall libsc.sc_array_is_permutation(array::Ptr{sc_array_t})::Cint
end

"""
    sc_array_permute(array, newindices, keepperm)

Given permutation *newindices*, permute *array* in place. The data that on input is contained in *array*[i] will be contained in *array*[newindices[i]] on output. The entries of newindices will be altered unless *keepperm* is true.

### Parameters
* `array`:\\[in,out\\] An array.
* `newindices`:\\[in,out\\] Permutation array (see [`sc_array_is_permutation`](@ref)).
* `keepperm`:\\[in\\] If true, *newindices* will be unchanged by the algorithm; if false, *newindices* will be the identity permutation on output, but the algorithm will only use O(1) space.
### Prototype
```c
void sc_array_permute (sc_array_t * array, sc_array_t * newindices, int keepperm);
```
"""
function sc_array_permute(array, newindices, keepperm)
    @ccall libsc.sc_array_permute(array::Ptr{sc_array_t}, newindices::Ptr{sc_array_t}, keepperm::Cint)::Cvoid
end

"""
    sc_array_checksum(array)

Computes the adler32 checksum of array data (see zlib documentation). This is a faster checksum than crc32, and it works with zeros as data.

### Prototype
```c
unsigned int sc_array_checksum (sc_array_t * array);
```
"""
function sc_array_checksum(array)
    @ccall libsc.sc_array_checksum(array::Ptr{sc_array_t})::Cuint
end

"""
    sc_array_pqueue_add(array, temp, compar)

Adds an element to a priority queue. PQUEUE FUNCTIONS ARE UNTESTED AND CURRENTLY DISABLED. This function is not allowed for views. The priority queue is implemented as a heap in ascending order. A heap is a binary tree where the children are not less than their parent. Assumes that elements [0]..[elem\\_count-2] form a valid heap. Then propagates [elem\\_count-1] upward by swapping if necessary.

!!! note

    If the return value is zero for all elements in an array, the array is sorted linearly and unchanged.

### Parameters
* `temp`:\\[in\\] Pointer to unused allocated memory of elem\\_size.
* `compar`:\\[in\\] The comparison function to be used.
### Returns
Returns the number of swap operations.
### Prototype
```c
size_t sc_array_pqueue_add (sc_array_t * array, void *temp, int (*compar) (const void *, const void *));
```
"""
function sc_array_pqueue_add(array, temp, compar)
    @ccall libsc.sc_array_pqueue_add(array::Ptr{sc_array_t}, temp::Ptr{Cvoid}, compar::Ptr{Cvoid})::Csize_t
end

"""
    sc_array_pqueue_pop(array, result, compar)

Pops the smallest element from a priority queue. PQUEUE FUNCTIONS ARE UNTESTED AND CURRENTLY DISABLED. This function is not allowed for views. This function assumes that the array forms a valid heap in ascending order.

!!! note

    This function resizes the array to elem\\_count-1.

### Parameters
* `result`:\\[out\\] Pointer to unused allocated memory of elem\\_size.
* `compar`:\\[in\\] The comparison function to be used.
### Returns
Returns the number of swap operations.
### Prototype
```c
size_t sc_array_pqueue_pop (sc_array_t * array, void *result, int (*compar) (const void *, const void *));
```
"""
function sc_array_pqueue_pop(array, result, compar)
    @ccall libsc.sc_array_pqueue_pop(array::Ptr{sc_array_t}, result::Ptr{Cvoid}, compar::Ptr{Cvoid})::Csize_t
end

"""
    sc_array_index(array, iz)

### Prototype
```c
static inline void * sc_array_index (sc_array_t * array, size_t iz);
```
"""
function sc_array_index(array, iz)
    @ccall libsc.sc_array_index(array::Ptr{sc_array_t}, iz::Csize_t)::Ptr{Cvoid}
end

"""
    sc_array_index_null(array, iz)

### Prototype
```c
static inline void * sc_array_index_null (sc_array_t * array, size_t iz);
```
"""
function sc_array_index_null(array, iz)
    @ccall libsc.sc_array_index_null(array::Ptr{sc_array_t}, iz::Csize_t)::Ptr{Cvoid}
end

"""
    sc_array_index_int(array, i)

### Prototype
```c
static inline void * sc_array_index_int (sc_array_t * array, int i);
```
"""
function sc_array_index_int(array, i)
    @ccall libsc.sc_array_index_int(array::Ptr{sc_array_t}, i::Cint)::Ptr{Cvoid}
end

"""
    sc_array_index_long(array, l)

### Prototype
```c
static inline void * sc_array_index_long (sc_array_t * array, long l);
```
"""
function sc_array_index_long(array, l)
    @ccall libsc.sc_array_index_long(array::Ptr{sc_array_t}, l::Clong)::Ptr{Cvoid}
end

"""
    sc_array_index_ssize_t(array, is)

### Prototype
```c
static inline void * sc_array_index_ssize_t (sc_array_t * array, ssize_t is);
```
"""
function sc_array_index_ssize_t(array, is)
    @ccall libsc.sc_array_index_ssize_t(array::Ptr{sc_array_t}, is::Cssize_t)::Ptr{Cvoid}
end

"""
    sc_array_index_int16(array, i16)

### Prototype
```c
static inline void * sc_array_index_int16 (sc_array_t * array, int16_t i16);
```
"""
function sc_array_index_int16(array, i16)
    @ccall libsc.sc_array_index_int16(array::Ptr{sc_array_t}, i16::Int16)::Ptr{Cvoid}
end

"""
    sc_array_position(array, element)

### Prototype
```c
static inline size_t sc_array_position (sc_array_t * array, void *element);
```
"""
function sc_array_position(array, element)
    @ccall libsc.sc_array_position(array::Ptr{sc_array_t}, element::Ptr{Cvoid})::Csize_t
end

"""
    sc_array_pop(array)

### Prototype
```c
static inline void * sc_array_pop (sc_array_t * array);
```
"""
function sc_array_pop(array)
    @ccall libsc.sc_array_pop(array::Ptr{sc_array_t})::Ptr{Cvoid}
end

"""
    sc_array_push_count(array, add_count)

### Prototype
```c
static inline void * sc_array_push_count (sc_array_t * array, size_t add_count);
```
"""
function sc_array_push_count(array, add_count)
    @ccall libsc.sc_array_push_count(array::Ptr{sc_array_t}, add_count::Csize_t)::Ptr{Cvoid}
end

"""
    sc_array_push(array)

### Prototype
```c
static inline void * sc_array_push (sc_array_t * array);
```
"""
function sc_array_push(array)
    @ccall libsc.sc_array_push(array::Ptr{sc_array_t})::Ptr{Cvoid}
end

"""
    sc_mstamp

A data container to create memory items of the same size. Allocations are bundled so it's fast for small memory sizes. The items created will remain valid until the container is destroyed. There is no option to return an item to the container. See sc_mempool_t for that purpose.

| Field        | Note                            |
| :----------- | :------------------------------ |
| elem\\_size  | Input parameter: size per item  |
| per\\_stamp  | Number of items per stamp       |
| stamp\\_size | Bytes allocated in a stamp      |
| cur\\_snext  | Next number within a stamp      |
| current      | Memory of current stamp         |
| remember     | Collects all stamps             |
"""
struct sc_mstamp
    elem_size::Csize_t
    per_stamp::Csize_t
    stamp_size::Csize_t
    cur_snext::Csize_t
    current::Cstring
    remember::sc_array_t
end

"""A data container to create memory items of the same size. Allocations are bundled so it's fast for small memory sizes. The items created will remain valid until the container is destroyed. There is no option to return an item to the container. See sc_mempool_t for that purpose."""
const sc_mstamp_t = sc_mstamp

"""
    sc_mstamp_init(mst, stamp_unit, elem_size)

Initialize a memory stamp container. We provide allocation of fixed-size memory items without allocating new memory in every request. Instead we block the allocations in what we call a stamp of multiple items. Even if no allocations are done, the container's internal memory must be freed eventually by sc_mstamp_reset.

### Parameters
* `mst`:\\[in,out\\] Legal pointer to a stamp structure.
* `stamp_unit`:\\[in\\] Size of each memory block that we allocate. If it is larger than the element size, we may place more than one element in it. Passing 0 is legal and forces stamps that hold one item each.
* `elem_size`:\\[in\\] Size of each item. Passing 0 is legal. In that case, sc_mstamp_alloc returns NULL.
### Prototype
```c
void sc_mstamp_init (sc_mstamp_t * mst, size_t stamp_unit, size_t elem_size);
```
"""
function sc_mstamp_init(mst, stamp_unit, elem_size)
    @ccall libsc.sc_mstamp_init(mst::Ptr{sc_mstamp_t}, stamp_unit::Csize_t, elem_size::Csize_t)::Cvoid
end

"""
    sc_mstamp_reset(mst)

Free all memory in a stamp structure and all items previously returned.

### Parameters
* `mst`:\\[in,out\\] Properly initialized stamp container. On output, the structure is undefined.
### Prototype
```c
void sc_mstamp_reset (sc_mstamp_t * mst);
```
"""
function sc_mstamp_reset(mst)
    @ccall libsc.sc_mstamp_reset(mst::Ptr{sc_mstamp_t})::Cvoid
end

"""
    sc_mstamp_truncate(mst)

Free all memory in a stamp structure and initialize it anew. Equivalent to calling sc_mstamp_reset followed by sc_mstamp_init with the same stamp\\_unit and elem\\_size.

### Parameters
* `mst`:\\[in,out\\] Properly initialized stamp container. On output, its elements have been freed and it is ready for further use.
### Prototype
```c
void sc_mstamp_truncate (sc_mstamp_t * mst);
```
"""
function sc_mstamp_truncate(mst)
    @ccall libsc.sc_mstamp_truncate(mst::Ptr{sc_mstamp_t})::Cvoid
end

"""
    sc_mstamp_alloc(mst)

Return a new item. The memory returned will stay legal until container is destroyed or truncated.

### Parameters
* `mst`:\\[in,out\\] Properly initialized stamp container.
### Returns
Pointer to an item ready to use. Legal until sc_mstamp_reset or sc_mstamp_truncate is called on mst.
### Prototype
```c
void *sc_mstamp_alloc (sc_mstamp_t * mst);
```
"""
function sc_mstamp_alloc(mst)
    @ccall libsc.sc_mstamp_alloc(mst::Ptr{sc_mstamp_t})::Ptr{Cvoid}
end

"""
    sc_mstamp_memory_used(mst)

Return memory size in bytes of all data allocated in the container.

### Parameters
* `mst`:\\[in\\] Properly initialized stamp container.
### Returns
Total container memory size in bytes.
### Prototype
```c
size_t sc_mstamp_memory_used (sc_mstamp_t * mst);
```
"""
function sc_mstamp_memory_used(mst)
    @ccall libsc.sc_mstamp_memory_used(mst::Ptr{sc_mstamp_t})::Csize_t
end

"""
    sc_mempool

The [`sc_mempool`](@ref) object provides a large pool of equal-size elements. The pool grows dynamically for element allocation. Elements are referenced by their address which never changes. Elements can be freed (that is, returned to the pool) and are transparently reused. If the zero\\_and\\_persist option is selected, new elements are initialized to all zeros on creation, and the contents of an element are not touched between freeing and re-returning it.

| Field                | Note                             |
| :------------------- | :------------------------------- |
| elem\\_size          | size of a single element         |
| elem\\_count         | number of valid elements         |
| zero\\_and\\_persist | Boolean; is set in constructor.  |
| mstamp               | fixed-size chunk allocator       |
| freed                | buffers the freed elements       |
"""
struct sc_mempool
    elem_size::Csize_t
    elem_count::Csize_t
    zero_and_persist::Cint
    mstamp::sc_mstamp_t
    freed::sc_array_t
end

"""The [`sc_mempool`](@ref) object provides a large pool of equal-size elements. The pool grows dynamically for element allocation. Elements are referenced by their address which never changes. Elements can be freed (that is, returned to the pool) and are transparently reused. If the zero\\_and\\_persist option is selected, new elements are initialized to all zeros on creation, and the contents of an element are not touched between freeing and re-returning it."""
const sc_mempool_t = sc_mempool

"""
    sc_mempool_memory_used(mempool)

Calculate the memory used by a memory pool.

### Parameters
* `mempool`:\\[in\\] The memory pool.
### Returns
Memory used in bytes.
### Prototype
```c
size_t sc_mempool_memory_used (sc_mempool_t * mempool);
```
"""
function sc_mempool_memory_used(mempool)
    @ccall libsc.sc_mempool_memory_used(mempool::Ptr{sc_mempool_t})::Csize_t
end

"""
    sc_mempool_new(elem_size)

Creates a new mempool structure with the zero\\_and\\_persist option off. The contents of any elements returned by [`sc_mempool_alloc`](@ref) are undefined.

### Parameters
* `elem_size`:\\[in\\] Size of one element in bytes.
### Returns
Returns an allocated and initialized memory pool.
### Prototype
```c
sc_mempool_t *sc_mempool_new (size_t elem_size);
```
"""
function sc_mempool_new(elem_size)
    @ccall libsc.sc_mempool_new(elem_size::Csize_t)::Ptr{sc_mempool_t}
end

"""
    sc_mempool_new_zero_and_persist(elem_size)

Creates a new mempool structure with the zero\\_and\\_persist option on. The memory of newly created elements is zero'd out, and the contents of an element are not touched between freeing and re-returning it.

### Parameters
* `elem_size`:\\[in\\] Size of one element in bytes.
### Returns
Returns an allocated and initialized memory pool.
### Prototype
```c
sc_mempool_t *sc_mempool_new_zero_and_persist (size_t elem_size);
```
"""
function sc_mempool_new_zero_and_persist(elem_size)
    @ccall libsc.sc_mempool_new_zero_and_persist(elem_size::Csize_t)::Ptr{sc_mempool_t}
end

"""
    sc_mempool_init(mempool, elem_size)

Same as [`sc_mempool_new`](@ref), but for an already allocated [`sc_mempool_t`](@ref) pointer.

### Prototype
```c
void sc_mempool_init (sc_mempool_t * mempool, size_t elem_size);
```
"""
function sc_mempool_init(mempool, elem_size)
    @ccall libsc.sc_mempool_init(mempool::Ptr{sc_mempool_t}, elem_size::Csize_t)::Cvoid
end

"""
    sc_mempool_destroy(mempool)

Destroy a mempool structure. All elements that are still in use are invalidated.

### Parameters
* `mempool`:\\[in,out\\] Its memory is freed.
### Prototype
```c
void sc_mempool_destroy (sc_mempool_t * mempool);
```
"""
function sc_mempool_destroy(mempool)
    @ccall libsc.sc_mempool_destroy(mempool::Ptr{sc_mempool_t})::Cvoid
end

"""
    sc_mempool_destroy_null(pmempool)

Destroy a mempool structure. All elements that are still in use are invalidated.

### Parameters
* `pmempool`:\\[in,out\\] Address of pointer to memory pool. Its memory is freed, pointer is NULLed.
### Prototype
```c
void sc_mempool_destroy_null (sc_mempool_t ** pmempool);
```
"""
function sc_mempool_destroy_null(pmempool)
    @ccall libsc.sc_mempool_destroy_null(pmempool::Ptr{Ptr{sc_mempool_t}})::Cvoid
end

"""
    sc_mempool_reset(mempool)

Same as [`sc_mempool_destroy`](@ref), but does not free the pointer

### Prototype
```c
void sc_mempool_reset (sc_mempool_t * mempool);
```
"""
function sc_mempool_reset(mempool)
    @ccall libsc.sc_mempool_reset(mempool::Ptr{sc_mempool_t})::Cvoid
end

"""
    sc_mempool_truncate(mempool)

Invalidates all previously returned pointers, resets count to 0.

### Prototype
```c
void sc_mempool_truncate (sc_mempool_t * mempool);
```
"""
function sc_mempool_truncate(mempool)
    @ccall libsc.sc_mempool_truncate(mempool::Ptr{sc_mempool_t})::Cvoid
end

"""
    sc_mempool_alloc(mempool)

### Prototype
```c
static inline void * sc_mempool_alloc (sc_mempool_t * mempool);
```
"""
function sc_mempool_alloc(mempool)
    @ccall libsc.sc_mempool_alloc(mempool::Ptr{sc_mempool_t})::Ptr{Cvoid}
end

"""
    sc_mempool_free(mempool, elem)

### Prototype
```c
static inline void sc_mempool_free (sc_mempool_t * mempool, void *elem);
```
"""
function sc_mempool_free(mempool, elem)
    @ccall libsc.sc_mempool_free(mempool::Ptr{sc_mempool_t}, elem::Ptr{Cvoid})::Cvoid
end

"""
    sc_link

The [`sc_link`](@ref) structure is one link of a linked list.
"""
struct sc_link
    data::Ptr{Cvoid}
    next::Ptr{sc_link}
end

"""The [`sc_link`](@ref) structure is one link of a linked list."""
const sc_link_t = sc_link

"""
    sc_list

The [`sc_list`](@ref) object provides a linked list.
"""
struct sc_list
    elem_count::Csize_t
    first::Ptr{sc_link_t}
    last::Ptr{sc_link_t}
    allocator_owned::Cint
    allocator::Ptr{sc_mempool_t}
end

"""The [`sc_list`](@ref) object provides a linked list."""
const sc_list_t = sc_list

"""
    sc_list_memory_used(list, is_dynamic)

Calculate the total memory used by a list.

### Parameters
* `list`:\\[in\\] The list.
* `is_dynamic`:\\[in\\] True if created with [`sc_list_new`](@ref), false if initialized with [`sc_list_init`](@ref)
### Returns
Memory used in bytes.
### Prototype
```c
size_t sc_list_memory_used (sc_list_t * list, int is_dynamic);
```
"""
function sc_list_memory_used(list, is_dynamic)
    @ccall libsc.sc_list_memory_used(list::Ptr{sc_list_t}, is_dynamic::Cint)::Csize_t
end

"""
    sc_list_new(allocator)

Allocate a new, empty linked list.

### Parameters
* `allocator`:\\[in\\] Memory allocator for [`sc_link_t`](@ref), can be NULL in which case an internal allocator is created.
### Returns
Pointer to a newly allocated, empty list object.
### Prototype
```c
sc_list_t *sc_list_new (sc_mempool_t * allocator);
```
"""
function sc_list_new(allocator)
    @ccall libsc.sc_list_new(allocator::Ptr{sc_mempool_t})::Ptr{sc_list_t}
end

"""
    sc_list_destroy(list)

Destroy a linked list structure in O(N).

!!! note

    If allocator was provided in [`sc_list_new`](@ref), it will not be destroyed.

### Parameters
* `list`:\\[in,out\\] All memory allocated for this list is freed.
### Prototype
```c
void sc_list_destroy (sc_list_t * list);
```
"""
function sc_list_destroy(list)
    @ccall libsc.sc_list_destroy(list::Ptr{sc_list_t})::Cvoid
end

"""
    sc_list_init(list, allocator)

Initialize a list object with an external link allocator.

### Parameters
* `list`:\\[in,out\\] List structure to be initialized.
* `allocator`:\\[in\\] External memory allocator for [`sc_link_t`](@ref), which must exist already.
### Prototype
```c
void sc_list_init (sc_list_t * list, sc_mempool_t * allocator);
```
"""
function sc_list_init(list, allocator)
    @ccall libsc.sc_list_init(list::Ptr{sc_list_t}, allocator::Ptr{sc_mempool_t})::Cvoid
end

"""
    sc_list_reset(list)

Remove all elements from a list in O(N).

!!! note

    Calling [`sc_list_init`](@ref), then any list operations, then [`sc_list_reset`](@ref) is memory neutral.

### Parameters
* `list`:\\[in,out\\] List structure to be emptied.
### Prototype
```c
void sc_list_reset (sc_list_t * list);
```
"""
function sc_list_reset(list)
    @ccall libsc.sc_list_reset(list::Ptr{sc_list_t})::Cvoid
end

"""
    sc_list_unlink(list)

Unlink all list elements without returning them to the mempool. This runs in O(1) but is dangerous because the link memory stays alive.

### Parameters
* `list`:\\[in,out\\] List structure to be unlinked.
### Prototype
```c
void sc_list_unlink (sc_list_t * list);
```
"""
function sc_list_unlink(list)
    @ccall libsc.sc_list_unlink(list::Ptr{sc_list_t})::Cvoid
end

"""
    sc_list_prepend(list, data)

Insert a list element at the beginning of the list.

### Parameters
* `list`:\\[in,out\\] Valid list object.
* `data`:\\[in\\] A new link is created holding this data.
### Returns
The link that has been created for data.
### Prototype
```c
sc_link_t *sc_list_prepend (sc_list_t * list, void *data);
```
"""
function sc_list_prepend(list, data)
    @ccall libsc.sc_list_prepend(list::Ptr{sc_list_t}, data::Ptr{Cvoid})::Ptr{sc_link_t}
end

"""
    sc_list_append(list, data)

Insert a list element at the end of the list.

### Parameters
* `list`:\\[in,out\\] Valid list object.
* `data`:\\[in\\] A new link is created holding this data.
### Returns
The link that has been created for data.
### Prototype
```c
sc_link_t *sc_list_append (sc_list_t * list, void *data);
```
"""
function sc_list_append(list, data)
    @ccall libsc.sc_list_append(list::Ptr{sc_list_t}, data::Ptr{Cvoid})::Ptr{sc_link_t}
end

"""
    sc_list_insert(list, pred, data)

Insert an element after a given list position.

### Parameters
* `list`:\\[in,out\\] Valid list object.
* `pred`:\\[in,out\\] The predecessor of the element to be inserted.
* `data`:\\[in\\] A new link is created holding this data.
### Returns
The link that has been created for data.
### Prototype
```c
sc_link_t *sc_list_insert (sc_list_t * list, sc_link_t * pred, void *data);
```
"""
function sc_list_insert(list, pred, data)
    @ccall libsc.sc_list_insert(list::Ptr{sc_list_t}, pred::Ptr{sc_link_t}, data::Ptr{Cvoid})::Ptr{sc_link_t}
end

"""
    sc_list_remove(list, pred)

Remove an element after a given list position.

### Parameters
* `list`:\\[in,out\\] Valid, non-empty list object.
* `pred`:\\[in\\] The predecessor of the element to be removed. If *pred* == NULL, the first element is removed, which is equivalent to calling [`sc_list_pop`](@ref) (list).
### Returns
The data of the removed and freed link.
### Prototype
```c
void *sc_list_remove (sc_list_t * list, sc_link_t * pred);
```
"""
function sc_list_remove(list, pred)
    @ccall libsc.sc_list_remove(list::Ptr{sc_list_t}, pred::Ptr{sc_link_t})::Ptr{Cvoid}
end

"""
    sc_list_pop(list)

Remove an element from the front of the list.

### Parameters
* `list`:\\[in,out\\] Valid, non-empty list object.
### Returns
Returns the data of the removed first list element.
### Prototype
```c
void *sc_list_pop (sc_list_t * list);
```
"""
function sc_list_pop(list)
    @ccall libsc.sc_list_pop(list::Ptr{sc_list_t})::Ptr{Cvoid}
end

"""
    sc_hash

The [`sc_hash`](@ref) implements a hash table. It uses an array which has linked lists as elements.

| Field        | Note                                   |
| :----------- | :------------------------------------- |
| elem\\_count | total number of objects contained      |
| slots        | the slot count is slots->elem\\_count  |
| user\\_data  | user data passed to hash function      |
| allocator    | must allocate [`sc_link_t`](@ref)      |
"""
struct sc_hash
    elem_count::Csize_t
    slots::Ptr{sc_array_t}
    user_data::Ptr{Cvoid}
    hash_fn::sc_hash_function_t
    equal_fn::sc_equal_function_t
    resize_checks::Csize_t
    resize_actions::Csize_t
    allocator_owned::Cint
    allocator::Ptr{sc_mempool_t}
end

"""The [`sc_hash`](@ref) implements a hash table. It uses an array which has linked lists as elements."""
const sc_hash_t = sc_hash

"""
    sc_hash_function_string(s, u)

Compute a hash value from a null-terminated string. This hash function is NOT cryptographically safe! Use libcrypt then.

### Parameters
* `s`:\\[in\\] Null-terminated string to be hashed.
* `u`:\\[in\\] Not used.
### Returns
The computed hash value as an unsigned integer.
### Prototype
```c
unsigned int sc_hash_function_string (const void *s, const void *u);
```
"""
function sc_hash_function_string(s, u)
    @ccall libsc.sc_hash_function_string(s::Ptr{Cvoid}, u::Ptr{Cvoid})::Cuint
end

"""
    sc_hash_memory_used(hash)

Calculate the memory used by a hash table.

### Parameters
* `hash`:\\[in\\] The hash table.
### Returns
Memory used in bytes.
### Prototype
```c
size_t sc_hash_memory_used (sc_hash_t * hash);
```
"""
function sc_hash_memory_used(hash)
    @ccall libsc.sc_hash_memory_used(hash::Ptr{sc_hash_t})::Csize_t
end

"""
    sc_hash_new(hash_fn, equal_fn, user_data, allocator)

Create a new hash table. The number of hash slots is chosen dynamically.

### Parameters
* `hash_fn`:\\[in\\] Function to compute the hash value.
* `equal_fn`:\\[in\\] Function to test two objects for equality.
* `user_data`:\\[in\\] User data passed through to the hash function.
* `allocator`:\\[in\\] Memory allocator for [`sc_link_t`](@ref), can be NULL.
### Prototype
```c
sc_hash_t *sc_hash_new (sc_hash_function_t hash_fn, sc_equal_function_t equal_fn, void *user_data, sc_mempool_t * allocator);
```
"""
function sc_hash_new(hash_fn, equal_fn, user_data, allocator)
    @ccall libsc.sc_hash_new(hash_fn::sc_hash_function_t, equal_fn::sc_equal_function_t, user_data::Ptr{Cvoid}, allocator::Ptr{sc_mempool_t})::Ptr{sc_hash_t}
end

"""
    sc_hash_destroy(hash)

Destroy a hash table.

If the allocator is owned, this runs in O(1), otherwise in O(N).

!!! note

    If allocator was provided in [`sc_hash_new`](@ref), it will not be destroyed.

### Prototype
```c
void sc_hash_destroy (sc_hash_t * hash);
```
"""
function sc_hash_destroy(hash)
    @ccall libsc.sc_hash_destroy(hash::Ptr{sc_hash_t})::Cvoid
end

"""
    sc_hash_destroy_null(phash)

Destroy a hash table and set its pointer to NULL. Destruction is done using sc_hash_destroy.

### Parameters
* `phash`:\\[in,out\\] Address of pointer to hash table. On output, pointer is NULLed.
### Prototype
```c
void sc_hash_destroy_null (sc_hash_t ** phash);
```
"""
function sc_hash_destroy_null(phash)
    @ccall libsc.sc_hash_destroy_null(phash::Ptr{Ptr{sc_hash_t}})::Cvoid
end

"""
    sc_hash_truncate(hash)

Remove all entries from a hash table in O(N).

If the allocator is owned, it calls [`sc_hash_unlink`](@ref) and [`sc_mempool_truncate`](@ref). Otherwise, it calls [`sc_list_reset`](@ref) on every hash slot which is slower.

### Prototype
```c
void sc_hash_truncate (sc_hash_t * hash);
```
"""
function sc_hash_truncate(hash)
    @ccall libsc.sc_hash_truncate(hash::Ptr{sc_hash_t})::Cvoid
end

"""
    sc_hash_unlink(hash)

Unlink all hash elements without returning them to the mempool.

If the allocator is not owned, this runs faster than [`sc_hash_truncate`](@ref), but is dangerous because of potential memory leaks.

### Parameters
* `hash`:\\[in,out\\] Hash structure to be unlinked.
### Prototype
```c
void sc_hash_unlink (sc_hash_t * hash);
```
"""
function sc_hash_unlink(hash)
    @ccall libsc.sc_hash_unlink(hash::Ptr{sc_hash_t})::Cvoid
end

"""
    sc_hash_unlink_destroy(hash)

Same effect as unlink and destroy, but in O(1). This is dangerous because of potential memory leaks.

### Parameters
* `hash`:\\[in\\] Hash structure to be unlinked and destroyed.
### Prototype
```c
void sc_hash_unlink_destroy (sc_hash_t * hash);
```
"""
function sc_hash_unlink_destroy(hash)
    @ccall libsc.sc_hash_unlink_destroy(hash::Ptr{sc_hash_t})::Cvoid
end

"""
    sc_hash_lookup(hash, v, found)

Check if an object is contained in the hash table.

### Parameters
* `v`:\\[in\\] The object to be looked up.
* `found`:\\[out\\] If found != NULL, *found is set to the address of the pointer to the already contained object if the object is found. You can assign to **found to override.
### Returns
Returns true if object is found, false otherwise.
### Prototype
```c
int sc_hash_lookup (sc_hash_t * hash, void *v, void ***found);
```
"""
function sc_hash_lookup(hash, v, found)
    @ccall libsc.sc_hash_lookup(hash::Ptr{sc_hash_t}, v::Ptr{Cvoid}, found::Ptr{Ptr{Ptr{Cvoid}}})::Cint
end

"""
    sc_hash_insert_unique(hash, v, found)

Insert an object into a hash table if it is not contained already.

### Parameters
* `v`:\\[in\\] The object to be inserted.
* `found`:\\[out\\] If found != NULL, *found is set to the address of the pointer to the already contained, or if not present, the new object. You can assign to **found to override.
### Returns
Returns true if object is added, false if it is already contained.
### Prototype
```c
int sc_hash_insert_unique (sc_hash_t * hash, void *v, void ***found);
```
"""
function sc_hash_insert_unique(hash, v, found)
    @ccall libsc.sc_hash_insert_unique(hash::Ptr{sc_hash_t}, v::Ptr{Cvoid}, found::Ptr{Ptr{Ptr{Cvoid}}})::Cint
end

"""
    sc_hash_remove(hash, v, found)

Remove an object from a hash table.

### Parameters
* `v`:\\[in\\] The object to be removed.
* `found`:\\[out\\] If found != NULL, *found is set to the object that is removed if that exists.
### Returns
Returns true if object is found, false if is not contained.
### Prototype
```c
int sc_hash_remove (sc_hash_t * hash, void *v, void **found);
```
"""
function sc_hash_remove(hash, v, found)
    @ccall libsc.sc_hash_remove(hash::Ptr{sc_hash_t}, v::Ptr{Cvoid}, found::Ptr{Ptr{Cvoid}})::Cint
end

"""
    sc_hash_foreach(hash, fn)

Invoke a callback for every member of the hash table. The functions hash\\_fn and equal\\_fn are not called by this function.

### Prototype
```c
void sc_hash_foreach (sc_hash_t * hash, sc_hash_foreach_t fn);
```
"""
function sc_hash_foreach(hash, fn)
    @ccall libsc.sc_hash_foreach(hash::Ptr{sc_hash_t}, fn::sc_hash_foreach_t)::Cvoid
end

"""
    sc_hash_print_statistics(package_id, log_priority, hash)

Compute and print statistical information about the occupancy.

### Prototype
```c
void sc_hash_print_statistics (int package_id, int log_priority, sc_hash_t * hash);
```
"""
function sc_hash_print_statistics(package_id, log_priority, hash)
    @ccall libsc.sc_hash_print_statistics(package_id::Cint, log_priority::Cint, hash::Ptr{sc_hash_t})::Cvoid
end

struct sc_hash_array_data
    pa::Ptr{sc_array_t}
    hash_fn::sc_hash_function_t
    equal_fn::sc_equal_function_t
    user_data::Ptr{Cvoid}
    current_item::Ptr{Cvoid}
end

const sc_hash_array_data_t = sc_hash_array_data

"""
    sc_hash_array

The [`sc_hash_array`](@ref) implements an array backed up by a hash table. This enables O(1) access for array elements.
"""
struct sc_hash_array
    a::sc_array_t
    internal_data::sc_hash_array_data_t
    h::Ptr{sc_hash_t}
end

"""The [`sc_hash_array`](@ref) implements an array backed up by a hash table. This enables O(1) access for array elements."""
const sc_hash_array_t = sc_hash_array

"""
    sc_hash_array_memory_used(ha)

Calculate the memory used by a hash array.

### Parameters
* `ha`:\\[in\\] The hash array.
### Returns
Memory used in bytes.
### Prototype
```c
size_t sc_hash_array_memory_used (sc_hash_array_t * ha);
```
"""
function sc_hash_array_memory_used(ha)
    @ccall libsc.sc_hash_array_memory_used(ha::Ptr{sc_hash_array_t})::Csize_t
end

"""
    sc_hash_array_new(elem_size, hash_fn, equal_fn, user_data)

Create a new hash array.

### Parameters
* `elem_size`:\\[in\\] Size of one array element in bytes.
* `hash_fn`:\\[in\\] Function to compute the hash value.
* `equal_fn`:\\[in\\] Function to test two objects for equality.
### Prototype
```c
sc_hash_array_t *sc_hash_array_new (size_t elem_size, sc_hash_function_t hash_fn, sc_equal_function_t equal_fn, void *user_data);
```
"""
function sc_hash_array_new(elem_size, hash_fn, equal_fn, user_data)
    @ccall libsc.sc_hash_array_new(elem_size::Csize_t, hash_fn::sc_hash_function_t, equal_fn::sc_equal_function_t, user_data::Ptr{Cvoid})::Ptr{sc_hash_array_t}
end

"""
    sc_hash_array_destroy(hash_array)

Destroy a hash array.

### Prototype
```c
void sc_hash_array_destroy (sc_hash_array_t * hash_array);
```
"""
function sc_hash_array_destroy(hash_array)
    @ccall libsc.sc_hash_array_destroy(hash_array::Ptr{sc_hash_array_t})::Cvoid
end

"""
    sc_hash_array_is_valid(hash_array)

Check the internal consistency of a hash array.

### Prototype
```c
int sc_hash_array_is_valid (sc_hash_array_t * hash_array);
```
"""
function sc_hash_array_is_valid(hash_array)
    @ccall libsc.sc_hash_array_is_valid(hash_array::Ptr{sc_hash_array_t})::Cint
end

"""
    sc_hash_array_truncate(hash_array)

Remove all elements from the hash array.

### Parameters
* `hash_array`:\\[in,out\\] Hash array to truncate.
### Prototype
```c
void sc_hash_array_truncate (sc_hash_array_t * hash_array);
```
"""
function sc_hash_array_truncate(hash_array)
    @ccall libsc.sc_hash_array_truncate(hash_array::Ptr{sc_hash_array_t})::Cvoid
end

"""
    sc_hash_array_lookup(hash_array, v, position)

Check if an object is contained in a hash array.

### Parameters
* `v`:\\[in\\] A pointer to the object.
* `position`:\\[out\\] If position != NULL, *position is set to the array position of the already contained object if found.
### Returns
Returns true if object is found, false otherwise.
### Prototype
```c
int sc_hash_array_lookup (sc_hash_array_t * hash_array, void *v, size_t *position);
```
"""
function sc_hash_array_lookup(hash_array, v, position)
    @ccall libsc.sc_hash_array_lookup(hash_array::Ptr{sc_hash_array_t}, v::Ptr{Cvoid}, position::Ptr{Csize_t})::Cint
end

"""
    sc_hash_array_insert_unique(hash_array, v, position)

Insert an object into a hash array if it is not contained already. The object is not copied into the array. Use the return value for that. New objects are guaranteed to be added at the end of the array.

### Parameters
* `v`:\\[in\\] A pointer to the object. Used for search only.
* `position`:\\[out\\] If position != NULL, *position is set to the array position of the already contained, or if not present, the new object.
### Returns
Returns NULL if the object is already contained. Otherwise returns its new address in the array.
### Prototype
```c
void *sc_hash_array_insert_unique (sc_hash_array_t * hash_array, void *v, size_t *position);
```
"""
function sc_hash_array_insert_unique(hash_array, v, position)
    @ccall libsc.sc_hash_array_insert_unique(hash_array::Ptr{sc_hash_array_t}, v::Ptr{Cvoid}, position::Ptr{Csize_t})::Ptr{Cvoid}
end

"""
    sc_hash_array_rip(hash_array, rip)

Extract the array data from a hash array and destroy everything else.

### Parameters
* `hash_array`:\\[in\\] The hash array is destroyed after extraction.
* `rip`:\\[in\\] Array structure that will be overwritten. All previous array data (if any) will be leaked. The filled array can be freed with [`sc_array_reset`](@ref).
### Prototype
```c
void sc_hash_array_rip (sc_hash_array_t * hash_array, sc_array_t * rip);
```
"""
function sc_hash_array_rip(hash_array, rip)
    @ccall libsc.sc_hash_array_rip(hash_array::Ptr{sc_hash_array_t}, rip::Ptr{sc_array_t})::Cvoid
end

"""
    sc_recycle_array

The [`sc_recycle_array`](@ref) object provides an array of slots that can be reused.

It keeps a list of free slots in the array which will be used for insertion while available. Otherwise, the array is grown.
"""
struct sc_recycle_array
    elem_count::Csize_t
    a::sc_array_t
    f::sc_array_t
end

"""
The [`sc_recycle_array`](@ref) object provides an array of slots that can be reused.

It keeps a list of free slots in the array which will be used for insertion while available. Otherwise, the array is grown.
"""
const sc_recycle_array_t = sc_recycle_array

"""
    sc_recycle_array_init(rec_array, elem_size)

Initialize a recycle array.

### Parameters
* `elem_size`:\\[in\\] Size of the objects to be stored in the array.
### Prototype
```c
void sc_recycle_array_init (sc_recycle_array_t * rec_array, size_t elem_size);
```
"""
function sc_recycle_array_init(rec_array, elem_size)
    @ccall libsc.sc_recycle_array_init(rec_array::Ptr{sc_recycle_array_t}, elem_size::Csize_t)::Cvoid
end

"""
    sc_recycle_array_reset(rec_array)

Reset a recycle array.

As with all \\_reset functions, calling \\_init, then any array operations, then \\_reset is memory neutral.

### Prototype
```c
void sc_recycle_array_reset (sc_recycle_array_t * rec_array);
```
"""
function sc_recycle_array_reset(rec_array)
    @ccall libsc.sc_recycle_array_reset(rec_array::Ptr{sc_recycle_array_t})::Cvoid
end

"""
    sc_recycle_array_insert(rec_array, position)

Insert an object into the recycle array. The object is not copied into the array. Use the return value for that.

### Parameters
* `position`:\\[out\\] If position != NULL, *position is set to the array position of the inserted object.
### Returns
Returns the new address of the object in the array.
### Prototype
```c
void *sc_recycle_array_insert (sc_recycle_array_t * rec_array, size_t *position);
```
"""
function sc_recycle_array_insert(rec_array, position)
    @ccall libsc.sc_recycle_array_insert(rec_array::Ptr{sc_recycle_array_t}, position::Ptr{Csize_t})::Ptr{Cvoid}
end

"""
    sc_recycle_array_remove(rec_array, position)

Remove an object from the recycle array. It must be valid.

### Parameters
* `position`:\\[in\\] Index into the array for the object to remove.
### Returns
The pointer to the removed object. Will be valid as long as no other function is called on this recycle array.
### Prototype
```c
void *sc_recycle_array_remove (sc_recycle_array_t * rec_array, size_t position);
```
"""
function sc_recycle_array_remove(rec_array, position)
    @ccall libsc.sc_recycle_array_remove(rec_array::Ptr{sc_recycle_array_t}, position::Csize_t)::Ptr{Cvoid}
end

"""A type for storing SFC indices"""
const t8_linearidx_t = UInt64

"""
    t8_MPI_tag_t

Communication tags used internal to t8code.

| Enumerator                      | Note                               |
| :------------------------------ | :--------------------------------- |
| T8\\_MPI\\_PARTITION\\_CMESH    | Used for coarse mesh partitioning  |
| T8\\_MPI\\_PARTITION\\_FOREST   | Used for forest partitioning       |
| T8\\_MPI\\_GHOST\\_FOREST       | Used for for ghost layer creation  |
| T8\\_MPI\\_GHOST\\_EXC\\_FOREST | Used for ghost data exchange       |
"""
@cenum t8_MPI_tag_t::UInt32 begin
    T8_MPI_TAG_FIRST = 214
    T8_MPI_PARTITION_CMESH = 295
    T8_MPI_PARTITION_FOREST = 296
    T8_MPI_GHOST_FOREST = 297
    T8_MPI_GHOST_EXC_FOREST = 298
    T8_MPI_TAG_LAST = 299
end

# automatic type deduction for variadic arguments may not be what you want, please use with caution
@generated function t8_logf(category, priority, fmt, va_list...)
        :(@ccall(libt8.t8_logf(category::Cint, priority::Cint, fmt::Cstring; $(to_c_type_pairs(va_list)...))::Cvoid))
    end

"""
    t8_log_indent_push()

Add one space to the start of t8's default log format.

### Prototype
```c
void t8_log_indent_push (void);
```
"""
function t8_log_indent_push()
    @ccall libt8.t8_log_indent_push()::Cvoid
end

"""
    t8_log_indent_pop()

Remove one space from the start of a t8's default log format.

### Prototype
```c
void t8_log_indent_pop (void);
```
"""
function t8_log_indent_pop()
    @ccall libt8.t8_log_indent_pop()::Cvoid
end

# automatic type deduction for variadic arguments may not be what you want, please use with caution
@generated function t8_global_errorf(fmt, va_list...)
        :(@ccall(libt8.t8_global_errorf(fmt::Cstring; $(to_c_type_pairs(va_list)...))::Cvoid))
    end

# automatic type deduction for variadic arguments may not be what you want, please use with caution
@generated function t8_global_essentialf(fmt, va_list...)
        :(@ccall(libt8.t8_global_essentialf(fmt::Cstring; $(to_c_type_pairs(va_list)...))::Cvoid))
    end

# automatic type deduction for variadic arguments may not be what you want, please use with caution
@generated function t8_global_productionf(fmt, va_list...)
        :(@ccall(libt8.t8_global_productionf(fmt::Cstring; $(to_c_type_pairs(va_list)...))::Cvoid))
    end

# automatic type deduction for variadic arguments may not be what you want, please use with caution
@generated function t8_global_infof(fmt, va_list...)
        :(@ccall(libt8.t8_global_infof(fmt::Cstring; $(to_c_type_pairs(va_list)...))::Cvoid))
    end

# automatic type deduction for variadic arguments may not be what you want, please use with caution
@generated function t8_infof(fmt, va_list...)
        :(@ccall(libt8.t8_infof(fmt::Cstring; $(to_c_type_pairs(va_list)...))::Cvoid))
    end

# automatic type deduction for variadic arguments may not be what you want, please use with caution
@generated function t8_productionf(fmt, va_list...)
        :(@ccall(libt8.t8_productionf(fmt::Cstring; $(to_c_type_pairs(va_list)...))::Cvoid))
    end

# automatic type deduction for variadic arguments may not be what you want, please use with caution
@generated function t8_debugf(fmt, va_list...)
        :(@ccall(libt8.t8_debugf(fmt::Cstring; $(to_c_type_pairs(va_list)...))::Cvoid))
    end

# automatic type deduction for variadic arguments may not be what you want, please use with caution
@generated function t8_errorf(fmt, va_list...)
        :(@ccall(libt8.t8_errorf(fmt::Cstring; $(to_c_type_pairs(va_list)...))::Cvoid))
    end

"""
    t8_init(log_threshold)

Register t8code with libsc and print version and variable information.

### Parameters
* `log_threshold`:\\[in\\] Declared in sc.h. `SC_LP_DEFAULT` is fine. You can also choose from log levels SC\\_LP\\_*.
### Prototype
```c
void t8_init (int log_threshold);
```
"""
function t8_init(log_threshold)
    @ccall libt8.t8_init(log_threshold::Cint)::Cvoid
end

"""
    t8_sc_array_index_locidx(array, it)

Return a pointer to an array element indexed by a [`t8_locidx_t`](@ref).

### Parameters
* `index`:\\[in\\] needs to be in [0]..[elem\\_count-1].
### Returns
A void * pointing to entry *it* in *array*.
### Prototype
```c
void *t8_sc_array_index_locidx (sc_array_t *array, t8_locidx_t it);
```
"""
function t8_sc_array_index_locidx(array, it)
    @ccall libt8.t8_sc_array_index_locidx(array::Ptr{sc_array_t}, it::t8_locidx_t)::Ptr{Cvoid}
end

"""
    sc_shmem_type_t

` sc_shmem.h `

| Enumerator                    | Note                                         |
| :---------------------------- | :------------------------------------------- |
| SC\\_SHMEM\\_BASIC            | use allgathers, then sum to simulate scan    |
| SC\\_SHMEM\\_PRESCAN          | mpi\\_scan, then allgather                   |
| SC\\_SHMEM\\_WINDOW           | MPI\\_Win (requires MPI 3)                   |
| SC\\_SHMEM\\_WINDOW\\_PRESCAN | mpi\\_scan, then MPI\\_Win (requires MPI 3)  |
"""
@cenum sc_shmem_type_t::UInt32 begin
    SC_SHMEM_BASIC = 0
    SC_SHMEM_PRESCAN = 1
    SC_SHMEM_WINDOW = 2
    SC_SHMEM_WINDOW_PRESCAN = 3
    SC_SHMEM_NUM_TYPES = 4
    SC_SHMEM_NOT_SET = 5
end

"""
    sc_shmem_set_type(comm, type)

### Prototype
```c
void sc_shmem_set_type (sc_MPI_Comm comm, sc_shmem_type_t type);
```
"""
function sc_shmem_set_type(comm, type)
    @ccall libsc.sc_shmem_set_type(comm::MPI_Comm, type::sc_shmem_type_t)::Cvoid
end

"""
    sc_shmem_get_type(comm)

### Prototype
```c
sc_shmem_type_t sc_shmem_get_type (sc_MPI_Comm comm);
```
"""
function sc_shmem_get_type(comm)
    @ccall libsc.sc_shmem_get_type(comm::MPI_Comm)::sc_shmem_type_t
end

"""
    sc_shmem_write_start(array, comm)

### Prototype
```c
int sc_shmem_write_start (void *array, sc_MPI_Comm comm);
```
"""
function sc_shmem_write_start(array, comm)
    @ccall libsc.sc_shmem_write_start(array::Ptr{Cvoid}, comm::MPI_Comm)::Cint
end

"""
    sc_shmem_write_end(array, comm)

### Prototype
```c
void sc_shmem_write_end (void *array, sc_MPI_Comm comm);
```
"""
function sc_shmem_write_end(array, comm)
    @ccall libsc.sc_shmem_write_end(array::Ptr{Cvoid}, comm::MPI_Comm)::Cvoid
end

"""
    sc_shmem_memcpy(destarray, srcarray, bytes, comm)

### Prototype
```c
void sc_shmem_memcpy (void *destarray, void *srcarray, size_t bytes, sc_MPI_Comm comm);
```
"""
function sc_shmem_memcpy(destarray, srcarray, bytes, comm)
    @ccall libsc.sc_shmem_memcpy(destarray::Ptr{Cvoid}, srcarray::Ptr{Cvoid}, bytes::Csize_t, comm::MPI_Comm)::Cvoid
end

"""
    sc_shmem_allgather(sendbuf, sendcount, sendtype, recvbuf, recvcount, recvtype, comm)

### Prototype
```c
void sc_shmem_allgather (void *sendbuf, int sendcount, sc_MPI_Datatype sendtype, void *recvbuf, int recvcount, sc_MPI_Datatype recvtype, sc_MPI_Comm comm);
```
"""
function sc_shmem_allgather(sendbuf, sendcount, sendtype, recvbuf, recvcount, recvtype, comm)
    @ccall libsc.sc_shmem_allgather(sendbuf::Ptr{Cvoid}, sendcount::Cint, sendtype::Cint, recvbuf::Ptr{Cvoid}, recvcount::Cint, recvtype::Cint, comm::MPI_Comm)::Cvoid
end

"""
    sc_shmem_prefix(sendbuf, recvbuf, count, type, op, comm)

### Prototype
```c
void sc_shmem_prefix (void *sendbuf, void *recvbuf, int count, sc_MPI_Datatype type, sc_MPI_Op op, sc_MPI_Comm comm);
```
"""
function sc_shmem_prefix(sendbuf, recvbuf, count, type, op, comm)
    @ccall libsc.sc_shmem_prefix(sendbuf::Ptr{Cvoid}, recvbuf::Ptr{Cvoid}, count::Cint, type::Cint, op::Cint, comm::MPI_Comm)::Cvoid
end

"""
    sc_refcount

The refcount structure is declared in public so its size is known. Its members should really never be accessed directly.

| Field        | Note                                                         |
| :----------- | :----------------------------------------------------------- |
| package\\_id | The sc package that uses this reference counter.             |
| refcount     | The reference count is always positive for a valid counter.  |
"""
struct sc_refcount
    package_id::Cint
    refcount::Cint
end

"""The refcount structure is declared in public so its size is known. Its members should really never be accessed directly."""
const sc_refcount_t = sc_refcount

"""
    sc_refcount_init_invalid(rc)

Initialize a well-defined but unusable reference counter. Specifically, we set its package identifier and reference count to -1. To make this reference counter usable, call sc_refcount_init.

### Parameters
* `rc`:\\[out\\] This reference counter is defined as invalid. It will return false on both sc_refcount_is_active and sc_refcount_is_last. It can be made valid by calling sc_refcount_init. No other functions must be called on it.
### Prototype
```c
void sc_refcount_init_invalid (sc_refcount_t * rc);
```
"""
function sc_refcount_init_invalid(rc)
    @ccall libsc.sc_refcount_init_invalid(rc::Ptr{sc_refcount_t})::Cvoid
end

"""
    sc_refcount_init(rc, package_id)

Initialize a reference counter to 1. It is legal if its status prior to this call is undefined.

### Parameters
* `rc`:\\[out\\] This reference counter is initialized to one. The object's contents may be undefined on input.
* `package_id`:\\[in\\] Either -1 or a package registered to libsc.
### Prototype
```c
void sc_refcount_init (sc_refcount_t * rc, int package_id);
```
"""
function sc_refcount_init(rc, package_id)
    @ccall libsc.sc_refcount_init(rc::Ptr{sc_refcount_t}, package_id::Cint)::Cvoid
end

"""
    sc_refcount_new(package_id)

Create a new reference counter with count initialized to 1. Equivalent to calling sc_refcount_init on a newly allocated rc object.

### Parameters
* `package_id`:\\[in\\] Either -1 or a package registered to libsc.
### Returns
A reference counter with count one.
### Prototype
```c
sc_refcount_t *sc_refcount_new (int package_id);
```
"""
function sc_refcount_new(package_id)
    @ccall libsc.sc_refcount_new(package_id::Cint)::Ptr{sc_refcount_t}
end

"""
    sc_refcount_destroy(rc)

Destroy a reference counter. It must have been counted down to zero before, thus reached an inactive state.

### Parameters
* `rc`:\\[in,out\\] This reference counter must have reached count zero.
### Prototype
```c
void sc_refcount_destroy (sc_refcount_t * rc);
```
"""
function sc_refcount_destroy(rc)
    @ccall libsc.sc_refcount_destroy(rc::Ptr{sc_refcount_t})::Cvoid
end

"""
    sc_refcount_ref(rc)

Increase a reference counter. The counter must be active, that is, have a value greater than zero.

### Parameters
* `rc`:\\[in,out\\] This reference counter must be valid (greater zero). Its count is increased by one.
### Prototype
```c
void sc_refcount_ref (sc_refcount_t * rc);
```
"""
function sc_refcount_ref(rc)
    @ccall libsc.sc_refcount_ref(rc::Ptr{sc_refcount_t})::Cvoid
end

"""
    sc_refcount_unref(rc)

Decrease the reference counter and notify when it reaches zero. The count must be greater zero on input. If the reference count reaches zero, which is indicated by the return value, the counter may not be used further with sc_refcount_ref or

### Parameters
* `rc`:\\[in,out\\] This reference counter must be valid (greater zero). Its count is decreased by one.
### Returns
True if the count has reached zero, false otherwise.
### See also
[`sc_refcount_unref`](@ref). It is legal, however, to reactivate it later by calling, [`sc_refcount_init`](@ref).

### Prototype
```c
int sc_refcount_unref (sc_refcount_t * rc);
```
"""
function sc_refcount_unref(rc)
    @ccall libsc.sc_refcount_unref(rc::Ptr{sc_refcount_t})::Cint
end

"""
    sc_refcount_is_active(rc)

Check whether a reference counter has a positive value. This means that the reference counter is in use and corresponds to a live object.

### Parameters
* `rc`:\\[in\\] A reference counter.
### Returns
True if the count is greater zero, false otherwise.
### Prototype
```c
int sc_refcount_is_active (const sc_refcount_t * rc);
```
"""
function sc_refcount_is_active(rc)
    @ccall libsc.sc_refcount_is_active(rc::Ptr{sc_refcount_t})::Cint
end

"""
    sc_refcount_is_last(rc)

Check whether a reference counter has value one. This means that this counter is the last of its kind, which we may optimize for.

### Parameters
* `rc`:\\[in\\] A reference counter.
### Returns
True if the count is exactly one.
### Prototype
```c
int sc_refcount_is_last (const sc_refcount_t * rc);
```
"""
function sc_refcount_is_last(rc)
    @ccall libsc.sc_refcount_is_last(rc::Ptr{sc_refcount_t})::Cint
end

mutable struct t8_cmesh end

const t8_cmesh_t = Ptr{t8_cmesh}

mutable struct t8_ctree end

const t8_ctree_t = Ptr{t8_ctree}

mutable struct t8_cghost end

const t8_cghost_t = Ptr{t8_cghost}

"""
    t8_cmesh_init(pcmesh)

Create a new cmesh with reference count one. This cmesh needs to be specialized with the t8\\_cmesh\\_set\\_* calls. Then it needs to be set up with t8_cmesh_commit.

### Parameters
* `pcmesh`:\\[in,out\\] On input, this pointer must be non-NULL. On return, this pointer set to the new cmesh.
### Prototype
```c
void t8_cmesh_init (t8_cmesh_t *pcmesh);
```
"""
function t8_cmesh_init(pcmesh)
    @ccall libt8.t8_cmesh_init(pcmesh::Ptr{t8_cmesh_t})::Cvoid
end

"""
    t8_cmesh_is_initialized(cmesh)

Check whether a cmesh is not NULL, initialized and not committed. In addition, it asserts that the cmesh is consistent as much as possible.

### Parameters
* `cmesh`:\\[in\\] This cmesh is examined. May be NULL.
### Returns
True if cmesh is not NULL, t8_cmesh_init has been called on it, but not t8_cmesh_commit. False otherwise.
### Prototype
```c
int t8_cmesh_is_initialized (t8_cmesh_t cmesh);
```
"""
function t8_cmesh_is_initialized(cmesh)
    @ccall libt8.t8_cmesh_is_initialized(cmesh::t8_cmesh_t)::Cint
end

"""
    t8_cmesh_is_committed(cmesh)

Check whether a cmesh is not NULL, initialized and committed. In addition, it asserts that the cmesh is consistent as much as possible.

### Parameters
* `cmesh`:\\[in\\] This cmesh is examined. May be NULL.
### Returns
True if cmesh is not NULL and t8_cmesh_init has been called on it as well as t8_cmesh_commit. False otherwise.
### Prototype
```c
int t8_cmesh_is_committed (t8_cmesh_t cmesh);
```
"""
function t8_cmesh_is_committed(cmesh)
    @ccall libt8.t8_cmesh_is_committed(cmesh::t8_cmesh_t)::Cint
end

"""
    t8_eclass

This enumeration contains all possible element classes.

| Enumerator             | Note                                                                                                               |
| :--------------------- | :----------------------------------------------------------------------------------------------------------------- |
| T8\\_ECLASS\\_VERTEX   | The vertex is the only zero-dimensional element class.                                                             |
| T8\\_ECLASS\\_LINE     | The line is the only one-dimensional element class.                                                                |
| T8\\_ECLASS\\_QUAD     | The quadrilateral is one of two element classes in two dimensions.                                                 |
| T8\\_ECLASS\\_TRIANGLE | The element class for a triangle.                                                                                  |
| T8\\_ECLASS\\_HEX      | The hexahedron is one three-dimensional element class.                                                             |
| T8\\_ECLASS\\_TET      | The tetrahedron is another three-dimensional element class.                                                        |
| T8\\_ECLASS\\_PRISM    | The prism has five sides: two opposing triangles joined by three quadrilaterals.                                   |
| T8\\_ECLASS\\_PYRAMID  | The pyramid has a quadrilateral as base and four triangles as sides.                                               |
| T8\\_ECLASS\\_COUNT    | This is no element class but can be used as the number of element classes.                                         |
| T8\\_ECLASS\\_INVALID  | This is no element class but can be used for the case a class of a third party library is not supported by t8code  |
"""
@cenum t8_eclass::UInt32 begin
    T8_ECLASS_ZERO = 0
    T8_ECLASS_VERTEX = 0
    T8_ECLASS_LINE = 1
    T8_ECLASS_QUAD = 2
    T8_ECLASS_TRIANGLE = 3
    T8_ECLASS_HEX = 4
    T8_ECLASS_TET = 5
    T8_ECLASS_PRISM = 6
    T8_ECLASS_PYRAMID = 7
    T8_ECLASS_COUNT = 8
    T8_ECLASS_INVALID = 9
end

"""This enumeration contains all possible element classes."""
const t8_eclass_t = t8_eclass

"""
    t8_cmesh_tree_vertices_negative_volume(eclass, vertices, num_vertices)

Given a set of vertex coordinates for a tree of a given eclass. Query whether the geometric volume of the tree with this coordinates would be negative.

### Parameters
* `eclass`:\\[in\\] The eclass of a tree.
* `vertices`:\\[in\\] The coordinates of the tree's vertices.
* `num_vertices`:\\[in\\] The number of vertices. *vertices* must hold 3 * *num_vertices* many doubles. *num_vertices* must match t8_eclass_num_vertices[*eclass*]
### Returns
True if the geometric volume describe by *vertices* is negative. Fals otherwise. Returns true if a tree of the given eclass with the given vertex coordinates does have negative volume.
### Prototype
```c
int t8_cmesh_tree_vertices_negative_volume (t8_eclass_t eclass, double *vertices, int num_vertices);
```
"""
function t8_cmesh_tree_vertices_negative_volume(eclass, vertices, num_vertices)
    @ccall libt8.t8_cmesh_tree_vertices_negative_volume(eclass::t8_eclass_t, vertices::Ptr{Cdouble}, num_vertices::Cint)::Cint
end

"""
    t8_cmesh_set_derive(cmesh, set_from)

This function sets a cmesh to be derived from. The default is to create a cmesh standalone by specifying all data manually. A coarse mesh can also be constructed by deriving it from an existing one. The derivation from another cmesh may optionally be combined with a repartition or uniform refinement of each tree. This function overrides a previously set cmesh to be derived from.

### Parameters
* `cmesh`:\\[in,out\\] Must be initialized, but not committed. May even be NULL to revert to standalone.
* `set_from`:\\[in,out\\] Reference counter on this cmesh is bumped. It will be unbumped by t8_cmesh_commit, after which *from* is no longer remembered. Other than that the from object is not changed.
### Prototype
```c
void t8_cmesh_set_derive (t8_cmesh_t cmesh, t8_cmesh_t set_from);
```
"""
function t8_cmesh_set_derive(cmesh, set_from)
    @ccall libt8.t8_cmesh_set_derive(cmesh::t8_cmesh_t, set_from::t8_cmesh_t)::Cvoid
end

mutable struct t8_shmem_array end

const t8_shmem_array_t = Ptr{t8_shmem_array}

"""
    t8_cmesh_alloc_offsets(mpisize, comm)

### Prototype
```c
t8_shmem_array_t t8_cmesh_alloc_offsets (int mpisize, sc_MPI_Comm comm);
```
"""
function t8_cmesh_alloc_offsets(mpisize, comm)
    @ccall libt8.t8_cmesh_alloc_offsets(mpisize::Cint, comm::MPI_Comm)::t8_shmem_array_t
end

"""
    t8_cmesh_set_partition_range(cmesh, set_face_knowledge, first_local_tree, last_local_tree)

Declare if the cmesh is understood as a partitioned cmesh and specify the processor local tree range. This function should be preferred over t8_cmesh_set_partition_offsets when the cmesh is not derived from another cmesh. This call is only valid when the cmesh is not yet committed via a call to t8_cmesh_commit.

!!! note

    A value of *set_face_knowledge* other than -1 or 3 is not yet supported.

### Parameters
* `cmesh`:\\[in,out\\] The cmesh to be updated.  [in] set\\_face\\_knowledge Several values are possible that define how much information is required on face connections, specified by t8_cmesh_set_join. 0: Expect face connection of local trees. 1: In addition, expect face connection from ghost trees to local trees. 2: In addition, expect face connection between ghost trees. 3: Expect face connection of local and ghost trees. Consistency of this requirement is checked on t8_cmesh_commit. -1: Co not change the face\\_knowledge level but keep any previously set ones. (Possibly by a previous call to t8_cmesh_set_partition_range)
* `first_local_tree`:\\[in\\] The global index ID of the first tree on this process. If this tree is also the last tree on the previous process, then the argument must be -ID - 1.
* `last_local_tree`:\\[in\\] The global index of the last tree on this process. If this process should be empty then *last_local_tree* must be strictly smaller than *first_local_tree*.
### See also
t8\\_cmesh\\_set\\_partition\\_offset, [`t8_cmesh_set_partition_uniform`](@ref)

### Prototype
```c
void t8_cmesh_set_partition_range (t8_cmesh_t cmesh, int set_face_knowledge, t8_gloidx_t first_local_tree, t8_gloidx_t last_local_tree);
```
"""
function t8_cmesh_set_partition_range(cmesh, set_face_knowledge, first_local_tree, last_local_tree)
    @ccall libt8.t8_cmesh_set_partition_range(cmesh::t8_cmesh_t, set_face_knowledge::Cint, first_local_tree::t8_gloidx_t, last_local_tree::t8_gloidx_t)::Cvoid
end

"""
    t8_cmesh_set_partition_offsets(cmesh, tree_offsets)

Declare if the cmesh is understood as a partitioned cmesh and specify the first local tree for each process. This call is only valid when the cmesh is not yet committed via a call to t8_cmesh_commit. If instead t8_cmesh_set_partition_range was called and the cmesh is derived then the offset array is constructed during commit.

### Parameters
* `cmesh`:\\[in,out\\] The cmesh to be updated.
* `tree_offsets`:\\[in\\] An array of global tree\\_id offsets for each process can be specified here. TODO: document flag for shared trees.
### Prototype
```c
void t8_cmesh_set_partition_offsets (t8_cmesh_t cmesh, t8_shmem_array_t tree_offsets);
```
"""
function t8_cmesh_set_partition_offsets(cmesh, tree_offsets)
    @ccall libt8.t8_cmesh_set_partition_offsets(cmesh::t8_cmesh_t, tree_offsets::t8_shmem_array_t)::Cvoid
end

mutable struct t8_eclass_scheme end

"""This typedef holds virtual functions for a particular element class."""
const t8_eclass_scheme_c = t8_eclass_scheme

"""
    t8_scheme_cxx

The scheme holds implementations for one or more element classes.

| Field            | Note                                                   |
| :--------------- | :----------------------------------------------------- |
| rc               | Reference counter for this scheme.                     |
| eclass\\_schemes | This array holds one virtual table per element class.  |
"""
struct t8_scheme_cxx
    rc::sc_refcount_t
    eclass_schemes::NTuple{8, Ptr{t8_eclass_scheme_c}}
end

"""The scheme holds implementations for one or more element classes."""
const t8_scheme_cxx_t = t8_scheme_cxx

"""
    t8_cmesh_set_partition_uniform(cmesh, element_level, ts)

Declare if the cmesh is understood as a partitioned cmesh where the partition table is derived from an assumed uniform refinement of a given level. This call is only valid when the cmesh is not yet committed via a call to t8_cmesh_commit.

### Parameters
* `cmesh`:\\[in,out\\] The cmesh to be updated.
* `element_level`:\\[in\\] The refinement\\_level.
* `ts`:\\[in\\] The element scheme describing the refinement pattern. We take ownership. This can be prevented by referencing **ts** before calling this function.
### Prototype
```c
void t8_cmesh_set_partition_uniform (t8_cmesh_t cmesh, int element_level, t8_scheme_cxx_t *ts);
```
"""
function t8_cmesh_set_partition_uniform(cmesh, element_level, ts)
    @ccall libt8.t8_cmesh_set_partition_uniform(cmesh::t8_cmesh_t, element_level::Cint, ts::Ptr{t8_scheme_cxx_t})::Cvoid
end

"""
    t8_cmesh_set_refine(cmesh, level, scheme)

Refine the cmesh to a given level. Thus split each tree into x^level subtrees TODO: implement

### Prototype
```c
void t8_cmesh_set_refine (t8_cmesh_t cmesh, int level, t8_scheme_cxx_t *scheme);
```
"""
function t8_cmesh_set_refine(cmesh, level, scheme)
    @ccall libt8.t8_cmesh_set_refine(cmesh::t8_cmesh_t, level::Cint, scheme::Ptr{t8_scheme_cxx_t})::Cvoid
end

"""
    t8_cmesh_set_dimension(cmesh, dim)

Set the dimension of a cmesh. If any tree is inserted to the cmesh via [`t8_cmesh_set_tree_class`](@ref), then the dimension is set automatically to that of the inserted tree. However, if the cmesh is constructed partitioned and the part on this process is empty, it is neccessary to set the dimension by hand.

### Parameters
* `cmesh`:\\[in,out\\] The cmesh to be updated.
* `dim`:\\[in\\] The dimension to be set. Must satisfy 0 <= dim <= 3. The cmesh must not be committed before calling this function.
### Prototype
```c
void t8_cmesh_set_dimension (t8_cmesh_t cmesh, int dim);
```
"""
function t8_cmesh_set_dimension(cmesh, dim)
    @ccall libt8.t8_cmesh_set_dimension(cmesh::t8_cmesh_t, dim::Cint)::Cvoid
end

"""
    t8_cmesh_set_tree_class(cmesh, gtree_id, tree_class)

Set the class of a tree in the cmesh. It is not allowed to call this function after t8_cmesh_commit. It is not allowed to call this function multiple times for the same tree.

### Parameters
* `cmesh`:\\[in,out\\] The cmesh to be updated.
* `tree_id`:\\[in\\] The global number of the tree.
* `tree_class`:\\[in\\] The element class of this tree.
### Prototype
```c
void t8_cmesh_set_tree_class (t8_cmesh_t cmesh, t8_gloidx_t gtree_id, t8_eclass_t tree_class);
```
"""
function t8_cmesh_set_tree_class(cmesh, gtree_id, tree_class)
    @ccall libt8.t8_cmesh_set_tree_class(cmesh::t8_cmesh_t, gtree_id::t8_gloidx_t, tree_class::t8_eclass_t)::Cvoid
end

"""
    t8_cmesh_set_attribute(cmesh, gtree_id, package_id, key, data, data_size, data_persists)

Store an attribute at a tree in a cmesh. Attributes can be arbitrary data that is copied to an internal storage associated to the tree. Each application can set multiple attributes and attributes are distinguished by an interger key, where each application can use any integer as key.

!!! note

    If an attribute with the given package\\_id and key already exists, then it will get overwritten.

### Parameters
* `cmesh`:\\[in,out\\] The cmesh to be updated.
* `gtree_id`:\\[in\\] The global id of the tree.
* `package_id`:\\[in\\] Unique identifier of a valid software package.
* `key`:\\[in\\] An integer key used to identify this attribute under all attributes with the same package\\_id. *key* must be a unique value for this tree and package\\_id.
* `data`:\\[in\\] A pointer to the attribute data.
* `data_size`:\\[in\\] The number of bytes of the attribute.
* `data_persists`:\\[in\\] This flag can be used to optimize memory. If true then t8code assumes that the attribute data is present at the memory that *data* points to when t8_cmesh_commit is called (This is more memory efficient). If the flag is false an internal copy of the data is created immediately and this copy is used at commit. In both cases a copy of the data is used by t8\\_code after [`t8_cmesh_commit`](@ref).
### See also
[`sc_package_register`](@ref)

### Prototype
```c
void t8_cmesh_set_attribute (t8_cmesh_t cmesh, t8_gloidx_t gtree_id, int package_id, int key, void *data, size_t data_size, int data_persists);
```
"""
function t8_cmesh_set_attribute(cmesh, gtree_id, package_id, key, data, data_size, data_persists)
    @ccall libt8.t8_cmesh_set_attribute(cmesh::t8_cmesh_t, gtree_id::t8_gloidx_t, package_id::Cint, key::Cint, data::Ptr{Cvoid}, data_size::Csize_t, data_persists::Cint)::Cvoid
end

"""
    t8_cmesh_set_attribute_string(cmesh, gtree_id, package_id, key, string)

Store a string as an attribute at a tree in a cmesh.

!!! note

    You can also use t8_cmesh_set_attribute, but we recommend using this specialized function for strings.

### Parameters
* `cmesh`:\\[in,out\\] The cmesh to be updated.
* `gtree_id`:\\[in\\] The global id of the tree.
* `package_id`:\\[in\\] Unique identifier of a valid software package.
* `key`:\\[in\\] An integer key used to identify this attribute under all attributes with the same package\\_id. *key* must be a unique value for this tree and package\\_id.
* `string`:\\[in\\] The string to store as attribute.
### See also
[`sc_package_register`](@ref)

### Prototype
```c
void t8_cmesh_set_attribute_string (t8_cmesh_t cmesh, t8_gloidx_t gtree_id, int package_id, int key, const char *string);
```
"""
function t8_cmesh_set_attribute_string(cmesh, gtree_id, package_id, key, string)
    @ccall libt8.t8_cmesh_set_attribute_string(cmesh::t8_cmesh_t, gtree_id::t8_gloidx_t, package_id::Cint, key::Cint, string::Cstring)::Cvoid
end

"""
    t8_cmesh_set_join(cmesh, gtree1, gtree2, face1, face2, orientation)

Insert a face-connection between two trees in a cmesh.

### Parameters
* `cmesh`:\\[in,out\\] The cmesh to be updated.
* `tree1`:\\[in\\] The tree id of the first of the two trees.
* `tree2`:\\[in\\] The tree id of the second of the two trees.
* `face1`:\\[in\\] The face number of the first tree.
* `face2`:\\[in\\] The face number of the second tree.
* `orientation`:\\[in\\] Specify how face1 and face2 are oriented to each other TODO: orientation needs to be carefully defined for all element classes. TODO: document orientation
### Prototype
```c
void t8_cmesh_set_join (t8_cmesh_t cmesh, t8_gloidx_t gtree1, t8_gloidx_t gtree2, int face1, int face2, int orientation);
```
"""
function t8_cmesh_set_join(cmesh, gtree1, gtree2, face1, face2, orientation)
    @ccall libt8.t8_cmesh_set_join(cmesh::t8_cmesh_t, gtree1::t8_gloidx_t, gtree2::t8_gloidx_t, face1::Cint, face2::Cint, orientation::Cint)::Cvoid
end

"""
    t8_cmesh_set_profiling(cmesh, set_profiling)

Enable or disable profiling for a cmesh. If profiling is enabled, runtimes and statistics are collected during cmesh\\_commit.

Profiling is disabled by default. The cmesh must not be committed before calling this function.

### Parameters
* `cmesh`:\\[in,out\\] The cmesh to be updated.
* `set_profiling`:\\[in\\] If true, profiling will be enabled, if false disabled.
### See also
[`t8_cmesh_print_profile`](@ref)

### Prototype
```c
void t8_cmesh_set_profiling (t8_cmesh_t cmesh, int set_profiling);
```
"""
function t8_cmesh_set_profiling(cmesh, set_profiling)
    @ccall libt8.t8_cmesh_set_profiling(cmesh::t8_cmesh_t, set_profiling::Cint)::Cvoid
end

"""
    t8_cmesh_is_equal(cmesh_a, cmesh_b)

Check whether two given cmeshes carry the same information.

### Parameters
* `cmesh_a`:\\[in\\] The first of the two cmeshes to be checked.
* `cmesh_b`:\\[in\\] The second of the two cmeshes to be checked.
### Returns
True if both cmeshes carry the same information, false otherwise. TODO: define carefully. Orders, sequences, equivalences? This function works on committed and uncommitted cmeshes.
### Prototype
```c
int t8_cmesh_is_equal (t8_cmesh_t cmesh_a, t8_cmesh_t cmesh_b);
```
"""
function t8_cmesh_is_equal(cmesh_a, cmesh_b)
    @ccall libt8.t8_cmesh_is_equal(cmesh_a::t8_cmesh_t, cmesh_b::t8_cmesh_t)::Cint
end

"""
    t8_cmesh_is_empty(cmesh)

Check whether a cmesh is empty on all processes.

### Parameters
* `cmesh`:\\[in\\] A committed cmesh.
### Returns
True (non-zero) if and only if the cmesh has trees at all.
### Prototype
```c
int t8_cmesh_is_empty (t8_cmesh_t cmesh);
```
"""
function t8_cmesh_is_empty(cmesh)
    @ccall libt8.t8_cmesh_is_empty(cmesh::t8_cmesh_t)::Cint
end

"""
    t8_cmesh_bcast(cmesh_in, root, comm)

### Prototype
```c
t8_cmesh_t t8_cmesh_bcast (t8_cmesh_t cmesh_in, int root, sc_MPI_Comm comm);
```
"""
function t8_cmesh_bcast(cmesh_in, root, comm)
    @ccall libt8.t8_cmesh_bcast(cmesh_in::t8_cmesh_t, root::Cint, comm::MPI_Comm)::t8_cmesh_t
end

mutable struct t8_geometry end

"""This typedef holds virtual functions for a particular geometry. We need it so that we can use [`t8_geometry_c`](@ref) pointers in .c files without them seeing the actual C++ code (and then not compiling)"""
const t8_geometry_c = t8_geometry

"""
    t8_cmesh_register_geometry(cmesh, geometry)

### Prototype
```c
void t8_cmesh_register_geometry (t8_cmesh_t cmesh, const t8_geometry_c *geometry);
```
"""
function t8_cmesh_register_geometry(cmesh, geometry)
    @ccall libt8.t8_cmesh_register_geometry(cmesh::t8_cmesh_t, geometry::Ptr{t8_geometry_c})::Cvoid
end

"""
    t8_cmesh_set_tree_geometry(cmesh, gtreeid, geom_name)

Set the geometry for a tree, thus specify which geometry to use for this tree.

### Parameters
* `cmesh`:\\[in\\] A non-committed cmesh.
* `gtreeid`:\\[in\\] A global tree id in *cmesh*.
* `geom_name`:\\[in\\] The name of the geometry to use for this tree. See also t8_cmesh_get_tree_geometry
### Prototype
```c
void t8_cmesh_set_tree_geometry (t8_cmesh_t cmesh, t8_gloidx_t gtreeid, const char *geom_name);
```
"""
function t8_cmesh_set_tree_geometry(cmesh, gtreeid, geom_name)
    @ccall libt8.t8_cmesh_set_tree_geometry(cmesh::t8_cmesh_t, gtreeid::t8_gloidx_t, geom_name::Cstring)::Cvoid
end

"""
    t8_cmesh_commit(cmesh, comm)

### Prototype
```c
void t8_cmesh_commit (t8_cmesh_t cmesh, sc_MPI_Comm comm);
```
"""
function t8_cmesh_commit(cmesh, comm)
    @ccall libt8.t8_cmesh_commit(cmesh::t8_cmesh_t, comm::MPI_Comm)::Cvoid
end

"""
    t8_cmesh_save(cmesh, fileprefix)

### Prototype
```c
int t8_cmesh_save (t8_cmesh_t cmesh, const char *fileprefix);
```
"""
function t8_cmesh_save(cmesh, fileprefix)
    @ccall libt8.t8_cmesh_save(cmesh::t8_cmesh_t, fileprefix::Cstring)::Cint
end

"""
    t8_cmesh_load(filename, comm)

### Prototype
```c
t8_cmesh_t t8_cmesh_load (const char *filename, sc_MPI_Comm comm);
```
"""
function t8_cmesh_load(filename, comm)
    @ccall libt8.t8_cmesh_load(filename::Cstring, comm::MPI_Comm)::t8_cmesh_t
end

"""
    t8_load_mode

This enumeration contains all modes in which we can open a saved cmesh. The cmesh can be loaded with more processes than it was saved and the mode controls, which of the processes open files and distribute the data.

| Enumerator         | Note                                                                                                                                                                                                                        |
| :----------------- | :-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| T8\\_LOAD\\_SIMPLE | In simple mode, the first n processes load the file                                                                                                                                                                         |
| T8\\_LOAD\\_BGQ    | In BGQ mode, the file is loaded on n nodes and from one process of each node. This needs MPI Version 3.1 or higher.                                                                                                         |
| T8\\_LOAD\\_STRIDE | Every n-th process loads a file. Handle with care, we introduce it, since on Juqueen MPI-3 was not available. The parameter n has to be passed as an extra parameter.  ### See also [`t8_cmesh_load_and_distribute`](@ref)  |
| T8\\_LOAD\\_COUNT  |                                                                                                                                                                                                                             |
"""
@cenum t8_load_mode::UInt32 begin
    T8_LOAD_FIRST = 0
    T8_LOAD_SIMPLE = 0
    T8_LOAD_BGQ = 1
    T8_LOAD_STRIDE = 2
    T8_LOAD_COUNT = 3
end

"""This enumeration contains all modes in which we can open a saved cmesh. The cmesh can be loaded with more processes than it was saved and the mode controls, which of the processes open files and distribute the data."""
const t8_load_mode_t = t8_load_mode

"""
    t8_cmesh_load_and_distribute(fileprefix, num_files, comm, mode, procs_per_node)

### Prototype
```c
t8_cmesh_t t8_cmesh_load_and_distribute (const char *fileprefix, int num_files, sc_MPI_Comm comm, t8_load_mode_t mode, int procs_per_node);
```
"""
function t8_cmesh_load_and_distribute(fileprefix, num_files, comm, mode, procs_per_node)
    @ccall libt8.t8_cmesh_load_and_distribute(fileprefix::Cstring, num_files::Cint, comm::MPI_Comm, mode::t8_load_mode_t, procs_per_node::Cint)::t8_cmesh_t
end

"""
    t8_cmesh_comm_is_valid(cmesh, comm)

### Prototype
```c
int t8_cmesh_comm_is_valid (t8_cmesh_t cmesh, sc_MPI_Comm comm);
```
"""
function t8_cmesh_comm_is_valid(cmesh, comm)
    @ccall libt8.t8_cmesh_comm_is_valid(cmesh::t8_cmesh_t, comm::MPI_Comm)::Cint
end

"""
    t8_cmesh_is_partitioned(cmesh)

Query whether a committed cmesh is partitioned or replicated.

### Parameters
* `cmesh`:\\[in\\] A committed cmesh.
### Returns
True if *cmesh* is partitioned. False otherwise. *cmesh* must be committed before calling this function.
### Prototype
```c
int t8_cmesh_is_partitioned (t8_cmesh_t cmesh);
```
"""
function t8_cmesh_is_partitioned(cmesh)
    @ccall libt8.t8_cmesh_is_partitioned(cmesh::t8_cmesh_t)::Cint
end

"""
    t8_cmesh_get_num_trees(cmesh)

Return the global number of trees in a cmesh.

### Parameters
* `cmesh`:\\[in\\] The cmesh to be considered.
### Returns
The number of trees associated to *cmesh*. *cmesh* must be committed before calling this function.
### Prototype
```c
t8_gloidx_t t8_cmesh_get_num_trees (t8_cmesh_t cmesh);
```
"""
function t8_cmesh_get_num_trees(cmesh)
    @ccall libt8.t8_cmesh_get_num_trees(cmesh::t8_cmesh_t)::t8_gloidx_t
end

"""
    t8_cmesh_get_num_local_trees(cmesh)

Return the number of local trees of a cmesh. If the cmesh is not partitioned this is equivalent to t8_cmesh_get_num_trees.

### Parameters
* `cmesh`:\\[in\\] The cmesh to be considered.
### Returns
The number of local trees of the cmesh. *cmesh* must be committed before calling this function.
### Prototype
```c
t8_locidx_t t8_cmesh_get_num_local_trees (t8_cmesh_t cmesh);
```
"""
function t8_cmesh_get_num_local_trees(cmesh)
    @ccall libt8.t8_cmesh_get_num_local_trees(cmesh::t8_cmesh_t)::t8_locidx_t
end

"""
    t8_cmesh_get_num_ghosts(cmesh)

Return the number of ghost trees of a cmesh. If the cmesh is not partitioned this is equivalent to t8_cmesh_get_num_trees.

### Parameters
* `cmesh`:\\[in\\] The cmesh to be considered.
### Returns
The number of ghost trees of the cmesh. *cmesh* must be committed before calling this function.
### Prototype
```c
t8_locidx_t t8_cmesh_get_num_ghosts (t8_cmesh_t cmesh);
```
"""
function t8_cmesh_get_num_ghosts(cmesh)
    @ccall libt8.t8_cmesh_get_num_ghosts(cmesh::t8_cmesh_t)::t8_locidx_t
end

"""
    t8_cmesh_get_first_treeid(cmesh)

Return the global index of the first local tree of a cmesh. If the cmesh is not partitioned this is allways 0.

### Parameters
* `cmesh`:\\[in\\] The cmesh to be considered.
### Returns
The global id of the first local tree in cmesh. *cmesh* must be committed before calling this function.
### Prototype
```c
t8_gloidx_t t8_cmesh_get_first_treeid (t8_cmesh_t cmesh);
```
"""
function t8_cmesh_get_first_treeid(cmesh)
    @ccall libt8.t8_cmesh_get_first_treeid(cmesh::t8_cmesh_t)::t8_gloidx_t
end

"""
    t8_cmesh_get_tree_geometry(cmesh, gtreeid)

### Prototype
```c
const t8_geometry_c *t8_cmesh_get_tree_geometry (t8_cmesh_t cmesh, t8_gloidx_t gtreeid);
```
"""
function t8_cmesh_get_tree_geometry(cmesh, gtreeid)
    @ccall libt8.t8_cmesh_get_tree_geometry(cmesh::t8_cmesh_t, gtreeid::t8_gloidx_t)::Ptr{t8_geometry_c}
end

"""
    t8_cmesh_treeid_is_local_tree(cmesh, ltreeid)

Query whether a given [`t8_locidx_t`](@ref) belongs to a local tree of a cmesh.

### Parameters
* `cmesh`:\\[in\\] The cmesh to be considered.
* `ltreeid`:\\[in\\] An (possible) tree index.
### Returns
True if *ltreeid* matches the range of local trees of *cmesh*. False if not. *cmesh* must be committed before calling this function.
### Prototype
```c
int t8_cmesh_treeid_is_local_tree (const t8_cmesh_t cmesh, const t8_locidx_t ltreeid);
```
"""
function t8_cmesh_treeid_is_local_tree(cmesh, ltreeid)
    @ccall libt8.t8_cmesh_treeid_is_local_tree(cmesh::t8_cmesh_t, ltreeid::t8_locidx_t)::Cint
end

"""
    t8_cmesh_treeid_is_ghost(cmesh, ltreeid)

Query whether a given [`t8_locidx_t`](@ref) belongs to a ghost of a cmesh.

### Parameters
* `cmesh`:\\[in\\] The cmesh to be considered.
* `ltreeid`:\\[in\\] An (possible) ghost index.
### Returns
True if *ltreeid* matches the range of ghost trees of *cmesh*. False if not. *cmesh* must be committed before calling this function.
### Prototype
```c
int t8_cmesh_treeid_is_ghost (const t8_cmesh_t cmesh, const t8_locidx_t ltreeid);
```
"""
function t8_cmesh_treeid_is_ghost(cmesh, ltreeid)
    @ccall libt8.t8_cmesh_treeid_is_ghost(cmesh::t8_cmesh_t, ltreeid::t8_locidx_t)::Cint
end

"""
    t8_cmesh_ltreeid_to_ghostid(cmesh, ltreeid)

Given a local tree id that belongs to a ghost, return the index of the ghost.

### Parameters
* `cmesh`:\\[in\\] The cmesh to be considered.
* `ltreeid`:\\[in\\] The local id of a ghost, satisfying t8_cmesh_treeid_is_ghost, thus num\\_trees <= *ltreeid* < num\\_trees + num\\_ghosts
### Returns
The index of the ghost whithin all ghosts, thus an index 0 <= index < num\\_ghosts *cmesh* must be committed before calling this function.
### Prototype
```c
t8_locidx_t t8_cmesh_ltreeid_to_ghostid (const t8_cmesh_t cmesh, const t8_locidx_t ltreeid);
```
"""
function t8_cmesh_ltreeid_to_ghostid(cmesh, ltreeid)
    @ccall libt8.t8_cmesh_ltreeid_to_ghostid(cmesh::t8_cmesh_t, ltreeid::t8_locidx_t)::t8_locidx_t
end

"""
    t8_cmesh_get_first_tree(cmesh)

Return a pointer to the first local tree in a cmesh.

### Parameters
* `cmesh`:\\[in\\] The cmesh to be queried.
### Returns
A pointer to the first local tree in *cmesh*. If *cmesh* has no local trees, NULL is returned. *cmesh* must be committed before calling this function.
### Prototype
```c
t8_ctree_t t8_cmesh_get_first_tree (t8_cmesh_t cmesh);
```
"""
function t8_cmesh_get_first_tree(cmesh)
    @ccall libt8.t8_cmesh_get_first_tree(cmesh::t8_cmesh_t)::t8_ctree_t
end

"""
    t8_cmesh_get_next_tree(cmesh, tree)

Given a local tree in a cmesh return a pointer to the next local tree.

### Parameters
* `cmesh`:\\[in\\] The cmesh to be queried.
* `tree`:\\[in\\] A local tree in *cmesh*.
### Returns
A pointer to the next local tree in *cmesh* after *tree*. If no such tree exists, NULL is returned. * *cmesh* must be committed before calling this function. TODO: If we run over tree numbers only, don't use ctree\\_t in API if possible.
### Prototype
```c
t8_ctree_t t8_cmesh_get_next_tree (t8_cmesh_t cmesh, t8_ctree_t tree);
```
"""
function t8_cmesh_get_next_tree(cmesh, tree)
    @ccall libt8.t8_cmesh_get_next_tree(cmesh::t8_cmesh_t, tree::t8_ctree_t)::t8_ctree_t
end

"""
    t8_cmesh_get_tree(cmesh, ltree_id)

Return a pointer to a given local tree.

### Parameters
* `cmesh`:\\[in\\] The cmesh to be queried.
* `ltree_id`:\\[in\\] The local id of the tree that is asked for.
### Returns
A pointer to tree in *cmesh* with local id *ltree_id*. The cmesh must have at least *ltree_id* + 1 local trees when calling this function. *cmesh* must be committed before calling this function.
### Prototype
```c
t8_ctree_t t8_cmesh_get_tree (t8_cmesh_t cmesh, t8_locidx_t ltree_id);
```
"""
function t8_cmesh_get_tree(cmesh, ltree_id)
    @ccall libt8.t8_cmesh_get_tree(cmesh::t8_cmesh_t, ltree_id::t8_locidx_t)::t8_ctree_t
end

"""
    t8_cmesh_get_tree_class(cmesh, ltree_id)

Return the eclass of a given local tree. TODO: Should we refer to indices or consequently use ctree\\_t?

### Parameters
* `cmesh`:\\[in\\] The cmesh to be considered.
* `tree_id`:\\[in\\] The local id of the tree whose eclass will be returned.
### Returns
The eclass of the given tree. TODO: Call tree ids ltree\\_id or gtree\\_id etc. instead of tree\\_id. *cmesh* must be committed before calling this function.
### Prototype
```c
t8_eclass_t t8_cmesh_get_tree_class (t8_cmesh_t cmesh, t8_locidx_t ltree_id);
```
"""
function t8_cmesh_get_tree_class(cmesh, ltree_id)
    @ccall libt8.t8_cmesh_get_tree_class(cmesh::t8_cmesh_t, ltree_id::t8_locidx_t)::t8_eclass_t
end

"""
    t8_cmesh_tree_face_is_boundary(cmesh, ltree_id, face)

Query whether a face of a local tree or ghost is at the domain boundary.

### Parameters
* `cmesh`:\\[in\\] The cmesh to be considered.
* `ltree_id`:\\[in\\] The local id of a tree.
* `face`:\\[in\\] The number of a face of the tree.
### Returns
True if the face is at the domain boundary. False otherwise. *cmesh* must be committed before calling this function.
### Prototype
```c
int t8_cmesh_tree_face_is_boundary (t8_cmesh_t cmesh, t8_locidx_t ltree_id, int face);
```
"""
function t8_cmesh_tree_face_is_boundary(cmesh, ltree_id, face)
    @ccall libt8.t8_cmesh_tree_face_is_boundary(cmesh::t8_cmesh_t, ltree_id::t8_locidx_t, face::Cint)::Cint
end

"""
    t8_cmesh_get_ghost_class(cmesh, lghost_id)

Return the eclass of a given local ghost. TODO: Should we refer to indices or consequently use cghost\\_t?

### Parameters
* `cmesh`:\\[in\\] The cmesh to be considered.
* `ghost_id`:\\[in\\] The local id of the ghost whose eclass will be returned. 0 <= *tree_id* < cmesh.num\\_ghosts.
### Returns
The eclass of the given ghost. *cmesh* must be committed before calling this function.
### Prototype
```c
t8_eclass_t t8_cmesh_get_ghost_class (t8_cmesh_t cmesh, t8_locidx_t lghost_id);
```
"""
function t8_cmesh_get_ghost_class(cmesh, lghost_id)
    @ccall libt8.t8_cmesh_get_ghost_class(cmesh::t8_cmesh_t, lghost_id::t8_locidx_t)::t8_eclass_t
end

"""
    t8_cmesh_get_global_id(cmesh, local_id)

Return the global id of a given local tree or ghost.

### Parameters
* `cmesh`:\\[in\\] The cmesh to be considered.
* `local_id`:\\[in\\] The local id of a tree or a ghost. If *local_id* < cmesh.num\\_local\\_trees then it is a tree, otherwise a ghost.
### Returns
The global id of the tree/ghost.
### See also
https://github.com/DLR-AMR/t8code/wiki/Tree-indexing for more details about tree indexing.

### Prototype
```c
t8_gloidx_t t8_cmesh_get_global_id (t8_cmesh_t cmesh, t8_locidx_t local_id);
```
"""
function t8_cmesh_get_global_id(cmesh, local_id)
    @ccall libt8.t8_cmesh_get_global_id(cmesh::t8_cmesh_t, local_id::t8_locidx_t)::t8_gloidx_t
end

"""
    t8_cmesh_get_local_id(cmesh, global_id)

Return the local id of a give global tree.

### Parameters
* `cmesh`:\\[in\\] The cmesh.
* `global_id`:\\[in\\] A global tree id.
### Returns
Either a value l 0 <= *l* < num\\_local\\_trees if *global_id* corresponds to a local tree, or num\\_local\\_trees <= *l* < num\\_local\\_trees + num\\_ghosts if *global_id* corresponds to a ghost trees, or negative if *global_id* neither matches a local nor a ghost tree.
### See also
https://github.com/DLR-AMR/t8code/wiki/Tree-indexing for more details about tree indexing.

### Prototype
```c
t8_locidx_t t8_cmesh_get_local_id (t8_cmesh_t cmesh, t8_gloidx_t global_id);
```
"""
function t8_cmesh_get_local_id(cmesh, global_id)
    @ccall libt8.t8_cmesh_get_local_id(cmesh::t8_cmesh_t, global_id::t8_gloidx_t)::t8_locidx_t
end

"""
    t8_cmesh_get_face_neighbor(cmesh, ltreeid, face, dual_face, orientation)

Given a local tree id and a face number, get information about the face neighbor tree.

!!! note

    If *ltreeid* is a ghost and it has a neighbor which is neither a local tree or ghost, then the return value will be negative. Thus, a negative return value does not necessarily mean that this is a domain boundary. To find out whether a tree is a domain boundary or not

### Parameters
* `cmesh`:\\[in\\] The cmesh to be considered.
* `ltreeid`:\\[in\\] The local id of a tree or a ghost.
* `face`:\\[in\\] A face number of the tree/ghost.
* `dual_face`:\\[out\\] If not NULL, the face number of the neighbor tree at this connection.
* `orientation`:\\[out\\] If not NULL, the face orientation of the connection.
### Returns
If non-negative: The local id of the neighbor tree or ghost. If negative: There is no neighbor across this face. *dual_face* and *orientation* remain unchanged.
### See also
[`t8_cmesh_tree_face_is_boundary`](@ref).

### Prototype
```c
t8_locidx_t t8_cmesh_get_face_neighbor (const t8_cmesh_t cmesh, const t8_locidx_t ltreeid, const int face, int *dual_face, int *orientation);
```
"""
function t8_cmesh_get_face_neighbor(cmesh, ltreeid, face, dual_face, orientation)
    @ccall libt8.t8_cmesh_get_face_neighbor(cmesh::t8_cmesh_t, ltreeid::t8_locidx_t, face::Cint, dual_face::Ptr{Cint}, orientation::Ptr{Cint})::t8_locidx_t
end

"""
    t8_cmesh_print_profile(cmesh)

Print the collected statistics from a cmesh profile.

*cmesh* must be committed before calling this function.

### Parameters
* `cmesh`:\\[in\\] The cmesh.
### See also
[`t8_cmesh_set_profiling`](@ref)

### Prototype
```c
void t8_cmesh_print_profile (t8_cmesh_t cmesh);
```
"""
function t8_cmesh_print_profile(cmesh)
    @ccall libt8.t8_cmesh_print_profile(cmesh::t8_cmesh_t)::Cvoid
end

"""
    t8_cmesh_get_tree_vertices(cmesh, ltreeid)

Return a pointer to the vertex coordinates of a tree.

### Parameters
* `cmesh`:\\[in\\] The cmesh.
* `ltreeid`:\\[in\\] The id of a local tree.
### Returns
If stored, a pointer to the vertex coordinates of *tree*. If no coordinates for this tree are found, NULL.
### Prototype
```c
double *t8_cmesh_get_tree_vertices (t8_cmesh_t cmesh, t8_locidx_t ltreeid);
```
"""
function t8_cmesh_get_tree_vertices(cmesh, ltreeid)
    @ccall libt8.t8_cmesh_get_tree_vertices(cmesh::t8_cmesh_t, ltreeid::t8_locidx_t)::Ptr{Cdouble}
end

"""
    t8_cmesh_get_attribute(cmesh, package_id, key, ltree_id)

Return the attribute pointer of a tree.

### Parameters
* `cmesh`:\\[in\\] The cmesh.
* `package_id`:\\[in\\] The identifier of a valid software package.
* `key`:\\[in\\] A key used to identify the attribute under all attributes of this tree with the same *package_id*.
* `tree_id`:\\[in\\] The local number of the tree.
* `data_size`:\\[out\\] The size of the attribute in bytes.
### Returns
The attribute pointer of the tree *ltree_id* or NULL if the attribute is not found. *cmesh* must be committed before calling this function.
### See also
[`sc_package_register`](@ref), [`t8_cmesh_set_attribute`](@ref)

### Prototype
```c
void *t8_cmesh_get_attribute (t8_cmesh_t cmesh, int package_id, int key, t8_locidx_t ltree_id);
```
"""
function t8_cmesh_get_attribute(cmesh, package_id, key, ltree_id)
    @ccall libt8.t8_cmesh_get_attribute(cmesh::t8_cmesh_t, package_id::Cint, key::Cint, ltree_id::t8_locidx_t)::Ptr{Cvoid}
end

"""
    t8_cmesh_get_partition_table(cmesh)

Return the shared memory array storing the partition table of a partitioned cmesh.

### Parameters
* `cmesh`:\\[in\\] The cmesh.
### Returns
The partition array. NULL if the cmesh is not partitioned or the partition array is not stored in *cmesh*. *cmesh* must be committed before calling this function.
### Prototype
```c
t8_shmem_array_t t8_cmesh_get_partition_table (t8_cmesh_t cmesh);
```
"""
function t8_cmesh_get_partition_table(cmesh)
    @ccall libt8.t8_cmesh_get_partition_table(cmesh::t8_cmesh_t)::t8_shmem_array_t
end

"""
    t8_cmesh_uniform_bounds(cmesh, level, ts, first_local_tree, child_in_tree_begin, last_local_tree, child_in_tree_end, first_tree_shared)

Calculate the section of a uniform forest for the current rank.

### Parameters
* `cmesh`:\\[in\\] The cmesh to be considered.
* `level`:\\[in\\] The uniform refinement level to be created.
* `ts`:\\[in\\] The element scheme for which to compute the bounds.
* `first_local_tree`:\\[out\\] The first tree that contains elements belonging to the calling processor.
* `child_in_tree_begin`:\\[out\\] The global index of the first element belonging to the calling processor. Not computed if NULL.
* `last_local_tree`:\\[out\\] The last tree that contains elements belonging to the calling processor.
* `child_in_tree_end`:\\[out\\] The global index of the first element that does not belonging to the calling processor anymore. Not computed if NULL.
* `first_tree_shared`:\\[out\\] If not NULL, 1 or 0 is stored here depending on whether *first_local_tree* is the same as *last_local_tree* on the next process. *cmesh* must be committed before calling this function. *
### Prototype
```c
void t8_cmesh_uniform_bounds (t8_cmesh_t cmesh, int level, t8_scheme_cxx_t *ts, t8_gloidx_t *first_local_tree, t8_gloidx_t *child_in_tree_begin, t8_gloidx_t *last_local_tree, t8_gloidx_t *child_in_tree_end, int8_t *first_tree_shared);
```
"""
function t8_cmesh_uniform_bounds(cmesh, level, ts, first_local_tree, child_in_tree_begin, last_local_tree, child_in_tree_end, first_tree_shared)
    @ccall libt8.t8_cmesh_uniform_bounds(cmesh::t8_cmesh_t, level::Cint, ts::Ptr{t8_scheme_cxx_t}, first_local_tree::Ptr{t8_gloidx_t}, child_in_tree_begin::Ptr{t8_gloidx_t}, last_local_tree::Ptr{t8_gloidx_t}, child_in_tree_end::Ptr{t8_gloidx_t}, first_tree_shared::Ptr{Int8})::Cvoid
end

"""
    t8_cmesh_ref(cmesh)

Increase the reference counter of a cmesh.

### Parameters
* `cmesh`:\\[in,out\\] On input, this cmesh must exist with positive reference count. It may be in any state.
### Prototype
```c
void t8_cmesh_ref (t8_cmesh_t cmesh);
```
"""
function t8_cmesh_ref(cmesh)
    @ccall libt8.t8_cmesh_ref(cmesh::t8_cmesh_t)::Cvoid
end

"""
    t8_cmesh_unref(pcmesh)

Decrease the reference counter of a cmesh. If the counter reaches zero, this cmesh is destroyed. See also t8_cmesh_destroy, which is to be preferred when it is known that the last reference to a cmesh is deleted.

### Parameters
* `pcmesh`:\\[in,out\\] On input, the cmesh pointed to must exist with positive reference count. It may be in any state. If the reference count reaches zero, the cmesh is destroyed and this pointer set to NULL. Otherwise, the pointer is not changed and the cmesh is not modified in other ways.
### Prototype
```c
void t8_cmesh_unref (t8_cmesh_t *pcmesh);
```
"""
function t8_cmesh_unref(pcmesh)
    @ccall libt8.t8_cmesh_unref(pcmesh::Ptr{t8_cmesh_t})::Cvoid
end

"""
    t8_cmesh_destroy(pcmesh)

Verify that a coarse mesh has only one reference left and destroy it. This function is preferred over t8_cmesh_unref when it is known that the last reference is to be deleted.

### Parameters
* `pcmesh`:\\[in,out\\] This cmesh must have a reference count of one. It can be in any state (committed or not). Then it effectively calls t8_cmesh_unref.
* `comm`:\\[in\\] A mpi communicator that is valid with *cmesh*.
### Prototype
```c
void t8_cmesh_destroy (t8_cmesh_t *pcmesh);
```
"""
function t8_cmesh_destroy(pcmesh)
    @ccall libt8.t8_cmesh_destroy(pcmesh::Ptr{t8_cmesh_t})::Cvoid
end

"""
    t8_cmesh_new_testhybrid(comm)

### Prototype
```c
t8_cmesh_t t8_cmesh_new_testhybrid (sc_MPI_Comm comm);
```
"""
function t8_cmesh_new_testhybrid(comm)
    @ccall libt8.t8_cmesh_new_testhybrid(comm::MPI_Comm)::t8_cmesh_t
end

"""
    t8_cmesh_coords_axb(coords_in, coords_out, num_vertices, alpha, b)

Compute y = ax + b on an array of doubles, interpreting each 3 as one vector x

### Parameters
* `coords_in`:\\[in\\] The incoming coordinates of the vectors
* `coords_out`:\\[out\\] The computed coordinates of the vectors
* `num_vertices`:\\[in\\] The number of vertices/vectors
* `alpha`:\\[in\\] Scaling factor for the vectors
* `b`:\\[in\\] Translation of the vectors.
### Prototype
```c
void t8_cmesh_coords_axb (const double *coords_in, double *coords_out, int num_vertices, double alpha, const double b[3]);
```
"""
function t8_cmesh_coords_axb(coords_in, coords_out, num_vertices, alpha, b)
    @ccall libt8.t8_cmesh_coords_axb(coords_in::Ptr{Cdouble}, coords_out::Ptr{Cdouble}, num_vertices::Cint, alpha::Cdouble, b::Ptr{Cdouble})::Cvoid
end

"""
    t8_cmesh_translate_coordinates(coords_in, coords_out, num_vertices, translate)

Compute y = x + translate on an array of doubles, interpreting  each 3 as one vector x

### Parameters
* `coords_in`:\\[in\\] The incoming coordinates of the vectors
* `coords_out`:\\[out\\] The computed coordinates of the vectors
* `num_vertices`:\\[in\\] The number of vertices/vectors
* `translate`:\\[in\\] Translation of the vectors.
### Prototype
```c
void t8_cmesh_translate_coordinates (const double *coords_in, double *coords_out, int num_vertices, double translate[3]);
```
"""
function t8_cmesh_translate_coordinates(coords_in, coords_out, num_vertices, translate)
    @ccall libt8.t8_cmesh_translate_coordinates(coords_in::Ptr{Cdouble}, coords_out::Ptr{Cdouble}, num_vertices::Cint, translate::Ptr{Cdouble})::Cvoid
end

"""
    t8_cmesh_new_translate_vertices_to_attributes(tvertices, vertices, attr_vertices, num_vertices)

TODO: Add proper documentation

### Prototype
```c
void t8_cmesh_new_translate_vertices_to_attributes (t8_locidx_t *tvertices, double *vertices, double *attr_vertices, int num_vertices);
```
"""
function t8_cmesh_new_translate_vertices_to_attributes(tvertices, vertices, attr_vertices, num_vertices)
    @ccall libt8.t8_cmesh_new_translate_vertices_to_attributes(tvertices::Ptr{t8_locidx_t}, vertices::Ptr{Cdouble}, attr_vertices::Ptr{Cdouble}, num_vertices::Cint)::Cvoid
end

"""
    t8_cmesh_debug_print_trees(cmesh, comm)

### Prototype
```c
void t8_cmesh_debug_print_trees (const t8_cmesh_t cmesh, sc_MPI_Comm comm);
```
"""
function t8_cmesh_debug_print_trees(cmesh, comm)
    @ccall libt8.t8_cmesh_debug_print_trees(cmesh::t8_cmesh_t, comm::MPI_Comm)::Cvoid
end

"""
    t8_netcdf_variable_type

This enumeration contains all possible netCDF variable datatypes (int, int64, double).

| Enumerator           | Note                                                                 |
| :------------------- | :------------------------------------------------------------------- |
| T8\\_NETCDF\\_INT    | Symbolizes netCDF variable datatype which holds 32-bit integer data  |
| T8\\_NETCDF\\_INT64  | Symbolizes netCDF variable datatype which holds 64-bit integer data  |
| T8\\_NETCDF\\_DOUBLE | Symbolizes netCDF variable datatype which holds double data          |
"""
@cenum t8_netcdf_variable_type::UInt32 begin
    T8_NETCDF_INT = 0
    T8_NETCDF_INT64 = 1
    T8_NETCDF_DOUBLE = 2
end

"""This enumeration contains all possible netCDF variable datatypes (int, int64, double)."""
const t8_netcdf_variable_type_t = t8_netcdf_variable_type

struct t8_netcdf_variable_t
    variable_name::Cstring
    variable_long_name::Cstring
    variable_units::Cstring
    datatype::t8_netcdf_variable_type_t
    var_user_dimid::Cint
    var_user_data::Ptr{sc_array_t}
end

"""
    t8_cmesh_write_netcdf(cmesh, file_prefix, file_title, dim, num_extern_netcdf_vars, variables, comm)

### Prototype
```c
void t8_cmesh_write_netcdf (t8_cmesh_t cmesh, const char *file_prefix, const char *file_title, int dim, int num_extern_netcdf_vars, t8_netcdf_variable_t * variables[], sc_MPI_Comm comm);
```
"""
function t8_cmesh_write_netcdf(cmesh, file_prefix, file_title, dim, num_extern_netcdf_vars, variables, comm)
    @ccall libt8.t8_cmesh_write_netcdf(cmesh::t8_cmesh_t, file_prefix::Cstring, file_title::Cstring, dim::Cint, num_extern_netcdf_vars::Cint, variables::Ptr{Ptr{t8_netcdf_variable_t}}, comm::MPI_Comm)::Cvoid
end

struct t8_msh_file_node_t
    index::t8_locidx_t
    coordinates::NTuple{3, Cdouble}
end

struct t8_msh_file_node_parametric_t
    index::t8_locidx_t
    coordinates::NTuple{3, Cdouble}
    parameters::NTuple{2, Cdouble}
    parametric::Cint
    entity_dim::Cint
    entity_tag::t8_locidx_t
end

"""
    t8_cmesh_from_msh_file(fileprefix, partition, comm, dim, master, use_occ_geometry)

### Prototype
```c
t8_cmesh_t t8_cmesh_from_msh_file (const char *fileprefix, int partition, sc_MPI_Comm comm, int dim, int master, int use_occ_geometry);
```
"""
function t8_cmesh_from_msh_file(fileprefix, partition, comm, dim, master, use_occ_geometry)
    @ccall libt8.t8_cmesh_from_msh_file(fileprefix::Cstring, partition::Cint, comm::MPI_Comm, dim::Cint, master::Cint, use_occ_geometry::Cint)::t8_cmesh_t
end

struct sc_stats
    mpicomm::MPI_Comm
    sarray::Ptr{sc_array_t}
end

"""The statistics container allows dynamically adding random variables."""
const sc_statistics_t = sc_stats

"""
    sc_statistics_has(stats, name)

Returns true if the stats include a variable with the given name

### Prototype
```c
int sc_statistics_has (sc_statistics_t * stats, const char *name);
```
"""
function sc_statistics_has(stats, name)
    @ccall libsc.sc_statistics_has(stats::Ptr{sc_statistics_t}, name::Cstring)::Cint
end

"""
    sc_statistics_add_empty(stats, name)

Register a statistics variable by name and set its count to 0. This variable must not exist already.

### Prototype
```c
void sc_statistics_add_empty (sc_statistics_t * stats, const char *name);
```
"""
function sc_statistics_add_empty(stats, name)
    @ccall libsc.sc_statistics_add_empty(stats::Ptr{sc_statistics_t}, name::Cstring)::Cvoid
end

struct sc_flopinfo
    seconds::Cdouble
    cwtime::Cdouble
    crtime::Cfloat
    cptime::Cfloat
    cflpops::Clonglong
    iwtime::Cdouble
    irtime::Cfloat
    iptime::Cfloat
    iflpops::Clonglong
    mflops::Cfloat
    use_papi::Cint
end

const sc_flopinfo_t = sc_flopinfo

"""
    sc_flops_snap(fi, snapshot)

Call [`sc_flops_count`](@ref) (fi) and copies fi into snapshot.

### Parameters
* `fi`:\\[in,out\\] Members will be updated.
* `snapshot`:\\[out\\] On output is a copy of fi.
### Prototype
```c
void sc_flops_snap (sc_flopinfo_t * fi, sc_flopinfo_t * snapshot);
```
"""
function sc_flops_snap(fi, snapshot)
    @ccall libsc.sc_flops_snap(fi::Ptr{sc_flopinfo_t}, snapshot::Ptr{sc_flopinfo_t})::Cvoid
end

"""
    sc_flops_shot(fi, snapshot)

Call [`sc_flops_count`](@ref) (fi) and override snapshot interval timings with the differences since the previous call to [`sc_flops_snap`](@ref). The interval mflop rate is computed by iflpops / 1e6 / irtime. The cumulative timings in snapshot are copied form fi.

### Parameters
* `fi`:\\[in,out\\] Members will be updated.
* `snapshot`:\\[in,out\\] Interval timings measured since [`sc_flops_snap`](@ref).
### Prototype
```c
void sc_flops_shot (sc_flopinfo_t * fi, sc_flopinfo_t * snapshot);
```
"""
function sc_flops_shot(fi, snapshot)
    @ccall libsc.sc_flops_shot(fi::Ptr{sc_flopinfo_t}, snapshot::Ptr{sc_flopinfo_t})::Cvoid
end

"""
    sc_statistics_accumulate(stats, name, value)

Add an instance of a statistics variable, see [`sc_stats_accumulate`](@ref) The variable must previously be added with [`sc_statistics_add_empty`](@ref).

### Prototype
```c
void sc_statistics_accumulate (sc_statistics_t * stats, const char *name, double value);
```
"""
function sc_statistics_accumulate(stats, name, value)
    @ccall libsc.sc_statistics_accumulate(stats::Ptr{sc_statistics_t}, name::Cstring, value::Cdouble)::Cvoid
end

"""
    sc_flops_papi(rtime, ptime, flpops, mflops)

Calls PAPI\\_flops. Aborts on PAPI error. The first call sets up the performance counters. Subsequent calls return cumulative real and process times, cumulative floating point operations and the flop rate since the last call. This is a compatibility wrapper: users should only need to use the [`sc_flopinfo_t`](@ref) interface functions below.

### Prototype
```c
void sc_flops_papi (float *rtime, float *ptime, long long *flpops, float *mflops);
```
"""
function sc_flops_papi(rtime, ptime, flpops, mflops)
    @ccall libsc.sc_flops_papi(rtime::Ptr{Cfloat}, ptime::Ptr{Cfloat}, flpops::Ptr{Clonglong}, mflops::Ptr{Cfloat})::Cvoid
end

"""
    sc_flops_start(fi)

Prepare [`sc_flopinfo_t`](@ref) structure and start flop counters. Must only be called once during the program run. This function calls [`sc_flops_papi`](@ref).

### Parameters
* `fi`:\\[out\\] Members will be initialized.
### Prototype
```c
void sc_flops_start (sc_flopinfo_t * fi);
```
"""
function sc_flops_start(fi)
    @ccall libsc.sc_flops_start(fi::Ptr{sc_flopinfo_t})::Cvoid
end

"""
    sc_flops_start_nopapi(fi)

Prepare [`sc_flopinfo_t`](@ref) structure and ignore the flop counters. This [`sc_flopinfo_t`](@ref) does not call PAPI\\_flops() in this function or in [`sc_flops_count`](@ref)().

### Parameters
* `fi`:\\[out\\] Members will be initialized.
### Prototype
```c
void sc_flops_start_nopapi (sc_flopinfo_t * fi);
```
"""
function sc_flops_start_nopapi(fi)
    @ccall libsc.sc_flops_start_nopapi(fi::Ptr{sc_flopinfo_t})::Cvoid
end

"""
    sc_flops_count(fi)

Update [`sc_flopinfo_t`](@ref) structure with current measurement. Must only be called after [`sc_flops_start`](@ref). Can be called any number of times. This function calls [`sc_flops_papi`](@ref).

### Parameters
* `fi`:\\[in,out\\] Members will be updated.
### Prototype
```c
void sc_flops_count (sc_flopinfo_t * fi);
```
"""
function sc_flops_count(fi)
    @ccall libsc.sc_flops_count(fi::Ptr{sc_flopinfo_t})::Cvoid
end

# automatic type deduction for variadic arguments may not be what you want, please use with caution
@generated function sc_flops_shotv(fi, va_list...)
        :(@ccall(libsc.sc_flops_shotv(fi::Ptr{sc_flopinfo_t}; $(to_c_type_pairs(va_list)...))::Cvoid))
    end

"""
    sc_keyvalue_entry_type_t

The values can have different types.

| Enumerator                      | Note                                        |
| :------------------------------ | :------------------------------------------ |
| SC\\_KEYVALUE\\_ENTRY\\_NONE    | Designate an invalid situation.             |
| SC\\_KEYVALUE\\_ENTRY\\_INT     | Used for values of type int.                |
| SC\\_KEYVALUE\\_ENTRY\\_DOUBLE  | Used for values of type double.             |
| SC\\_KEYVALUE\\_ENTRY\\_STRING  | Used for values of type const char *.       |
| SC\\_KEYVALUE\\_ENTRY\\_POINTER | Used for values of anonymous pointer type.  |
"""
@cenum sc_keyvalue_entry_type_t::UInt32 begin
    SC_KEYVALUE_ENTRY_NONE = 0
    SC_KEYVALUE_ENTRY_INT = 1
    SC_KEYVALUE_ENTRY_DOUBLE = 2
    SC_KEYVALUE_ENTRY_STRING = 3
    SC_KEYVALUE_ENTRY_POINTER = 4
end

mutable struct sc_keyvalue end

"""The key-value container is an opaque structure."""

# no prototype is found for this function at sc_keyvalue.h:52:21, please use with caution
"""
    sc_keyvalue_new()

Create a new key-value container.

### Returns
The container is ready to use.
### Prototype
```c
```
"""
function sc_keyvalue_new()
end

# automatic type deduction for variadic arguments may not be what you want, please use with caution
@generated function sc_keyvalue_newf(dummy, va_list...)
    end

"""
    sc_keyvalue_destroy(kv)

Free a key-value container and all internal memory for key storage.

### Parameters
* `kv`:\\[in,out\\] The key-value container is invalidated by this call.
### Prototype
```c
```
"""
function sc_keyvalue_destroy(kv)
end

"""
    sc_keyvalue_exists(kv, key)

Routine to check existence of an entry.

### Parameters
* `kv`:\\[in\\] Valid key-value container.
* `key`:\\[in\\] Lookup key to query.
### Returns
The entry's type if found and SC\\_KEYVALUE\\_ENTRY\\_NONE otherwise.
### Prototype
```c
```
"""
function sc_keyvalue_exists(kv, key)
end

"""
    sc_keyvalue_unset(kv, key)

Routine to remove an entry.

### Parameters
* `kv`:\\[in\\] Valid key-value container.
* `key`:\\[in\\] Lookup key to remove if it exists.
### Returns
The entry's type if found and removed, SC\\_KEYVALUE\\_ENTRY\\_NONE otherwise.
### Prototype
```c
```
"""
function sc_keyvalue_unset(kv, key)
end

"""
    sc_keyvalue_get_int(kv, key, dvalue)

Routines to retrieve an integer value by its key. This function asserts that the key, if existing, points to the correct type.

### Parameters
* `kv`:\\[in\\] Valid key-value container.
* `key`:\\[in\\] Lookup key, may or may not exist.
* `dvalue`:\\[in\\] Default value returned if key is not found.
### Returns
If key is not present then **dvalue** is returned, otherwise the value stored under **key**.
### Prototype
```c
```
"""
function sc_keyvalue_get_int(kv, key, dvalue)
end

"""
    sc_keyvalue_get_double(kv, key, dvalue)

Retrieve a double value by its key. This function asserts that the key, if existing, points to the correct type.

### Parameters
* `kv`:\\[in\\] Valid key-value container.
* `key`:\\[in\\] Lookup key, may or may not exist.
* `dvalue`:\\[in\\] Default value returned if key is not found.
### Returns
If key is not present then **dvalue** is returned, otherwise the value stored under **key**.
### Prototype
```c
```
"""
function sc_keyvalue_get_double(kv, key, dvalue)
end

"""
    sc_keyvalue_get_string(kv, key, dvalue)

Retrieve a string value by its key. This function asserts that the key, if existing, points to the correct type.

### Parameters
* `kv`:\\[in\\] Valid key-value container.
* `key`:\\[in\\] Lookup key, may or may not exist.
* `dvalue`:\\[in\\] Default value returned if key is not found.
### Returns
If key is not present then **dvalue** is returned, otherwise the value stored under **key**.
### Prototype
```c
```
"""
function sc_keyvalue_get_string(kv, key, dvalue)
end

"""
    sc_keyvalue_get_pointer(kv, key, dvalue)

Retrieve a pointer value by its key. This function asserts that the key, if existing, points to the correct type.

### Parameters
* `kv`:\\[in\\] Valid key-value container.
* `key`:\\[in\\] Lookup key, may or may not exist.
* `dvalue`:\\[in\\] Default value returned if key is not found.
### Returns
If key is not present then **dvalue** is returned, otherwise the value stored under **key**.
### Prototype
```c
```
"""
function sc_keyvalue_get_pointer(kv, key, dvalue)
end

"""
    sc_keyvalue_get_int_check(kv, key, status)

Query an integer key with error checking. We check whether the key is not found or it is of the wrong type. A default value to be returned on error can be passed in as *status. If status is NULL, then the result on error is undefined.

### Parameters
* `kv`:\\[in\\] Valid key-value table.
* `key`:\\[in\\] Non-NULL key string.
* `status`:\\[in,out\\] If not NULL, set to 0 if there is no error, 1 if the key is not found, 2 if a value is found but its type is not integer, and return the input value *status on error.
### Returns
On error we return *status if status is not NULL, and else an undefined value backed by an assertion. Without error, return the result of the lookup.
### Prototype
```c
```
"""
function sc_keyvalue_get_int_check(kv, key, status)
end

"""
    sc_keyvalue_set_int(kv, key, newvalue)

Routine to set an integer value for a given key.

### Parameters
* `kv`:\\[in\\] Valid key-value table.
* `key`:\\[in\\] Non-NULL key to insert or replace. If it already exists, it must be of type integer.
* `newvalue`:\\[in\\] New value will be stored under key.
### Prototype
```c
```
"""
function sc_keyvalue_set_int(kv, key, newvalue)
end

"""
    sc_keyvalue_set_double(kv, key, newvalue)

Routine to set a double value for a given key.

### Parameters
* `kv`:\\[in\\] Valid key-value table.
* `key`:\\[in\\] Non-NULL key to insert or replace. If it already exists, it must be of type double.
* `newvalue`:\\[in\\] New value will be stored under key.
### Prototype
```c
```
"""
function sc_keyvalue_set_double(kv, key, newvalue)
end

"""
    sc_keyvalue_set_string(kv, key, newvalue)

Routine to set a string value for a given key.

### Parameters
* `kv`:\\[in\\] Valid key-value table.
* `key`:\\[in\\] Non-NULL key to insert or replace. If it already exists, it must be of type string.
* `newvalue`:\\[in\\] New value will be stored under key.
### Prototype
```c
```
"""
function sc_keyvalue_set_string(kv, key, newvalue)
end

"""
    sc_keyvalue_set_pointer(kv, key, newvalue)

Routine to set a pointer value for a given key.

### Parameters
* `kv`:\\[in\\] Valid key-value table.
* `key`:\\[in\\] Non-NULL key to insert or replace. If it already exists, it must be of type pointer.
* `newvalue`:\\[in\\] New value will be stored under key.
### Prototype
```c
```
"""
function sc_keyvalue_set_pointer(kv, key, newvalue)
end

# typedef int ( * sc_keyvalue_foreach_t ) ( const char * key , const sc_keyvalue_entry_type_t type , void * entry , const void * u )
"""
Function to call on every key value pair

### Parameters
* `key`:\\[in\\] The key for this pair
* `type`:\\[in\\] The type of entry
* `entry`:\\[in\\] Pointer to the entry
* `u`:\\[in\\] Arbitrary user data.
### Returns
Return true if the traversal should continue, false to stop.
"""
const sc_keyvalue_foreach_t = Ptr{Cvoid}

"""
    sc_keyvalue_foreach(kv, fn, user_data)

Iterate through all stored key-value pairs.

### Parameters
* `kv`:\\[in\\] Valid key-value container.
* `fn`:\\[in\\] Function to call on each key-value pair.
* `user_data`:\\[in,out\\] This pointer is passed through to **fn**.
### Prototype
```c
```
"""
function sc_keyvalue_foreach(kv, fn, user_data)
end

"""
    sc_statinfo

Store information of one random variable.

| Field            | Note                                     |
| :--------------- | :--------------------------------------- |
| dirty            | Only update stats if this is true.       |
| count            | Inout; global count is 52 bit accurate.  |
| sum\\_values     | Inout; global sum of values.             |
| sum\\_squares    | Inout; global sum of squares.            |
| min              | Inout; minimum over values.              |
| max              | Inout; maximum over values.              |
| variable         | Name of the variable for output.         |
| variable\\_owned | NULL or deep copy of variable.           |
| group            | Grouping identifier.                     |
| prio             | Priority identifier.                     |
"""
struct sc_statinfo
    dirty::Cint
    count::Clong
    sum_values::Cdouble
    sum_squares::Cdouble
    min::Cdouble
    max::Cdouble
    min_at_rank::Cint
    max_at_rank::Cint
    average::Cdouble
    variance::Cdouble
    standev::Cdouble
    variance_mean::Cdouble
    standev_mean::Cdouble
    variable::Cstring
    variable_owned::Cstring
    group::Cint
    prio::Cint
end

"""Store information of one random variable."""
const sc_statinfo_t = sc_statinfo

"""
    sc_stats_set1(stats, value, variable)

Populate a [`sc_statinfo_t`](@ref) structure assuming count=1 and mark it dirty. We set sc_stats_group_all and sc_stats_prio_all internally.

### Parameters
* `stats`:\\[out\\] Will be filled with count=1 and the value.
* `value`:\\[in\\] Value used to fill statistics information.
* `variable`:\\[in\\] String to be reported by sc_stats_print. This string is assigned by pointer, not copied. Thus, it must stay alive while stats is in use.
### Prototype
```c
void sc_stats_set1 (sc_statinfo_t * stats, double value, const char *variable);
```
"""
function sc_stats_set1(stats, value, variable)
    @ccall libsc.sc_stats_set1(stats::Ptr{sc_statinfo_t}, value::Cdouble, variable::Cstring)::Cvoid
end

"""
    sc_stats_set1_ext(stats, value, variable, copy_variable, stats_group, stats_prio)

Populate a [`sc_statinfo_t`](@ref) structure assuming count=1 and mark it dirty.

### Parameters
* `stats`:\\[out\\] Will be filled with count=1 and the value.
* `value`:\\[in\\] Value used to fill statistics information.
* `variable`:\\[in\\] String to be reported by sc_stats_print.
* `copy_variable`:\\[in\\] If true, make internal copy of variable. Otherwise just assign the pointer.
* `stats_group`:\\[in\\] Non-negative number or sc_stats_group_all.
* `stats_prio`:\\[in\\] Non-negative number or sc_stats_prio_all.
### Prototype
```c
void sc_stats_set1_ext (sc_statinfo_t * stats, double value, const char *variable, int copy_variable, int stats_group, int stats_prio);
```
"""
function sc_stats_set1_ext(stats, value, variable, copy_variable, stats_group, stats_prio)
    @ccall libsc.sc_stats_set1_ext(stats::Ptr{sc_statinfo_t}, value::Cdouble, variable::Cstring, copy_variable::Cint, stats_group::Cint, stats_prio::Cint)::Cvoid
end

"""
    sc_stats_init(stats, variable)

Initialize a [`sc_statinfo_t`](@ref) structure assuming count=0 and mark it dirty. This is useful if *stats* will be used to sc_stats_accumulate instances locally before global statistics are computed. We set sc_stats_group_all and sc_stats_prio_all internally.

### Parameters
* `stats`:\\[out\\] Will be filled with count 0 and values of 0.
* `variable`:\\[in\\] String to be reported by sc_stats_print. This string is assigned by pointer, not copied. Thus, it must stay alive while stats is in use.
### Prototype
```c
void sc_stats_init (sc_statinfo_t * stats, const char *variable);
```
"""
function sc_stats_init(stats, variable)
    @ccall libsc.sc_stats_init(stats::Ptr{sc_statinfo_t}, variable::Cstring)::Cvoid
end

"""
    sc_stats_init_ext(stats, variable, copy_variable, stats_group, stats_prio)

Initialize a [`sc_statinfo_t`](@ref) structure assuming count=0 and mark it dirty. This is useful if *stats* will be used to sc_stats_accumulate instances locally before global statistics are computed.

### Parameters
* `stats`:\\[out\\] Will be filled with count 0 and values of 0.
* `variable`:\\[in\\] String to be reported by sc_stats_print.
* `copy_variable`:\\[in\\] If true, make internal copy of variable. Otherwise just assign the pointer.
* `stats_group`:\\[in\\] Non-negative number or sc_stats_group_all.
* `stats_prio`:\\[in\\] Non-negative number or sc_stats_prio_all. Values increase by importance.
### Prototype
```c
void sc_stats_init_ext (sc_statinfo_t * stats, const char *variable, int copy_variable, int stats_group, int stats_prio);
```
"""
function sc_stats_init_ext(stats, variable, copy_variable, stats_group, stats_prio)
    @ccall libsc.sc_stats_init_ext(stats::Ptr{sc_statinfo_t}, variable::Cstring, copy_variable::Cint, stats_group::Cint, stats_prio::Cint)::Cvoid
end

"""
    sc_stats_reset(stats, reset_vgp)

Reset all values to zero, optionally unassign name, group, and priority.

### Parameters
* `stats`:\\[in,out\\] Variables are zeroed. They can be set again by set1 or accumulate.
* `reset_vgp`:\\[in\\] If true, the variable name string is zeroed and if we did a copy, the copy is freed. If true, group and priority are set to all. If false, we don't touch any of the above.
### Prototype
```c
void sc_stats_reset (sc_statinfo_t * stats, int reset_vgp);
```
"""
function sc_stats_reset(stats, reset_vgp)
    @ccall libsc.sc_stats_reset(stats::Ptr{sc_statinfo_t}, reset_vgp::Cint)::Cvoid
end

"""
    sc_stats_set_group_prio(stats, stats_group, stats_prio)

Set/update the group and priority information for a stats item.

### Parameters
* `stats`:\\[out\\] Only group and stats entries are updated.
* `stats_group`:\\[in\\] Non-negative number or sc_stats_group_all.
* `stats_prio`:\\[in\\] Non-negative number or sc_stats_prio_all. Values increase by importance.
### Prototype
```c
void sc_stats_set_group_prio (sc_statinfo_t * stats, int stats_group, int stats_prio);
```
"""
function sc_stats_set_group_prio(stats, stats_group, stats_prio)
    @ccall libsc.sc_stats_set_group_prio(stats::Ptr{sc_statinfo_t}, stats_group::Cint, stats_prio::Cint)::Cvoid
end

"""
    sc_stats_accumulate(stats, value)

Add an instance of the random variable. The counter of the variable is increased by one. The value is added into the present values of the variable.

### Parameters
* `stats`:\\[out\\] Must be dirty. We bump count and values.
* `value`:\\[in\\] Value used to update statistics information.
### Prototype
```c
void sc_stats_accumulate (sc_statinfo_t * stats, double value);
```
"""
function sc_stats_accumulate(stats, value)
    @ccall libsc.sc_stats_accumulate(stats::Ptr{sc_statinfo_t}, value::Cdouble)::Cvoid
end

"""
    sc_stats_compute(mpicomm, nvars, stats)

### Prototype
```c
void sc_stats_compute (sc_MPI_Comm mpicomm, int nvars, sc_statinfo_t * stats);
```
"""
function sc_stats_compute(mpicomm, nvars, stats)
    @ccall libsc.sc_stats_compute(mpicomm::MPI_Comm, nvars::Cint, stats::Ptr{sc_statinfo_t})::Cvoid
end

"""
    sc_stats_compute1(mpicomm, nvars, stats)

### Prototype
```c
void sc_stats_compute1 (sc_MPI_Comm mpicomm, int nvars, sc_statinfo_t * stats);
```
"""
function sc_stats_compute1(mpicomm, nvars, stats)
    @ccall libsc.sc_stats_compute1(mpicomm::MPI_Comm, nvars::Cint, stats::Ptr{sc_statinfo_t})::Cvoid
end

"""
    sc_stats_print(package_id, log_priority, nvars, stats, full, summary)

Print measured statistics. This function uses the `SC_LC_GLOBAL` log category. That means the default action is to print only on rank 0. Applications can change that by providing a user-defined log handler. All groups and priorities are printed.

### Parameters
* `package_id`:\\[in\\] Registered package id or -1.
* `log_priority`:\\[in\\] Log priority for output according to sc.h.
* `nvars`:\\[in\\] Number of stats items in input array.
* `stats`:\\[in\\] Input array of stats variable items.
* `full`:\\[in\\] Print full information for every variable.
* `summary`:\\[in\\] Print summary information all on 1 line.
### Prototype
```c
void sc_stats_print (int package_id, int log_priority, int nvars, sc_statinfo_t * stats, int full, int summary);
```
"""
function sc_stats_print(package_id, log_priority, nvars, stats, full, summary)
    @ccall libsc.sc_stats_print(package_id::Cint, log_priority::Cint, nvars::Cint, stats::Ptr{sc_statinfo_t}, full::Cint, summary::Cint)::Cvoid
end

"""
    sc_stats_print_ext(package_id, log_priority, nvars, stats, stats_group, stats_prio, full, summary)

Print measured statistics, filter by group and/or priority. This function uses the `SC_LC_GLOBAL` log category. That means the default action is to print only on rank 0. Applications can change that by providing a user-defined log handler.

### Parameters
* `package_id`:\\[in\\] Registered package id or -1.
* `log_priority`:\\[in\\] Log priority for output according to sc.h.
* `nvars`:\\[in\\] Number of stats items in input array.
* `stats`:\\[in\\] Input array of stats variable items.
* `stats_group`:\\[in\\] Print only this group. Non-negative or sc_stats_group_all. We skip printing a variable if neither this parameter nor the item's group is all and if the item's group does not match this.
* `stats_prio`:\\[in\\] Print this and higher priorities. Non-negative or sc_stats_prio_all. We skip printing a variable if neither this parameter nor the item's prio is all and if the item's prio is less than this.
* `full`:\\[in\\] Print full information for every variable. This produces multiple lines including minimum, maximum, and standard deviation. If this is false, print one line per variable.
* `summary`:\\[in\\] Print summary information all on 1 line. This always contains all variables. Not affected by stats\\_group and stats\\_prio.
### Prototype
```c
void sc_stats_print_ext (int package_id, int log_priority, int nvars, sc_statinfo_t * stats, int stats_group, int stats_prio, int full, int summary);
```
"""
function sc_stats_print_ext(package_id, log_priority, nvars, stats, stats_group, stats_prio, full, summary)
    @ccall libsc.sc_stats_print_ext(package_id::Cint, log_priority::Cint, nvars::Cint, stats::Ptr{sc_statinfo_t}, stats_group::Cint, stats_prio::Cint, full::Cint, summary::Cint)::Cvoid
end

"""
    sc_statistics_new(mpicomm)

### Prototype
```c
sc_statistics_t *sc_statistics_new (sc_MPI_Comm mpicomm);
```
"""
function sc_statistics_new(mpicomm)
    @ccall libsc.sc_statistics_new(mpicomm::MPI_Comm)::Ptr{sc_statistics_t}
end

"""
    sc_statistics_destroy(stats)

Destroy a statistics structure.

### Parameters
* `stats`:\\[in,out\\] Valid object is invalidated.
### Prototype
```c
void sc_statistics_destroy (sc_statistics_t * stats);
```
"""
function sc_statistics_destroy(stats)
    @ccall libsc.sc_statistics_destroy(stats::Ptr{sc_statistics_t})::Cvoid
end

"""
    sc_statistics_add(stats, name)

Register a statistics variable by name and set its value to 0. This variable must not exist already.

### Prototype
```c
void sc_statistics_add (sc_statistics_t * stats, const char *name);
```
"""
function sc_statistics_add(stats, name)
    @ccall libsc.sc_statistics_add(stats::Ptr{sc_statistics_t}, name::Cstring)::Cvoid
end

"""
    sc_statistics_set(stats, name, value)

Set the value of a statistics variable, see [`sc_stats_set1`](@ref). The variable must previously be added with [`sc_statistics_add`](@ref). This assumes count=1 as in the [`sc_stats_set1`](@ref) function above.

### Prototype
```c
void sc_statistics_set (sc_statistics_t * stats, const char *name, double value);
```
"""
function sc_statistics_set(stats, name, value)
    @ccall libsc.sc_statistics_set(stats::Ptr{sc_statistics_t}, name::Cstring, value::Cdouble)::Cvoid
end

"""
    sc_statistics_compute(stats)

Compute statistics for all variables, see [`sc_stats_compute`](@ref).

### Prototype
```c
void sc_statistics_compute (sc_statistics_t * stats);
```
"""
function sc_statistics_compute(stats)
    @ccall libsc.sc_statistics_compute(stats::Ptr{sc_statistics_t})::Cvoid
end

"""
    sc_statistics_print(stats, package_id, log_priority, full, summary)

Print all statistics variables, see [`sc_stats_print`](@ref).

### Prototype
```c
void sc_statistics_print (sc_statistics_t * stats, int package_id, int log_priority, int full, int summary);
```
"""
function sc_statistics_print(stats, package_id, log_priority, full, summary)
    @ccall libsc.sc_statistics_print(stats::Ptr{sc_statistics_t}, package_id::Cint, log_priority::Cint, full::Cint, summary::Cint)::Cvoid
end

mutable struct sc_options end

"""The options data structure is opaque."""
const sc_options_t = sc_options

# typedef int ( * sc_options_callback_t ) ( sc_options_t * opt , const char * opt_arg , void * data )
"""
This callback can be invoked with sc_options_parse.

### Parameters
* `opt`:\\[in\\] Valid options data structure. This is passed as a matter of principle.
* `opt_arg`:\\[in\\] The option argument or NULL if there is none. This variable is internal. Do not store pointer.
* `data`:\\[in\\] User-defined data passed to [`sc_options_add_callback`](@ref).
### Returns
Return 0 if successful, -1 to indicate a parse error.
"""
const sc_options_callback_t = Ptr{Cvoid}

"""
    sc_options_new(program_path)

Create an empty options structure.

### Parameters
* `program_path`:\\[in\\] Name or path name of the program to display. Usually argv[0] is fine.
### Returns
A valid and empty options structure.
### Prototype
```c
sc_options_t *sc_options_new (const char *program_path);
```
"""
function sc_options_new(program_path)
    @ccall libsc.sc_options_new(program_path::Cstring)::Ptr{sc_options_t}
end

"""
    sc_options_destroy_deep(opt)

Destroy the options structure and all allocated structures contained. The keyvalue structure passed into sc\\_keyvalue\\_add is destroyed.

\\deprecated This function is kept for backwards compatibility. It is best to destroy any key-value container outside of the lifetime of the options object.

### Parameters
* `opt`:\\[in,out\\] This options structure is deallocated, including all key-value containers referenced.
### Prototype
```c
void sc_options_destroy_deep (sc_options_t * opt);
```
"""
function sc_options_destroy_deep(opt)
    @ccall libsc.sc_options_destroy_deep(opt::Ptr{sc_options_t})::Cvoid
end

"""
    sc_options_destroy(opt)

Destroy the options structure. Whatever has been passed into sc\\_keyvalue\\_add is left alone.

### Parameters
* `opt`:\\[in,out\\] This options structure is deallocated.
### Prototype
```c
void sc_options_destroy (sc_options_t * opt);
```
"""
function sc_options_destroy(opt)
    @ccall libsc.sc_options_destroy(opt::Ptr{sc_options_t})::Cvoid
end

"""
    sc_options_set_spacing(opt, space_type, space_help)

Set the spacing for sc_options_print_summary. There are two values to be set: the spacing from the beginning of the printed line to the type of the option variable, and from the beginning of the printed line to the help string.

### Parameters
* `opt`:\\[in,out\\] Valid options structure.
* `space_type`:\\[in\\] Number of spaces to the type display, for example <INT>, <STRING>, etc. Setting this negative sets the default 20.
* `space_help`:\\[in\\] Number of space to the help string. Setting this negative sets the default 32.
### Prototype
```c
void sc_options_set_spacing (sc_options_t * opt, int space_type, int space_help);
```
"""
function sc_options_set_spacing(opt, space_type, space_help)
    @ccall libsc.sc_options_set_spacing(opt::Ptr{sc_options_t}, space_type::Cint, space_help::Cint)::Cvoid
end

"""
    sc_options_add_switch(opt, opt_char, opt_name, variable, help_string)

Add a switch option. This option is used without option arguments. Every use increments the variable by one. Its initial value is 0. Either opt\\_char or opt\\_name must be valid, that is, not '\\0'/NULL.

### Parameters
* `opt`:\\[in,out\\] A valid options structure.
* `opt_char`:\\[in\\] Short option character, may be '\\0'.
* `opt_name`:\\[in\\] Long option name without initial dashes, may be NULL.
* `variable`:\\[in\\] Address of the variable to store the option value.
* `help_string`:\\[in\\] Help string for usage message, may be NULL.
### Prototype
```c
void sc_options_add_switch (sc_options_t * opt, int opt_char, const char *opt_name, int *variable, const char *help_string);
```
"""
function sc_options_add_switch(opt, opt_char, opt_name, variable, help_string)
    @ccall libsc.sc_options_add_switch(opt::Ptr{sc_options_t}, opt_char::Cint, opt_name::Cstring, variable::Ptr{Cint}, help_string::Cstring)::Cvoid
end

"""
    sc_options_add_bool(opt, opt_char, opt_name, variable, init_value, help_string)

Add a boolean option. It can be initialized to true or false in the C sense. Specifying it on the command line without argument sets the option to true. The argument 0/f/F/n/N sets it to false (0). The argument 1/t/T/y/Y sets it to true (nonzero).

### Parameters
* `opt`:\\[in,out\\] A valid options structure.
* `opt_char`:\\[in\\] Short option character, may be '\\0'.
* `opt_name`:\\[in\\] Long option name without initial dashes, may be NULL.
* `variable`:\\[in\\] Address of the variable to store the option value.
* `init_value`:\\[in\\] Initial value to set the option, read as true or false.
* `help_string`:\\[in\\] Help string for usage message, may be NULL.
### Prototype
```c
void sc_options_add_bool (sc_options_t * opt, int opt_char, const char *opt_name, int *variable, int init_value, const char *help_string);
```
"""
function sc_options_add_bool(opt, opt_char, opt_name, variable, init_value, help_string)
    @ccall libsc.sc_options_add_bool(opt::Ptr{sc_options_t}, opt_char::Cint, opt_name::Cstring, variable::Ptr{Cint}, init_value::Cint, help_string::Cstring)::Cvoid
end

"""
    sc_options_add_int(opt, opt_char, opt_name, variable, init_value, help_string)

Add an option that takes an integer argument.

### Parameters
* `opt`:\\[in,out\\] A valid options structure.
* `opt_char`:\\[in\\] Short option character, may be '\\0'.
* `opt_name`:\\[in\\] Long option name without initial dashes, may be NULL.
* `variable`:\\[in\\] Address of the variable to store the option value.
* `init_value`:\\[in\\] The initial value of the option variable.
* `help_string`:\\[in\\] Help string for usage message, may be NULL.
### Prototype
```c
void sc_options_add_int (sc_options_t * opt, int opt_char, const char *opt_name, int *variable, int init_value, const char *help_string);
```
"""
function sc_options_add_int(opt, opt_char, opt_name, variable, init_value, help_string)
    @ccall libsc.sc_options_add_int(opt::Ptr{sc_options_t}, opt_char::Cint, opt_name::Cstring, variable::Ptr{Cint}, init_value::Cint, help_string::Cstring)::Cvoid
end

"""
    sc_options_add_size_t(opt, opt_char, opt_name, variable, init_value, help_string)

Add an option that takes a size\\_t argument. The value of the size\\_t variable must not be greater than LLONG\\_MAX.

### Parameters
* `opt`:\\[in,out\\] A valid options structure.
* `opt_char`:\\[in\\] Short option character, may be '\\0'.
* `opt_name`:\\[in\\] Long option name without initial dashes, may be NULL.
* `variable`:\\[in\\] Address of the variable to store the option value.
* `init_value`:\\[in\\] The initial value of the option variable.
* `help_string`:\\[in\\] Help string for usage message, may be NULL.
### Prototype
```c
void sc_options_add_size_t (sc_options_t * opt, int opt_char, const char *opt_name, size_t *variable, size_t init_value, const char *help_string);
```
"""
function sc_options_add_size_t(opt, opt_char, opt_name, variable, init_value, help_string)
    @ccall libsc.sc_options_add_size_t(opt::Ptr{sc_options_t}, opt_char::Cint, opt_name::Cstring, variable::Ptr{Csize_t}, init_value::Csize_t, help_string::Cstring)::Cvoid
end

"""
    sc_options_add_double(opt, opt_char, opt_name, variable, init_value, help_string)

Add an option that takes a double argument. The double must be in the legal range. "inf" and "nan" are legal too.

### Parameters
* `opt`:\\[in,out\\] A valid options structure.
* `opt_char`:\\[in\\] Short option character, may be '\\0'.
* `opt_name`:\\[in\\] Long option name without initial dashes, may be NULL.
* `variable`:\\[in\\] Address of the variable to store the option value.
* `init_value`:\\[in\\] The initial value of the option variable.
* `help_string`:\\[in\\] Help string for usage message, may be NULL.
### Prototype
```c
void sc_options_add_double (sc_options_t * opt, int opt_char, const char *opt_name, double *variable, double init_value, const char *help_string);
```
"""
function sc_options_add_double(opt, opt_char, opt_name, variable, init_value, help_string)
    @ccall libsc.sc_options_add_double(opt::Ptr{sc_options_t}, opt_char::Cint, opt_name::Cstring, variable::Ptr{Cdouble}, init_value::Cdouble, help_string::Cstring)::Cvoid
end

"""
    sc_options_add_string(opt, opt_char, opt_name, variable, init_value, help_string)

Add a string option.

### Parameters
* `opt`:\\[in,out\\] A valid options structure.
* `opt_char`:\\[in\\] Short option character, may be '\\0'.
* `opt_name`:\\[in\\] Long option name without initial dashes, may be NULL.
* `variable`:\\[in\\] Address of the variable to store the option value.
* `init_value`:\\[in\\] This default value of the option may be NULL. If not NULL, the value is copied to internal storage.
* `help_string`:\\[in\\] Help string for usage message, may be NULL.
### Prototype
```c
void sc_options_add_string (sc_options_t * opt, int opt_char, const char *opt_name, const char **variable, const char *init_value, const char *help_string);
```
"""
function sc_options_add_string(opt, opt_char, opt_name, variable, init_value, help_string)
    @ccall libsc.sc_options_add_string(opt::Ptr{sc_options_t}, opt_char::Cint, opt_name::Cstring, variable::Ptr{Cstring}, init_value::Cstring, help_string::Cstring)::Cvoid
end

"""
    sc_options_add_inifile(opt, opt_char, opt_name, help_string)

Add an option to read in a file in `.ini` format. The argument to this option must be a filename. On parsing the specified file is read to set known option variables. It does not have an associated option variable itself.

### Parameters
* `opt`:\\[in,out\\] A valid options structure.
* `opt_char`:\\[in\\] Short option character, may be '\\0'.
* `opt_name`:\\[in\\] Long option name without initial dashes, may be NULL.
* `help_string`:\\[in\\] Help string for usage message, may be NULL.
### Prototype
```c
void sc_options_add_inifile (sc_options_t * opt, int opt_char, const char *opt_name, const char *help_string);
```
"""
function sc_options_add_inifile(opt, opt_char, opt_name, help_string)
    @ccall libsc.sc_options_add_inifile(opt::Ptr{sc_options_t}, opt_char::Cint, opt_name::Cstring, help_string::Cstring)::Cvoid
end

"""
    sc_options_add_jsonfile(opt, opt_char, opt_name, help_string)

Add an option to read in a file in JSON format. The argument to this option must be a filename. On parsing the specified file is read to set known option variables. It does not have an associated option variable itself.

This functionality is only active when sc_have_json returns true, equivalent to the define SC\\_HAVE\\_JSON existing, and ignored otherwise.

### Parameters
* `opt`:\\[in,out\\] A valid options structure.
* `opt_char`:\\[in\\] Short option character, may be '\\0'.
* `opt_name`:\\[in\\] Long option name without initial dashes, may be NULL.
* `help_string`:\\[in\\] Help string for usage message, may be NULL.
### Prototype
```c
void sc_options_add_jsonfile (sc_options_t * opt, int opt_char, const char *opt_name, const char *help_string);
```
"""
function sc_options_add_jsonfile(opt, opt_char, opt_name, help_string)
    @ccall libsc.sc_options_add_jsonfile(opt::Ptr{sc_options_t}, opt_char::Cint, opt_name::Cstring, help_string::Cstring)::Cvoid
end

"""
    sc_options_add_callback(opt, opt_char, opt_name, has_arg, fn, data, help_string)

Add an option that calls a user-defined function when parsed. The callback function should be implemented to allow multiple calls. The callback may be used to set multiple option variables in bulk that would otherwise require an inconvenient number of individual options. This option is not loaded from or saved to files.

### Parameters
* `opt`:\\[in,out\\] A valid options structure.
* `opt_char`:\\[in\\] Short option character, may be '\\0'.
* `opt_name`:\\[in\\] Long option name without initial dashes, may be NULL.
* `has_arg`:\\[in\\] Specify whether the option needs an option argument. This can be 0 for none, 1 for a required argument, and 2 for an optional argument; see getopt\\_long (3).
* `fn`:\\[in\\] Function to call when this option is encountered.
* `data`:\\[in\\] User-defined data passed to the callback.
* `help_string`:\\[in\\] Help string for usage message, may be NULL.
### Prototype
```c
void sc_options_add_callback (sc_options_t * opt, int opt_char, const char *opt_name, int has_arg, sc_options_callback_t fn, void *data, const char *help_string);
```
"""
function sc_options_add_callback(opt, opt_char, opt_name, has_arg, fn, data, help_string)
    @ccall libsc.sc_options_add_callback(opt::Ptr{sc_options_t}, opt_char::Cint, opt_name::Cstring, has_arg::Cint, fn::sc_options_callback_t, data::Ptr{Cvoid}, help_string::Cstring)::Cvoid
end

"""
    sc_options_add_keyvalue(opt, opt_char, opt_name, variable, init_value, keyvalue, help_string)

Add an option that takes string keys into a lookup table of integers. On calling this function, it must be certain that the initial value exists.

### Parameters
* `opt`:\\[in\\] Initialized options structure.
* `opt_char`:\\[in\\] Option character for command line, or 0.
* `opt_name`:\\[in\\] Name of the long option, or NULL.
* `variable`:\\[in\\] Address of an existing integer that holds the value of this option parameter.
* `init_value`:\\[in\\] The key that is looked up for the initial value. It must be certain that the key exists and its value is of type integer.
* `keyvalue`:\\[in\\] A valid key-value structure where the values must be integers. If a key is asked for that does not exist, we will produce an option error. This structure must stay alive as long as opt.
* `help_string`:\\[in\\] Instructive one-line string to explain the option.
### Prototype
```c
```
"""
function sc_options_add_keyvalue(opt, opt_char, opt_name, variable, init_value, keyvalue, help_string)
end

"""
    sc_options_add_suboptions(opt, subopt, prefix)

Copy one set of options to another as a subset, with a prefix. The variables referenced by the options and the suboptions are the same.

### Parameters
* `opt`:\\[in,out\\] A set of options.
* `subopt`:\\[in\\] Another set of options to be copied.
* `prefix`:\\[in\\] The prefix to add to option names as they are copied. If an option has a long name "name" in subopt, its name in opt is "prefix:name"; if an option only has a character 'c' in subopt, its name in opt is "prefix:-c".
### Prototype
```c
void sc_options_add_suboptions (sc_options_t * opt, sc_options_t * subopt, const char *prefix);
```
"""
function sc_options_add_suboptions(opt, subopt, prefix)
    @ccall libsc.sc_options_add_suboptions(opt::Ptr{sc_options_t}, subopt::Ptr{sc_options_t}, prefix::Cstring)::Cvoid
end

"""
    sc_options_print_usage(package_id, log_priority, opt, arg_usage)

Print a usage message. This function uses the `SC_LC_GLOBAL` log category. That means the default action is to print only on rank 0. Applications can change that by providing a user-defined log handler.

### Parameters
* `package_id`:\\[in\\] Registered package id or -1.
* `log_priority`:\\[in\\] Priority for output according to sc_logprios.
* `opt`:\\[in\\] The option structure.
* `arg_usage`:\\[in\\] If not NULL, an <ARGUMENTS> string is appended to the usage line. If the string is non-empty, it will be printed after the option summary and an "ARGUMENTS:\\n" title line. Line breaks are identified by strtok(3) and honored.
### Prototype
```c
void sc_options_print_usage (int package_id, int log_priority, sc_options_t * opt, const char *arg_usage);
```
"""
function sc_options_print_usage(package_id, log_priority, opt, arg_usage)
    @ccall libsc.sc_options_print_usage(package_id::Cint, log_priority::Cint, opt::Ptr{sc_options_t}, arg_usage::Cstring)::Cvoid
end

"""
    sc_options_print_summary(package_id, log_priority, opt)

Print a summary of all option values. Prints the title "Options:" and a line for every option, then the title "Arguments:" and a line for every argument. This function uses the `SC_LC_GLOBAL` log category. That means the default action is to print only on rank 0. Applications can change that by providing a user-defined log handler.

### Parameters
* `package_id`:\\[in\\] Registered package id or -1.
* `log_priority`:\\[in\\] Priority for output according to sc_logprios.
* `opt`:\\[in\\] The option structure.
### Prototype
```c
void sc_options_print_summary (int package_id, int log_priority, sc_options_t * opt);
```
"""
function sc_options_print_summary(package_id, log_priority, opt)
    @ccall libsc.sc_options_print_summary(package_id::Cint, log_priority::Cint, opt::Ptr{sc_options_t})::Cvoid
end

"""
    sc_options_load(package_id, err_priority, opt, file)

Load a file in the default format and update option values. The default is a file in the `.ini` format; see sc_options_load_ini.

### Parameters
* `package_id`:\\[in\\] Registered package id or -1.
* `err_priority`:\\[in\\] Error priority according to sc_logprios.
* `opt`:\\[in\\] The option structure.
* `file`:\\[in\\] Filename of the file to load.
### Returns
Returns 0 on success, -1 on failure.
### Prototype
```c
int sc_options_load (int package_id, int err_priority, sc_options_t * opt, const char *file);
```
"""
function sc_options_load(package_id, err_priority, opt, file)
    @ccall libsc.sc_options_load(package_id::Cint, err_priority::Cint, opt::Ptr{sc_options_t}, file::Cstring)::Cint
end

"""
    sc_options_load_ini(package_id, err_priority, opt, inifile, re)

Load a file in `.ini` format and update entries found under [Options]. An option whose name contains a colon such as "prefix:basename" will be updated by a "basename =" entry in a [prefix] section.

### Parameters
* `package_id`:\\[in\\] Registered package id or -1.
* `err_priority`:\\[in\\] Error priority according to sc_logprios.
* `opt`:\\[in\\] The option structure.
* `inifile`:\\[in\\] Filename of the ini file to load.
* `re`:\\[in,out\\] Provisioned for runtime error checking implementation; currently must be NULL.
### Returns
Returns 0 on success, -1 on failure.
### Prototype
```c
int sc_options_load_ini (int package_id, int err_priority, sc_options_t * opt, const char *inifile, void *re);
```
"""
function sc_options_load_ini(package_id, err_priority, opt, inifile, re)
    @ccall libsc.sc_options_load_ini(package_id::Cint, err_priority::Cint, opt::Ptr{sc_options_t}, inifile::Cstring, re::Ptr{Cvoid})::Cint
end

"""
    sc_options_load_json(package_id, err_priority, opt, jsonfile, re)

Load a file in JSON format and update entries from object "Options". An option whose name contains a colon such as "Prefix:basename" will be updated by a "basename :" entry in a "Prefix" nested object.

### Parameters
* `package_id`:\\[in\\] Registered package id or -1.
* `err_priority`:\\[in\\] Error priority according to sc_logprios.
* `opt`:\\[in\\] The option structure.
* `jsonfile`:\\[in\\] Filename of the JSON file to load.
* `re`:\\[in,out\\] Provisioned for runtime error checking implementation; currently must be NULL.
### Returns
Returns 0 on success, -1 on failure.
### Prototype
```c
int sc_options_load_json (int package_id, int err_priority, sc_options_t * opt, const char *jsonfile, void *re);
```
"""
function sc_options_load_json(package_id, err_priority, opt, jsonfile, re)
    @ccall libsc.sc_options_load_json(package_id::Cint, err_priority::Cint, opt::Ptr{sc_options_t}, jsonfile::Cstring, re::Ptr{Cvoid})::Cint
end

"""
    sc_options_save(package_id, err_priority, opt, inifile)

Save all options and arguments to a file in `.ini` format. This function must only be called after successful option parsing. This function should only be called on rank 0. This function will log errors with category `SC_LC_GLOBAL`. An options whose name contains a colon such as "Prefix:basename" will be written in a section titled [Prefix] as "basename =".

### Parameters
* `package_id`:\\[in\\] Registered package id or -1.
* `err_priority`:\\[in\\] Error priority according to sc_logprios.
* `opt`:\\[in\\] The option structure.
* `inifile`:\\[in\\] Filename of the ini file to save.
### Returns
Returns 0 on success, -1 on failure.
### Prototype
```c
int sc_options_save (int package_id, int err_priority, sc_options_t * opt, const char *inifile);
```
"""
function sc_options_save(package_id, err_priority, opt, inifile)
    @ccall libsc.sc_options_save(package_id::Cint, err_priority::Cint, opt::Ptr{sc_options_t}, inifile::Cstring)::Cint
end

"""
    sc_options_load_args(package_id, err_priority, opt, inifile)

Load a file in `.ini` format and update entries found under [Arguments]. There needs to be a key Arguments.count specifying the number. Then as many integer keys starting with 0 need to be present.

### Parameters
* `package_id`:\\[in\\] Registered package id or -1.
* `err_priority`:\\[in\\] Error priority according to sc_logprios.
* `opt`:\\[in\\] The args are stored in this option structure.
* `inifile`:\\[in\\] Filename of the ini file to load.
### Returns
Returns 0 on success, -1 on failure.
### Prototype
```c
int sc_options_load_args (int package_id, int err_priority, sc_options_t * opt, const char *inifile);
```
"""
function sc_options_load_args(package_id, err_priority, opt, inifile)
    @ccall libsc.sc_options_load_args(package_id::Cint, err_priority::Cint, opt::Ptr{sc_options_t}, inifile::Cstring)::Cint
end

"""
    sc_options_parse(package_id, err_priority, opt, argc, argv)

Parse command line options.

### Parameters
* `package_id`:\\[in\\] Registered package id or -1.
* `err_priority`:\\[in\\] Error priority according to sc_logprios.
* `opt`:\\[in\\] The option structure.
* `argc`:\\[in\\] Length of argument list.
* `argv`:\\[in,out\\] Argument list may be permuted.
### Returns
Returns -1 on an invalid option, otherwise the position of the first non-option argument.
### Prototype
```c
int sc_options_parse (int package_id, int err_priority, sc_options_t * opt, int argc, char **argv);
```
"""
function sc_options_parse(package_id, err_priority, opt, argc, argv)
    @ccall libsc.sc_options_parse(package_id::Cint, err_priority::Cint, opt::Ptr{sc_options_t}, argc::Cint, argv::Ptr{Cstring})::Cint
end

"""
    t8_cmesh_from_tetgen_file(fileprefix, partition, comm, do_dup)

### Prototype
```c
t8_cmesh_t t8_cmesh_from_tetgen_file (char *fileprefix, int partition, sc_MPI_Comm comm, int do_dup);
```
"""
function t8_cmesh_from_tetgen_file(fileprefix, partition, comm, do_dup)
    @ccall libt8.t8_cmesh_from_tetgen_file(fileprefix::Cstring, partition::Cint, comm::MPI_Comm, do_dup::Cint)::t8_cmesh_t
end

"""
    t8_cmesh_from_tetgen_file_time(fileprefix, partition, comm, do_dup, fi, snapshot, stats, statentry)

### Prototype
```c
t8_cmesh_t t8_cmesh_from_tetgen_file_time (char *fileprefix, int partition, sc_MPI_Comm comm, int do_dup, sc_flopinfo_t * fi, sc_flopinfo_t * snapshot, sc_statinfo_t * stats, int statentry);
```
"""
function t8_cmesh_from_tetgen_file_time(fileprefix, partition, comm, do_dup, fi, snapshot, stats, statentry)
    @ccall libt8.t8_cmesh_from_tetgen_file_time(fileprefix::Cstring, partition::Cint, comm::MPI_Comm, do_dup::Cint, fi::Ptr{sc_flopinfo_t}, snapshot::Ptr{sc_flopinfo_t}, stats::Ptr{sc_statinfo_t}, statentry::Cint)::t8_cmesh_t
end

"""
    t8_cmesh_from_triangle_file(fileprefix, partition, comm, do_dup)

### Prototype
```c
t8_cmesh_t t8_cmesh_from_triangle_file (char *fileprefix, int partition, sc_MPI_Comm comm, int do_dup);
```
"""
function t8_cmesh_from_triangle_file(fileprefix, partition, comm, do_dup)
    @ccall libt8.t8_cmesh_from_triangle_file(fileprefix::Cstring, partition::Cint, comm::MPI_Comm, do_dup::Cint)::t8_cmesh_t
end

"""
    t8_cmesh_vtk_write_file(cmesh, fileprefix, scale)

### Prototype
```c
int t8_cmesh_vtk_write_file (t8_cmesh_t cmesh, const char *fileprefix, double scale);
```
"""
function t8_cmesh_vtk_write_file(cmesh, fileprefix, scale)
    @ccall libt8.t8_cmesh_vtk_write_file(cmesh::t8_cmesh_t, fileprefix::Cstring, scale::Cdouble)::Cint
end

"""
    t8_cmesh_set_tree_vertices(cmesh, ltree_id, vertices, num_vertices)

Set the vertex coordinates of a tree in the cmesh. This is currently inefficient, since the vertices are duplicated for each tree. Eventually this function will be replaced by a more efficient one. It is not allowed to call this function after t8_cmesh_commit. The eclass of the tree has to be set before calling this function.

### Parameters
* `cmesh`:\\[in,out\\] The cmesh to be updated.
* `ltree_id`:\\[in\\] The local number of the tree.
* `vertices`:\\[in\\] An array of 3 doubles per tree vertex.
* `num_vertices`:\\[in\\] The number of verticess in *vertices*. Must match the number of corners of the tree.
### Prototype
```c
void t8_cmesh_set_tree_vertices (t8_cmesh_t cmesh, t8_locidx_t ltree_id, double *vertices, int num_vertices);
```
"""
function t8_cmesh_set_tree_vertices(cmesh, ltree_id, vertices, num_vertices)
    @ccall libt8.t8_cmesh_set_tree_vertices(cmesh::t8_cmesh_t, ltree_id::t8_locidx_t, vertices::Ptr{Cdouble}, num_vertices::Cint)::Cvoid
end

"""
    t8_eclass_count_boundary(theclass, min_dim, per_eclass)

Query the element class and count of boundary points.

### Parameters
* `theclass`:\\[in\\] We query a point of this element class.
* `min_dim`:\\[in\\] Ignore boundary points of lesser dimension. The ignored points get a count value of 0.
* `per_eclass`:\\[out\\] Array of length T8\\_ECLASS\\_COUNT to be filled with the count of the boundary objects, counted per each of the element classes.
### Returns
The count over all boundary points.
### Prototype
```c
int t8_eclass_count_boundary (t8_eclass_t theclass, int min_dim, int *per_eclass);
```
"""
function t8_eclass_count_boundary(theclass, min_dim, per_eclass)
    @ccall libt8.t8_eclass_count_boundary(theclass::t8_eclass_t, min_dim::Cint, per_eclass::Ptr{Cint})::Cint
end

"""
    t8_eclass_compare(eclass1, eclass2)

Compare two eclasses of the same dimension as necessary for face neighbor orientation. The implemented order is Triangle < Square in 2D and Tet < Hex < Prism < Pyramid in 3D.

### Parameters
* `eclass1`:\\[in\\] The first eclass to compare.
* `eclass2`:\\[in\\] The second eclass to compare.
### Returns
0 if the eclasses are equal, 1 if eclass1 > eclass2 and -1 if eclass1 < eclass2
### Prototype
```c
int t8_eclass_compare (t8_eclass_t eclass1, t8_eclass_t eclass2);
```
"""
function t8_eclass_compare(eclass1, eclass2)
    @ccall libt8.t8_eclass_compare(eclass1::t8_eclass_t, eclass2::t8_eclass_t)::Cint
end

"""
    t8_eclass_is_valid(eclass)

Check whether a class is a valid class. Returns non-zero if it is a valid class, returns zero, if the class is equal to T8\\_ECLASS\\_INVALID.

### Parameters
* `eclass`:\\[in\\] The eclass to check.
### Returns
Non-zero if *eclass* is valid, zero otherwise.
### Prototype
```c
int t8_eclass_is_valid (t8_eclass_t eclass);
```
"""
function t8_eclass_is_valid(eclass)
    @ccall libt8.t8_eclass_is_valid(eclass::t8_eclass_t)::Cint
end

mutable struct t8_element end

"""Opaque structure for a generic element, only used as pointer. Implementations are free to cast it to their internal data structure."""
const t8_element_t = t8_element

"""
    t8_scheme_cxx_ref(scheme)

Increase the reference counter of a scheme.

### Parameters
* `scheme`:\\[in,out\\] On input, this scheme must be alive, that is, exist with positive reference count.
### Prototype
```c
void t8_scheme_cxx_ref (t8_scheme_cxx_t *scheme);
```
"""
function t8_scheme_cxx_ref(scheme)
    @ccall libt8.t8_scheme_cxx_ref(scheme::Ptr{t8_scheme_cxx_t})::Cvoid
end

"""
    t8_scheme_cxx_unref(pscheme)

Decrease the reference counter of a scheme. If the counter reaches zero, this scheme is destroyed.

### Parameters
* `pscheme`:\\[in,out\\] On input, the scheme pointed to must exist with positive reference count. If the reference count reaches zero, the scheme is destroyed and this pointer set to NULL. Otherwise, the pointer is not changed and the scheme is not modified in other ways.
### Prototype
```c
void t8_scheme_cxx_unref (t8_scheme_cxx_t **pscheme);
```
"""
function t8_scheme_cxx_unref(pscheme)
    @ccall libt8.t8_scheme_cxx_unref(pscheme::Ptr{Ptr{t8_scheme_cxx_t}})::Cvoid
end

"""
    t8_scheme_cxx_destroy(s)

### Prototype
```c
extern void t8_scheme_cxx_destroy (t8_scheme_cxx_t *s);
```
"""
function t8_scheme_cxx_destroy(s)
    @ccall libt8.t8_scheme_cxx_destroy(s::Ptr{t8_scheme_cxx_t})::Cvoid
end

"""
    t8_element_size(ts)

Return the size of any element of a given class.

### Returns
The size of an element of class **ts**. We provide a default implementation of this routine that should suffice for most use cases.
### Prototype
```c
size_t t8_element_size (const t8_eclass_scheme_c *ts);
```
"""
function t8_element_size(ts)
    @ccall libt8.t8_element_size(ts::Ptr{t8_eclass_scheme_c})::Csize_t
end

"""
    t8_element_refines_irregular(ts)

Returns true, if there is one element in the tree, that does not refine into 2^dim children. Returns false otherwise.

### Prototype
```c
int t8_element_refines_irregular (const t8_eclass_scheme_c *ts);
```
"""
function t8_element_refines_irregular(ts)
    @ccall libt8.t8_element_refines_irregular(ts::Ptr{t8_eclass_scheme_c})::Cint
end

"""
    t8_element_maxlevel(ts)

Return the maximum allowed level for any element of a given class.

### Parameters
* `ts`:\\[in\\] Implementation of a class scheme.
### Returns
The maximum allowed level for elements of class **ts**.
### Prototype
```c
int t8_element_maxlevel (const t8_eclass_scheme_c *ts);
```
"""
function t8_element_maxlevel(ts)
    @ccall libt8.t8_element_maxlevel(ts::Ptr{t8_eclass_scheme_c})::Cint
end

"""
    t8_element_child_eclass(ts, childid)

Return the type of each child in the ordering of the implementation.

### Parameters
* `ts`:\\[in\\] Implementation of a class scheme.
* `childid`:\\[in\\] Must be between 0 and the number of children (exclusive). The number of children is defined in [`t8_element_num_children`](@ref).
### Returns
The type for the given child.
### Prototype
```c
t8_eclass_t t8_element_child_eclass (const t8_eclass_scheme_c *ts, int childid);
```
"""
function t8_element_child_eclass(ts, childid)
    @ccall libt8.t8_element_child_eclass(ts::Ptr{t8_eclass_scheme_c}, childid::Cint)::t8_eclass_t
end

"""
    t8_element_level(ts, elem)

Return the level of a particular element.

### Parameters
* `ts`:\\[in\\] Implementation of a class scheme.
* `elem`:\\[in\\] The element whose level should be returned.
### Returns
The level of **elem**.
### Prototype
```c
int t8_element_level (const t8_eclass_scheme_c *ts, const t8_element_t *elem);
```
"""
function t8_element_level(ts, elem)
    @ccall libt8.t8_element_level(ts::Ptr{t8_eclass_scheme_c}, elem::Ptr{t8_element_t})::Cint
end

"""
    t8_element_copy(ts, source, dest)

Copy all entries of **source** to **dest**. **dest** must be an existing element. No memory is allocated by this function.

!!! note

    *source* and *dest* may point to the same element.

### Parameters
* `ts`:\\[in\\] Implementation of a class scheme.
* `source`:\\[in\\] The element whose entries will be copied to **dest**.
* `dest`:\\[in,out\\] This element's entries will be overwritted with the entries of **source**.
### Prototype
```c
void t8_element_copy (const t8_eclass_scheme_c *ts, const t8_element_t *source, t8_element_t *dest);
```
"""
function t8_element_copy(ts, source, dest)
    @ccall libt8.t8_element_copy(ts::Ptr{t8_eclass_scheme_c}, source::Ptr{t8_element_t}, dest::Ptr{t8_element_t})::Cvoid
end

"""
    t8_element_compare(ts, elem1, elem2)

Compare two elements.

### Parameters
* `ts`:\\[in\\] Implementation of a class scheme.
* `elem1`:\\[in\\] The first element.
* `elem2`:\\[in\\] The second element.
### Returns
negativ if elem1 < elem2, zero if elem1 equals elem2 and positiv if elem1 > elem2. If elem2 is a copy of elem1 then the elements are equal.
### Prototype
```c
int t8_element_compare (const t8_eclass_scheme_c *ts, const t8_element_t *elem1, const t8_element_t *elem2);
```
"""
function t8_element_compare(ts, elem1, elem2)
    @ccall libt8.t8_element_compare(ts::Ptr{t8_eclass_scheme_c}, elem1::Ptr{t8_element_t}, elem2::Ptr{t8_element_t})::Cint
end

"""
    t8_element_parent(ts, elem, parent)

Compute the parent of a given element **elem** and store it in **parent**. **parent** needs to be an existing element. No memory is allocated by this function. **elem** and **parent** can point to the same element, then the entries of **elem** are overwritten by the ones of its parent.

### Parameters
* `ts`:\\[in\\] Implementation of a class scheme.
* `elem`:\\[in\\] The element whose parent will be computed.
* `parent`:\\[in,out\\] This element's entries will be overwritten by those of **elem**'s parent. The storage for this element must exist and match the element class of the parent.
### Prototype
```c
void t8_element_parent (const t8_eclass_scheme_c *ts, const t8_element_t *elem, t8_element_t *parent);
```
"""
function t8_element_parent(ts, elem, parent)
    @ccall libt8.t8_element_parent(ts::Ptr{t8_eclass_scheme_c}, elem::Ptr{t8_element_t}, parent::Ptr{t8_element_t})::Cvoid
end

"""
    t8_element_num_siblings(ts, elem)

Compute the number of siblings of an element. That is the number of  Children of its parent.

### Parameters
* `ts`:\\[in\\] Implementation of a class scheme.
* `elem`:\\[in\\] The element.
### Returns
The number of siblings of *element*. Note that this number is >= 1, since we count the element itself as a sibling.
### Prototype
```c
int t8_element_num_siblings (const t8_eclass_scheme_c *ts, const t8_element_t *elem);
```
"""
function t8_element_num_siblings(ts, elem)
    @ccall libt8.t8_element_num_siblings(ts::Ptr{t8_eclass_scheme_c}, elem::Ptr{t8_element_t})::Cint
end

"""
    t8_element_sibling(ts, elem, sibid, sibling)

Compute a specific sibling of a given element **elem** and store it in **sibling**. **sibling** needs to be an existing element. No memory is allocated by this function. **elem** and **sibling** can point to the same element, then the entries of **elem** are overwritten by the ones of its i-th sibling.

### Parameters
* `ts`:\\[in\\] Implementation of a class scheme.
* `elem`:\\[in\\] The element whose sibling will be computed.
* `sibid`:\\[in\\] The id of the sibling computed.
* `sibling`:\\[in,out\\] This element's entries will be overwritten by those of **elem**'s sibid-th sibling. The storage for this element must exist and match the element class of the sibling.
### Prototype
```c
void t8_element_sibling (const t8_eclass_scheme_c *ts, const t8_element_t *elem, int sibid, t8_element_t *sibling);
```
"""
function t8_element_sibling(ts, elem, sibid, sibling)
    @ccall libt8.t8_element_sibling(ts::Ptr{t8_eclass_scheme_c}, elem::Ptr{t8_element_t}, sibid::Cint, sibling::Ptr{t8_element_t})::Cvoid
end

"""
    t8_element_num_corners(ts, elem)

Compute the number of corners of an element.

### Parameters
* `ts`:\\[in\\] Implementation of a class scheme.
* `elem`:\\[in\\] The element.
### Returns
The number of corners of *element*.
### Prototype
```c
int t8_element_num_corners (const t8_eclass_scheme_c *ts, const t8_element_t *elem);
```
"""
function t8_element_num_corners(ts, elem)
    @ccall libt8.t8_element_num_corners(ts::Ptr{t8_eclass_scheme_c}, elem::Ptr{t8_element_t})::Cint
end

"""
    t8_element_num_faces(ts, elem)

Compute the number of faces of an element.

### Parameters
* `ts`:\\[in\\] Implementation of a class scheme.
* `elem`:\\[in\\] The element.
### Returns
The number of faces of *element*.
### Prototype
```c
int t8_element_num_faces (const t8_eclass_scheme_c *ts, const t8_element_t *elem);
```
"""
function t8_element_num_faces(ts, elem)
    @ccall libt8.t8_element_num_faces(ts::Ptr{t8_eclass_scheme_c}, elem::Ptr{t8_element_t})::Cint
end

"""
    t8_element_max_num_faces(ts, elem)

Compute the maximum number of faces of a given element and all of its descendants.

### Parameters
* `ts`:\\[in\\] Implementation of a class scheme.
* `elem`:\\[in\\] The element.
### Returns
The number of faces of *element*.
### Prototype
```c
int t8_element_max_num_faces (const t8_eclass_scheme_c *ts, const t8_element_t *elem);
```
"""
function t8_element_max_num_faces(ts, elem)
    @ccall libt8.t8_element_max_num_faces(ts::Ptr{t8_eclass_scheme_c}, elem::Ptr{t8_element_t})::Cint
end

"""
    t8_element_num_children(ts, elem)

Compute the number of children of an element when it is refined.

### Parameters
* `ts`:\\[in\\] Implementation of a class scheme.
* `elem`:\\[in\\] The element.
### Returns
The number of children of *element*.
### Prototype
```c
int t8_element_num_children (const t8_eclass_scheme_c *ts, const t8_element_t *elem);
```
"""
function t8_element_num_children(ts, elem)
    @ccall libt8.t8_element_num_children(ts::Ptr{t8_eclass_scheme_c}, elem::Ptr{t8_element_t})::Cint
end

"""
    t8_element_num_face_children(ts, elem, face)

Compute the number of children of an element's face when the element is refined.

### Parameters
* `ts`:\\[in\\] Implementation of a class scheme.
* `elem`:\\[in\\] The element.
* `face`:\\[in\\] A face of *elem*.
### Returns
The number of children of *face* if *elem* is to be refined.
### Prototype
```c
int t8_element_num_face_children (const t8_eclass_scheme_c *ts, const t8_element_t *elem, int face);
```
"""
function t8_element_num_face_children(ts, elem, face)
    @ccall libt8.t8_element_num_face_children(ts::Ptr{t8_eclass_scheme_c}, elem::Ptr{t8_element_t}, face::Cint)::Cint
end

"""
    t8_element_get_face_corner(ts, elem, face, corner)

Return the corner number of an element's face corner. Example quad: 2 x --- x 3 | | | | face 1 0 x --- x 1 Thus for face = 1 the output is: corner=0 : 1, corner=1: 3

The order in which the corners must be given is determined by the eclass of *element*: LINE/QUAD/TRIANGLE: No specific order. HEX : In Z-order of the face starting with the lowest corner number. TET : Starting with the lowest corner number counterclockwise as seen from 'outside' of the element.

### Parameters
* `ts`:\\[in\\] Implementation of a class scheme.
* `element`:\\[in\\] The element.
* `face`:\\[in\\] A face index for *element*.
* `corner`:\\[in\\] A corner index for the face 0 <= *corner* < num\\_face\\_corners.
### Returns
The corner number of the *corner*-th vertex of *face*.
### Prototype
```c
int t8_element_get_face_corner (const t8_eclass_scheme_c *ts, const t8_element_t *elem, int face, int corner);
```
"""
function t8_element_get_face_corner(ts, elem, face, corner)
    @ccall libt8.t8_element_get_face_corner(ts::Ptr{t8_eclass_scheme_c}, elem::Ptr{t8_element_t}, face::Cint, corner::Cint)::Cint
end

"""
    t8_element_get_corner_face(ts, elem, corner, face)

Compute the face numbers of the faces sharing an element's corner. Example quad: 2 x --- x 3 | | | | face 1 0 x --- x 1 face 2 Thus for corner = 1 the output is: face=0 : 2, face=1: 1

### Parameters
* `ts`:\\[in\\] Implementation of a class scheme.
* `element`:\\[in\\] The element.
* `corner`:\\[in\\] A corner index for the face.
* `face`:\\[in\\] A face index for *corner*.
### Returns
The face number of the *face*-th face at *corner*.
### Prototype
```c
int t8_element_get_corner_face (const t8_eclass_scheme_c *ts, const t8_element_t *elem, int corner, int face);
```
"""
function t8_element_get_corner_face(ts, elem, corner, face)
    @ccall libt8.t8_element_get_corner_face(ts::Ptr{t8_eclass_scheme_c}, elem::Ptr{t8_element_t}, corner::Cint, face::Cint)::Cint
end

"""
    t8_element_child(ts, elem, childid, child)

Construct the child element of a given number.

### Parameters
* `ts`:\\[in\\] Implementation of a class scheme.
* `elem`:\\[in\\] This must be a valid element, bigger than maxlevel.
* `childid`:\\[in\\] The number of the child to construct.
* `child`:\\[in,out\\] The storage for this element must exist and match the element class of the child. For a pyramid, for example, it may be either a tetrahedron or a pyramid depending on *childid*. This can be checked by [`t8_element_child_eclass`](@ref). On output, a valid element. It is valid to call this function with elem = child.
### See also
[`t8_element_child_eclass`](@ref)

### Prototype
```c
void t8_element_child (const t8_eclass_scheme_c *ts, const t8_element_t *elem, int childid, t8_element_t *child);
```
"""
function t8_element_child(ts, elem, childid, child)
    @ccall libt8.t8_element_child(ts::Ptr{t8_eclass_scheme_c}, elem::Ptr{t8_element_t}, childid::Cint, child::Ptr{t8_element_t})::Cvoid
end

"""
    t8_element_children(ts, elem, length, c)

Construct all children of a given element.

### Parameters
* `ts`:\\[in\\] Implementation of a class scheme.
* `elem`:\\[in\\] This must be a valid element, bigger than maxlevel.
* `length`:\\[in\\] The length of the output array *c* must match the number of children.
* `c`:\\[in,out\\] The storage for these *length* elements must exist and match the element class in the children's ordering. On output, all children are valid. It is valid to call this function with elem = c[0].
### See also
[`t8_element_num_children`](@ref), [`t8_element_child_eclass`](@ref)

### Prototype
```c
void t8_element_children (const t8_eclass_scheme_c *ts, const t8_element_t *elem, int length, t8_element_t *c[]);
```
"""
function t8_element_children(ts, elem, length, c)
    @ccall libt8.t8_element_children(ts::Ptr{t8_eclass_scheme_c}, elem::Ptr{t8_element_t}, length::Cint, c::Ptr{Ptr{t8_element_t}})::Cvoid
end

"""
    t8_element_child_id(ts, elem)

Compute the child id of an element.

### Parameters
* `ts`:\\[in\\] Implementation of a class scheme.
* `elem`:\\[in\\] This must be a valid element.
### Returns
The child id of elem.
### Prototype
```c
int t8_element_child_id (const t8_eclass_scheme_c *ts, const t8_element_t *elem);
```
"""
function t8_element_child_id(ts, elem)
    @ccall libt8.t8_element_child_id(ts::Ptr{t8_eclass_scheme_c}, elem::Ptr{t8_element_t})::Cint
end

"""
    t8_element_ancestor_id(ts, elem, level)

Compute the ancestor id of an element, that is the child id at a given level.

### Parameters
* `ts`:\\[in\\] Implementation of a class scheme.
* `elem`:\\[in\\] This must be a valid element.
* `level`:\\[in\\] A refinement level. Must satisfy *level* < elem.level
### Returns
The child\\_id of *elem* in regard to its *level* ancestor.
### Prototype
```c
int t8_element_ancestor_id (const t8_eclass_scheme_c *ts, const t8_element_t *elem, int level);
```
"""
function t8_element_ancestor_id(ts, elem, level)
    @ccall libt8.t8_element_ancestor_id(ts::Ptr{t8_eclass_scheme_c}, elem::Ptr{t8_element_t}, level::Cint)::Cint
end

"""
    t8_element_is_family(ts, fam)

Query whether a given set of elements is a family or not.

### Parameters
* `ts`:\\[in\\] Implementation of a class scheme.
* `fam`:\\[in\\] An array of as many elements as an element of class **ts** has children.
### Returns
Zero if **fam** is not a family, nonzero if it is.
### Prototype
```c
int t8_element_is_family (const t8_eclass_scheme_c *ts, t8_element_t **fam);
```
"""
function t8_element_is_family(ts, fam)
    @ccall libt8.t8_element_is_family(ts::Ptr{t8_eclass_scheme_c}, fam::Ptr{Ptr{t8_element_t}})::Cint
end

"""
    t8_element_nca(ts, elem1, elem2, nca)

Compute the nearest common ancestor of two elements. That is, the element with highest level that still has both given elements as descendants.

### Parameters
* `ts`:\\[in\\] Implementation of a class scheme.
* `elem1`:\\[in\\] The first of the two input elements.
* `elem2`:\\[in\\] The second of the two input elements.
* `nca`:\\[in,out\\] The storage for this element must exist and match the element class of the child. On output the unique nearest common ancestor of **elem1** and **elem2**.
### Prototype
```c
void t8_element_nca (const t8_eclass_scheme_c *ts, const t8_element_t *elem1, const t8_element_t *elem2, t8_element_t *nca);
```
"""
function t8_element_nca(ts, elem1, elem2, nca)
    @ccall libt8.t8_element_nca(ts::Ptr{t8_eclass_scheme_c}, elem1::Ptr{t8_element_t}, elem2::Ptr{t8_element_t}, nca::Ptr{t8_element_t})::Cvoid
end

"""Type definition for the geometric shape of an element. Currently the possible shapes are the same as the possible element classes. I.e. T8\\_ECLASS\\_VERTEX, T8\\_ECLASS\\_TET, etc..."""
const t8_element_shape_t = t8_eclass_t

"""
    t8_element_face_shape(ts, elem, face)

Compute the shape of the face of an element.

### Parameters
* `ts`:\\[in\\] Implementation of a class scheme.
* `elem`:\\[in\\] The element.
* `face`:\\[in\\] A face of *elem*.
### Returns
The element shape of the face. I.e. T8\\_ECLASS\\_LINE for quads, T8\\_ECLASS\\_TRIANGLE for tets and depending on the face number either T8\\_ECLASS\\_QUAD or T8\\_ECLASS\\_TRIANGLE for prisms.
### Prototype
```c
t8_element_shape_t t8_element_face_shape (const t8_eclass_scheme_c *ts, const t8_element_t *elem, int face);
```
"""
function t8_element_face_shape(ts, elem, face)
    @ccall libt8.t8_element_face_shape(ts::Ptr{t8_eclass_scheme_c}, elem::Ptr{t8_element_t}, face::Cint)::t8_element_shape_t
end

"""
    t8_element_children_at_face(ts, elem, face, children, num_children, child_indices)

Given an element and a face of the element, compute all children of the element that touch the face.

### Parameters
* `ts`:\\[in\\] Implementation of a class scheme.
* `elem`:\\[in\\] The element.
* `face`:\\[in\\] A face of *elem*.
* `children`:\\[in,out\\] Allocated elements, in which the children of *elem* that share a face with *face* are stored. They will be stored in order of their linear id.
* `num_children`:\\[in\\] The number of elements in *children*. Must match the number of children that touch *face*. t8_element_num_face_children
* `child_indices`:\\[in,out\\] If not NULL, an array of num\\_children integers must be given, on output its i-th entry is the child\\_id of the i-th face\\_child. It is valid to call this function with elem = children[0].
### Prototype
```c
void t8_element_children_at_face (const t8_eclass_scheme_c *ts, const t8_element_t *elem, int face, t8_element_t *children[], int num_children, int *child_indices);
```
"""
function t8_element_children_at_face(ts, elem, face, children, num_children, child_indices)
    @ccall libt8.t8_element_children_at_face(ts::Ptr{t8_eclass_scheme_c}, elem::Ptr{t8_element_t}, face::Cint, children::Ptr{Ptr{t8_element_t}}, num_children::Cint, child_indices::Ptr{Cint})::Cvoid
end

"""
    t8_element_face_child_face(ts, elem, face, face_child)

Given a face of an element and a child number of a child of that face, return the face number of the child of the element that matches the child face.

```c++
  x ---- x   x      x           x ---- x
  |      |   |      |           |   |  | <-- f
  |      |   |      x           |   x--x
  |      |   |                  |      |
  x ---- x   x                  x ---- x
   elem    face  face_child    Returns the face number f
```

### Parameters
* `ts`:\\[in\\] Implementation of a class scheme.
* `elem`:\\[in\\] The element.
* `face`:\\[in\\] Then number of the face.
* `face_child`:\\[in\\] A number 0 <= *face_child* < num\\_face\\_children, specifying a child of *elem* that shares a face with *face*. These children are counted in linear order. This coincides with the order of children from a call to t8_element_children_at_face.
### Returns
The face number of the face of a child of *elem* that conincides with *face_child*.
### Prototype
```c
int t8_element_face_child_face (const t8_eclass_scheme_c *ts, const t8_element_t *elem, int face, int face_child);
```
"""
function t8_element_face_child_face(ts, elem, face, face_child)
    @ccall libt8.t8_element_face_child_face(ts::Ptr{t8_eclass_scheme_c}, elem::Ptr{t8_element_t}, face::Cint, face_child::Cint)::Cint
end

"""
    t8_element_face_parent_face(ts, elem, face)

Given a face of an element return the face number of the parent of the element that matches the element's face. Or return -1 if no face of the parent matches the face.

!!! note

    For the root element this function always returns *face*.

### Parameters
* `ts`:\\[in\\] Implementation of a class scheme.
* `elem`:\\[in\\] The element.
* `face`:\\[in\\] Then number of the face.
### Returns
If *face* of *elem* is also a face of *elem*'s parent, the face number of this face. Otherwise -1.
### Prototype
```c
int t8_element_face_parent_face (const t8_eclass_scheme_c *ts, const t8_element_t *elem, int face);
```
"""
function t8_element_face_parent_face(ts, elem, face)
    @ccall libt8.t8_element_face_parent_face(ts::Ptr{t8_eclass_scheme_c}, elem::Ptr{t8_element_t}, face::Cint)::Cint
end

"""
    t8_element_tree_face(ts, elem, face)

Given an element and a face of this element. If the face lies on the tree boundary, return the face number of the tree face. If not the return value is arbitrary.

### Parameters
* `ts`:\\[in\\] Implementation of a class scheme.
* `elem`:\\[in\\] The element.
* `face`:\\[in\\] The index of a face of *elem*.
### Returns
The index of the tree face that *face* is a subface of, if *face* is on a tree boundary. Any arbitrary integer if *is* not at a tree boundary.
### Prototype
```c
int t8_element_tree_face (const t8_eclass_scheme_c *ts, const t8_element_t *elem, int face);
```
"""
function t8_element_tree_face(ts, elem, face)
    @ccall libt8.t8_element_tree_face(ts::Ptr{t8_eclass_scheme_c}, elem::Ptr{t8_element_t}, face::Cint)::Cint
end

"""
    t8_element_transform_face(ts, elem1, elem2, orientation, sign, is_smaller_face)

Suppose we have two trees that share a common face f. Given an element e that is a subface of f in one of the trees and given the orientation of the tree connection, construct the face element of the respective tree neighbor that logically coincides with e but lies in the coordinate system of the neighbor tree.

!!! note

    *elem1* and *elem2* may point to the same element.

### Parameters
* `ts`:\\[in\\] Implementation of a class scheme.
* `elem1`:\\[in\\] The face element.
* `elem2`:\\[in,out\\] On return the face elment *elem1* with respective to the coordinate system of the other tree.
* `orientation`:\\[in\\] The orientation of the tree-tree connection.
* `sign`:\\[in\\] Depending on the topological orientation of the two tree faces, either 0 (both faces have opposite orientation) or 1 (both faces have the same top. orientattion). t8_eclass_face_orientation
* `is_smaller_face`:\\[in\\] Flag to declare whether *elem1* belongs to the smaller face. A face f of tree T is smaller than f' of T' if either the eclass of T is smaller or if the classes are equal and f<f'. The orientation is defined in relation to the smaller face.
### See also
[`t8_cmesh_set_join`](@ref)

### Prototype
```c
void t8_element_transform_face (const t8_eclass_scheme_c *ts, const t8_element_t *elem1, t8_element_t *elem2, int orientation, int sign, int is_smaller_face);
```
"""
function t8_element_transform_face(ts, elem1, elem2, orientation, sign, is_smaller_face)
    @ccall libt8.t8_element_transform_face(ts::Ptr{t8_eclass_scheme_c}, elem1::Ptr{t8_element_t}, elem2::Ptr{t8_element_t}, orientation::Cint, sign::Cint, is_smaller_face::Cint)::Cvoid
end

"""
    t8_element_extrude_face(ts, face, face_scheme, elem, root_face)

Given a boundary face inside a root tree's face construct the element inside the root tree that has the given face as a face.

### Parameters
* `ts`:\\[in\\] Implementation of a class scheme.
* `face`:\\[in\\] A face element.
* `face_scheme`:\\[in\\] The scheme for the face element.
* `elem`:\\[in,out\\] An allocated element. The entries will be filled with the data of the element that has *face* as a face and lies within the root tree.
* `root_face`:\\[in\\] The index of the face of the root tree in which *face* lies.
### Returns
The face number of the face of *elem* that coincides with *face*.
### Prototype
```c
int t8_element_extrude_face (const t8_eclass_scheme_c *ts, const t8_element_t *face, const t8_eclass_scheme_c *face_scheme, t8_element_t *elem, int root_face);
```
"""
function t8_element_extrude_face(ts, face, face_scheme, elem, root_face)
    @ccall libt8.t8_element_extrude_face(ts::Ptr{t8_eclass_scheme_c}, face::Ptr{t8_element_t}, face_scheme::Ptr{t8_eclass_scheme_c}, elem::Ptr{t8_element_t}, root_face::Cint)::Cint
end

"""
    t8_element_boundary_face(ts, elem, face, boundary, boundary_scheme)

Construct the boundary element at a specific face.

### Parameters
* `ts`:\\[in\\] Implementation of a class scheme.
* `elem`:\\[in\\] The input element.
* `face`:\\[in\\] The index of the face of which to construct the boundary element.
* `boundary`:\\[in,out\\] An allocated element of dimension of *element* minus 1. The entries will be filled with the entries of the face of *element*.
* `boundary_scheme`:\\[in\\] The scheme for the eclass of the boundary face. If *elem* is of class T8\\_ECLASS\\_VERTEX, then *boundary* must be NULL and will not be modified.
### Prototype
```c
void t8_element_boundary_face (const t8_eclass_scheme_c *ts, const t8_element_t *elem, int face, t8_element_t *boundary, const t8_eclass_scheme_c *boundary_scheme);
```
"""
function t8_element_boundary_face(ts, elem, face, boundary, boundary_scheme)
    @ccall libt8.t8_element_boundary_face(ts::Ptr{t8_eclass_scheme_c}, elem::Ptr{t8_element_t}, face::Cint, boundary::Ptr{t8_element_t}, boundary_scheme::Ptr{t8_eclass_scheme_c})::Cvoid
end

"""
    t8_element_first_descendant_face(ts, elem, face, first_desc, level)

Construct the first descendant of an element at a given level that touches a given face.

### Parameters
* `ts`:\\[in\\] Implementation of a class scheme.
* `elem`:\\[in\\] The input element.
* `face`:\\[in\\] A face of *elem*.
* `first_desc`:\\[in,out\\] An allocated element. This element's data will be filled with the data of the first descendant of *elem* that shares a face with *face*.
* `level`:\\[in\\] The level, at which the first descendant is constructed
### Prototype
```c
void t8_element_first_descendant_face (const t8_eclass_scheme_c *ts, const t8_element_t *elem, int face, t8_element_t *first_desc, int level);
```
"""
function t8_element_first_descendant_face(ts, elem, face, first_desc, level)
    @ccall libt8.t8_element_first_descendant_face(ts::Ptr{t8_eclass_scheme_c}, elem::Ptr{t8_element_t}, face::Cint, first_desc::Ptr{t8_element_t}, level::Cint)::Cvoid
end

"""
    t8_element_last_descendant_face(ts, elem, face, last_desc, level)

Construct the last descendant of an element at a given level that touches a given face.

### Parameters
* `ts`:\\[in\\] Implementation of a class scheme.
* `elem`:\\[in\\] The input element.
* `face`:\\[in\\] A face of *elem*.
* `last_desc`:\\[in,out\\] An allocated element. This element's data will be filled with the data of the last descendant of *elem* that shares a face with *face*.
* `level`:\\[in\\] The level, at which the last descendant is constructed
### Prototype
```c
void t8_element_last_descendant_face (const t8_eclass_scheme_c *ts, const t8_element_t *elem, int face, t8_element_t *last_desc, int level);
```
"""
function t8_element_last_descendant_face(ts, elem, face, last_desc, level)
    @ccall libt8.t8_element_last_descendant_face(ts::Ptr{t8_eclass_scheme_c}, elem::Ptr{t8_element_t}, face::Cint, last_desc::Ptr{t8_element_t}, level::Cint)::Cvoid
end

"""
    t8_element_is_root_boundary(ts, elem, face)

Compute whether a given element shares a given face with its root tree.

### Parameters
* `ts`:\\[in\\] Implementation of a class scheme.
* `elem`:\\[in\\] The input element.
* `face`:\\[in\\] A face of *elem*.
### Returns
True if *face* is a subface of the element's root element.
### Prototype
```c
int t8_element_is_root_boundary (const t8_eclass_scheme_c *ts, const t8_element_t *elem, int face);
```
"""
function t8_element_is_root_boundary(ts, elem, face)
    @ccall libt8.t8_element_is_root_boundary(ts::Ptr{t8_eclass_scheme_c}, elem::Ptr{t8_element_t}, face::Cint)::Cint
end

"""
    t8_element_face_neighbor_inside(ts, elem, neigh, face, neigh_face)

Construct the face neighbor of a given element if this face neighbor is inside the root tree. Return 0 otherwise.

### Parameters
* `ts`:\\[in\\] Implementation of a class scheme.
* `elem`:\\[in\\] The element to be considered.
* `neigh`:\\[in,out\\] If the face neighbor of *elem* along *face* is inside the root tree, this element's data is filled with the data of the face neighbor. Otherwise the data can be modified arbitrarily.
* `face`:\\[in\\] The number of the face along which the neighbor should be constructed.
* `neigh_face`:\\[out\\] The number of *face* as viewed from *neigh*. An arbitrary value, if the neighbor is not inside the root tree.
### Returns
True if *neigh* is inside the root tree. False if not. In this case *neigh*'s data can be arbitrary on output.
### Prototype
```c
int t8_element_face_neighbor_inside (const t8_eclass_scheme_c *ts, const t8_element_t *elem, t8_element_t *neigh, int face, int *neigh_face);
```
"""
function t8_element_face_neighbor_inside(ts, elem, neigh, face, neigh_face)
    @ccall libt8.t8_element_face_neighbor_inside(ts::Ptr{t8_eclass_scheme_c}, elem::Ptr{t8_element_t}, neigh::Ptr{t8_element_t}, face::Cint, neigh_face::Ptr{Cint})::Cint
end

"""
    t8_element_shape(ts, elem)

Return the shape of an allocated element according its type. For example, a child of an element can be an element of a different shape and has to be handled differently - according to its shape.

### Parameters
* `ts`:\\[in\\] Implementation of a class scheme.
* `elem`:\\[in\\] The element to be considered
### Returns
The shape of the element as an eclass
### Prototype
```c
t8_element_shape_t t8_element_shape (const t8_eclass_scheme_c *ts, const t8_element_t *elem);
```
"""
function t8_element_shape(ts, elem)
    @ccall libt8.t8_element_shape(ts::Ptr{t8_eclass_scheme_c}, elem::Ptr{t8_element_t})::t8_element_shape_t
end

"""
    t8_element_set_linear_id(ts, elem, level, id)

Initialize the entries of an allocated element according to a given linear id in a uniform refinement.

### Parameters
* `ts`:\\[in\\] Implementation of a class scheme.
* `elem`:\\[in,out\\] The element whose entries will be set.
* `level`:\\[in\\] The level of the uniform refinement to consider.
* `id`:\\[in\\] The linear id. id must fulfil 0 <= id < 'number of leafs in the uniform refinement'
### Prototype
```c
void t8_element_set_linear_id (const t8_eclass_scheme_c *ts, t8_element_t *elem, int level, t8_linearidx_t id);
```
"""
function t8_element_set_linear_id(ts, elem, level, id)
    @ccall libt8.t8_element_set_linear_id(ts::Ptr{t8_eclass_scheme_c}, elem::Ptr{t8_element_t}, level::Cint, id::t8_linearidx_t)::Cvoid
end

"""
    t8_element_get_linear_id(ts, elem, level)

Compute the linear id of a given element in a hypothetical uniform refinement of a given level.

### Parameters
* `ts`:\\[in\\] Implementation of a class scheme.
* `elem`:\\[in\\] The element whose id we compute.
* `level`:\\[in\\] The level of the uniform refinement to consider.
### Returns
The linear id of the element.
### Prototype
```c
t8_linearidx_t t8_element_get_linear_id (const t8_eclass_scheme_c *ts, const t8_element_t *elem, int level);
```
"""
function t8_element_get_linear_id(ts, elem, level)
    @ccall libt8.t8_element_get_linear_id(ts::Ptr{t8_eclass_scheme_c}, elem::Ptr{t8_element_t}, level::Cint)::t8_linearidx_t
end

"""
    t8_element_first_descendant(ts, elem, desc, level)

Compute the first descendant of a given element.

### Parameters
* `ts`:\\[in\\] Implementation of a class scheme.
* `elem`:\\[in\\] The element whose descendant is computed.
* `desc`:\\[out\\] The first element in a uniform refinement of *elem* of the maximum possible level.
### Prototype
```c
void t8_element_first_descendant (const t8_eclass_scheme_c *ts, const t8_element_t *elem, t8_element_t *desc, int level);
```
"""
function t8_element_first_descendant(ts, elem, desc, level)
    @ccall libt8.t8_element_first_descendant(ts::Ptr{t8_eclass_scheme_c}, elem::Ptr{t8_element_t}, desc::Ptr{t8_element_t}, level::Cint)::Cvoid
end

"""
    t8_element_last_descendant(ts, elem, desc, level)

Compute the last descendant of a given element.

### Parameters
* `ts`:\\[in\\] Implementation of a class scheme.
* `elem`:\\[in\\] The element whose descendant is computed.
* `desc`:\\[out\\] The last element in a uniform refinement of *elem* of the maximum possible level.
### Prototype
```c
void t8_element_last_descendant (const t8_eclass_scheme_c *ts, const t8_element_t *elem, t8_element_t *desc, int level);
```
"""
function t8_element_last_descendant(ts, elem, desc, level)
    @ccall libt8.t8_element_last_descendant(ts::Ptr{t8_eclass_scheme_c}, elem::Ptr{t8_element_t}, desc::Ptr{t8_element_t}, level::Cint)::Cvoid
end

"""
    t8_element_successor(ts, elem1, elem2, level)

Construct the successor in a uniform refinement of a given element.

### Parameters
* `ts`:\\[in\\] Implementation of a class scheme.
* `elem1`:\\[in\\] The element whose successor should be constructed.
* `elem2`:\\[in,out\\] The element whose entries will be set.
* `level`:\\[in\\] The level of the uniform refinement to consider.
### Prototype
```c
void t8_element_successor (const t8_eclass_scheme_c *ts, const t8_element_t *elem1, t8_element_t *elem2, int level);
```
"""
function t8_element_successor(ts, elem1, elem2, level)
    @ccall libt8.t8_element_successor(ts::Ptr{t8_eclass_scheme_c}, elem1::Ptr{t8_element_t}, elem2::Ptr{t8_element_t}, level::Cint)::Cvoid
end

"""
    t8_element_root_len(ts, elem)

Compute the root lenght of a given element, that is the length of its level 0 ancestor.

### Parameters
* `ts`:\\[in\\] Implementation of a class scheme.
* `elem`:\\[in\\] The element whose root length should be computed.
### Returns
The root length of *elem*
### Prototype
```c
int t8_element_root_len (const t8_eclass_scheme_c *ts, const t8_element_t *elem);
```
"""
function t8_element_root_len(ts, elem)
    @ccall libt8.t8_element_root_len(ts::Ptr{t8_eclass_scheme_c}, elem::Ptr{t8_element_t})::Cint
end

"""
    t8_element_vertex_reference_coords(ts, t, vertex, coords)

Compute the coordinates of a given element vertex inside a reference tree that is embedded into [0,1]^d (d = dimension).

### Parameters
* `ts`:\\[in\\] Implementation of a class scheme.
* `t`:\\[in\\] The element to be considered.
* `vertex`:\\[in\\] The id of the vertex whose coordinates shall be computed.
* `coords`:\\[out\\] An array of at least as many doubles as the element's dimension whose entries will be filled with the coordinates of *vertex*.
### Prototype
```c
void t8_element_vertex_reference_coords (const t8_eclass_scheme_c *ts, const t8_element_t *t, const int vertex, double coords[]);
```
"""
function t8_element_vertex_reference_coords(ts, t, vertex, coords)
    @ccall libt8.t8_element_vertex_reference_coords(ts::Ptr{t8_eclass_scheme_c}, t::Ptr{t8_element_t}, vertex::Cint, coords::Ptr{Cdouble})::Cvoid
end

"""
    t8_element_count_leafs(ts, t, level)

Count how many leaf descendants of a given uniform level an element would produce.

Example: If *t* is a line element that refines into 2 line elements on each level, then the return value is max(0, 2^{*level* - level(*t*)}). Thus, if *t*'s level is 0, and *level* = 3, the return value is 2^3 = 8.

### Parameters
* `ts`:\\[in\\] Implementation of a class scheme.
* `t`:\\[in\\] The element to be checked.
* `level`:\\[in\\] A refinement level.
### Returns
Suppose *t* is uniformly refined up to level *level*. The return value is the resulting number of elements (of the given level). If *level* < [`t8_element_level`](@ref)(t), the return value should be 0.
### Prototype
```c
t8_gloidx_t t8_element_count_leafs (const t8_eclass_scheme_c *ts, const t8_element_t *t, int level);
```
"""
function t8_element_count_leafs(ts, t, level)
    @ccall libt8.t8_element_count_leafs(ts::Ptr{t8_eclass_scheme_c}, t::Ptr{t8_element_t}, level::Cint)::t8_gloidx_t
end

"""
    t8_element_count_leafs_from_root(ts, level)

Count how many leaf descendants of a given uniform level the root element will produce.

This is a convenience function, and can be implemented via t8_element_count_leafs.

### Parameters
* `ts`:\\[in\\] Implementation of a class scheme.
* `level`:\\[in\\] A refinement level.
### Returns
The value of t8_element_count_leafs if the input element is the root (level 0) element.
### Prototype
```c
t8_gloidx_t t8_element_count_leafs_from_root (const t8_eclass_scheme_c *ts, int level);
```
"""
function t8_element_count_leafs_from_root(ts, level)
    @ccall libt8.t8_element_count_leafs_from_root(ts::Ptr{t8_eclass_scheme_c}, level::Cint)::t8_gloidx_t
end

"""
    t8_element_general_function(ts, elem, indata, outdata)

This function has no defined effect but each implementation is free to provide its own meaning of it. Thus this function can be used to compute or lookup very scheme implementation specific data.

### Parameters
* `ts`:\\[in\\] Implementation of a class scheme.
* `elem`:\\[in\\] An valid element
* `indata`:\\[in\\] Pointer to input data
* `outdata`:\\[out\\] Pointer to output data. For the correct usage of *indata* and *outdata* see the specific implementations of the scheme. For example the default scheme triangle and tetrahedron implementations use  this function to return the type of a tri/tet to the caller.
### Prototype
```c
void t8_element_general_function (const t8_eclass_scheme_c *ts, const t8_element_t *elem, const void *indata, void *outdata);
```
"""
function t8_element_general_function(ts, elem, indata, outdata)
    @ccall libt8.t8_element_general_function(ts::Ptr{t8_eclass_scheme_c}, elem::Ptr{t8_element_t}, indata::Ptr{Cvoid}, outdata::Ptr{Cvoid})::Cvoid
end

"""
    t8_element_new(ts, length, elems)

Allocate memory for an array of elements of a given class and initialize them.

!!! note

    Not every element that is created in t8code will be created by a call to this function. However, if an element is not created using t8_element_new, then it is guaranteed that t8_element_init is called on it.

!!! note

    In debugging mode, an element that was created with t8_element_new must pass t8_element_is_valid.

!!! note

    If an element was created by t8_element_new then t8_element_init may not be called for it. Thus, t8_element_new should initialize an element in the same way as a call to t8_element_init would.

### Parameters
* `ts`:\\[in\\] Implementation of a class scheme.
* `length`:\\[in\\] The number of elements to be allocated.
* `elems`:\\[in,out\\] On input an array of **length** many unallocated element pointers. On output all these pointers will point to an allocated and initialized element.
### See also
t8\\_element\\_init, t8\\_element\\_is\\_valid

### Prototype
```c
void t8_element_new (const t8_eclass_scheme_c *ts, int length, t8_element_t **elems);
```
"""
function t8_element_new(ts, length, elems)
    @ccall libt8.t8_element_new(ts::Ptr{t8_eclass_scheme_c}, length::Cint, elems::Ptr{Ptr{t8_element_t}})::Cvoid
end

"""
    t8_element_destroy(ts, length, elems)

Deallocate an array of elements.

### Parameters
* `ts`:\\[in\\] Implementation of a class scheme.
* `length`:\\[in\\] The number of elements in the array.
* `elems`:\\[in,out\\] On input an array of **length** many allocated element pointers. On output all these pointers will be freed. **elem** itself will not be freed by this function.
### Prototype
```c
void t8_element_destroy (const t8_eclass_scheme_c *ts, int length, t8_element_t **elems);
```
"""
function t8_element_destroy(ts, length, elems)
    @ccall libt8.t8_element_destroy(ts::Ptr{t8_eclass_scheme_c}, length::Cint, elems::Ptr{Ptr{t8_element_t}})::Cvoid
end

"""
    t8_element_shape_num_faces(element_shape)

The number of codimension-one boundaries of an element class.

### Prototype
```c
int t8_element_shape_num_faces (int element_shape);
```
"""
function t8_element_shape_num_faces(element_shape)
    @ccall libt8.t8_element_shape_num_faces(element_shape::Cint)::Cint
end

"""
    t8_element_shape_max_num_faces(element_shape)

For each dimension the maximum possible number of faces of an element\\_shape of that dimension.

### Prototype
```c
int t8_element_shape_max_num_faces (int element_shape);
```
"""
function t8_element_shape_max_num_faces(element_shape)
    @ccall libt8.t8_element_shape_max_num_faces(element_shape::Cint)::Cint
end

"""
    t8_element_shape_num_vertices(element_shape)

The number of vertices of an element class.

### Prototype
```c
int t8_element_shape_num_vertices (int element_shape);
```
"""
function t8_element_shape_num_vertices(element_shape)
    @ccall libt8.t8_element_shape_num_vertices(element_shape::Cint)::Cint
end

"""
    t8_element_shape_vtk_type(element_shape)

The vtk cell type for the element\\_shape

### Prototype
```c
int t8_element_shape_vtk_type (int element_shape);
```
"""
function t8_element_shape_vtk_type(element_shape)
    @ccall libt8.t8_element_shape_vtk_type(element_shape::Cint)::Cint
end

"""
    t8_element_shape_vtk_corner_number(element_shape, index)

Maps the t8code corner number of the element to the vtk corner number

### Prototype
```c
int t8_element_shape_vtk_corner_number (int element_shape, int index);
```
"""
function t8_element_shape_vtk_corner_number(element_shape, index)
    @ccall libt8.t8_element_shape_vtk_corner_number(element_shape::Cint, index::Cint)::Cint
end

"""
    t8_element_shape_to_string(element_shape)

For each element\\_shape, the name of this class as a string

### Prototype
```c
const char *t8_element_shape_to_string (int element_shape);
```
"""
function t8_element_shape_to_string(element_shape)
    @ccall libt8.t8_element_shape_to_string(element_shape::Cint)::Cstring
end

"""
    t8_element_shape_compare(element_shape1, element_shape2)

Compare two element\\_shapees of the same dimension as necessary for face neighbor orientation. The implemented order is Triangle < Square in 2D and Tet < Hex < Prism < Pyramid in 3D.

### Parameters
* `element_shape1`:\\[in\\] The first element\\_shape to compare.
* `element_shape2`:\\[in\\] The second element\\_shape to compare.
### Returns
0 if the element\\_shapees are equal, 1 if element\\_shape1 > element\\_shape2 and -1 if element\\_shape1 < element\\_shape2
### Prototype
```c
int t8_element_shape_compare (t8_element_shape_t element_shape1, t8_element_shape_t element_shape2);
```
"""
function t8_element_shape_compare(element_shape1, element_shape2)
    @ccall libt8.t8_element_shape_compare(element_shape1::t8_element_shape_t, element_shape2::t8_element_shape_t)::Cint
end

# typedef double ( * t8_example_level_set_fn ) ( const double [ 3 ] , double , void * )
"""A levelset function in 3+1 space dimensions."""
const t8_example_level_set_fn = Ptr{Cvoid}

"""
    t8_example_level_set_struct_t

Struct to handle refinement around a level-set function.

| Field        | Note                                                                           |
| :----------- | :----------------------------------------------------------------------------- |
| L            | The level set function.                                                        |
| udata        | Data pointer that is passed to L                                               |
| band\\_width | Width of max\\_level elements around the zero-level set                        |
| t            | Time value passed to levelset function                                         |
| min\\_level  | The minimal refinement level. Elements with this level will not be coarsened.  |
| max\\_level  | The maximum refinement level. Elements with this level will not be refined.    |
"""
struct t8_example_level_set_struct_t
    L::t8_example_level_set_fn
    udata::Ptr{Cvoid}
    band_width::Cdouble
    t::Cdouble
    min_level::Cint
    max_level::Cint
end

# typedef double ( * t8_scalar_function_1d_fn ) ( double x , double t )
"""Function pointer for real valued functions from d+1 space dimensions functions f: R^d x R -> R"""
const t8_scalar_function_1d_fn = Ptr{Cvoid}

# typedef double ( * t8_scalar_function_2d_fn ) ( const double x [ 2 ] , double t )
const t8_scalar_function_2d_fn = Ptr{Cvoid}

# typedef double ( * t8_scalar_function_3d_fn ) ( const double x [ 3 ] , double t )
const t8_scalar_function_3d_fn = Ptr{Cvoid}

# typedef void ( * t8_flow_function_3d_fn ) ( const double x_in [ 3 ] , double t , double x_out [ 3 ] )
"""Function pointer for a vector valued function f: R^3 x R -> R"""
const t8_flow_function_3d_fn = Ptr{Cvoid}

mutable struct t8_forest end

"""Opaque pointer to a forest implementation."""
const t8_forest_t = Ptr{t8_forest}

"""
    t8_common_within_levelset(forest, ltreeid, element, ts, levelset, band_width, t, udata)

Query whether a given element is within a prescribed distance to the zero level-set of a level-set function.

### Parameters
* `forest`:\\[in\\] The forest.
* `ltreeid`:\\[in\\] A local tree in *forest*.
* `element`:\\[in\\] An element of tree *ltreeid* in *forest*.
* `ts`:\\[in\\] The scheme for *element*.
* `levelset`:\\[in\\] The level-set function.
* `band_width`:\\[in\\] Check whether the element is within a band of *band_width* many elements of its size.
* `t`:\\[in\\] Time value passed to *levelset*.
* `udata`:\\[in\\] User data passed to *levelset*.
### Returns
True if the absolute value of *levelset* at *element*'s midpoint is smaller than *band_width* * *element*'s diameter. False otherwise. If *band_width* = 0 then the return value is true if and only if the zero level-set passes through *element*.
### Prototype
```c
int t8_common_within_levelset (t8_forest_t forest, t8_locidx_t ltreeid, t8_element_t *element, t8_eclass_scheme_c *ts, t8_example_level_set_fn levelset, double band_width, double t, void *udata);
```
"""
function t8_common_within_levelset(forest, ltreeid, element, ts, levelset, band_width, t, udata)
    @ccall libt8.t8_common_within_levelset(forest::t8_forest_t, ltreeid::t8_locidx_t, element::Ptr{t8_element_t}, ts::Ptr{t8_eclass_scheme_c}, levelset::t8_example_level_set_fn, band_width::Cdouble, t::Cdouble, udata::Ptr{Cvoid})::Cint
end

"""
    t8_common_adapt_balance(forest, forest_from, which_tree, lelement_id, ts, is_family, num_elements, elements)

Adapt a forest such that always the second child of the first tree is refined and no other elements. This results in a highly imbalanced forest.

### Prototype
```c
int t8_common_adapt_balance (t8_forest_t forest, t8_forest_t forest_from, t8_locidx_t which_tree, t8_locidx_t lelement_id, t8_eclass_scheme_c *ts, const int is_family, const int num_elements, t8_element_t *elements[]);
```
"""
function t8_common_adapt_balance(forest, forest_from, which_tree, lelement_id, ts, is_family, num_elements, elements)
    @ccall libt8.t8_common_adapt_balance(forest::t8_forest_t, forest_from::t8_forest_t, which_tree::t8_locidx_t, lelement_id::t8_locidx_t, ts::Ptr{t8_eclass_scheme_c}, is_family::Cint, num_elements::Cint, elements::Ptr{Ptr{t8_element_t}})::Cint
end

"""
    t8_common_adapt_level_set(forest, forest_from, which_tree, lelement_id, ts, is_family, num_elements, elements)

Adapt a forest along a given level-set function. The user data of forest must be a pointer to a [`t8_example_level_set_struct_t`](@ref). An element in the forest is refined, if it is in a band of *band_with* many *max_level* elements around the zero level-set Gamma = { x | L(x) = 0}

### Prototype
```c
int t8_common_adapt_level_set (t8_forest_t forest, t8_forest_t forest_from, t8_locidx_t which_tree, t8_locidx_t lelement_id, t8_eclass_scheme_c *ts, const int is_family, const int num_elements, t8_element_t *elements[]);
```
"""
function t8_common_adapt_level_set(forest, forest_from, which_tree, lelement_id, ts, is_family, num_elements, elements)
    @ccall libt8.t8_common_adapt_level_set(forest::t8_forest_t, forest_from::t8_forest_t, which_tree::t8_locidx_t, lelement_id::t8_locidx_t, ts::Ptr{t8_eclass_scheme_c}, is_family::Cint, num_elements::Cint, elements::Ptr{Ptr{t8_element_t}})::Cint
end

"""
    t8_levelset_sphere_data_t

Real valued functions defined in t8\\_example\\_common\\_functions.h
"""
struct t8_levelset_sphere_data_t
    M::NTuple{3, Cdouble}
    radius::Cdouble
end

"""
    t8_levelset_sphere(x, t, data)

Distance to a sphere with given midpoint and radius. data is interpreted as [`t8_levelset_sphere_data_t`](@ref).

### Returns
dist (x,data->M) - data->radius
### Prototype
```c
double t8_levelset_sphere (const double x[3], double t, void *data);
```
"""
function t8_levelset_sphere(x, t, data)
    @ccall libt8.t8_levelset_sphere(x::Ptr{Cdouble}, t::Cdouble, data::Ptr{Cvoid})::Cdouble
end

"""
    t8_scalar3d_constant_one(x, t)

Returns always 1.

### Returns
1
### Prototype
```c
double t8_scalar3d_constant_one (const double x[3], double t);
```
"""
function t8_scalar3d_constant_one(x, t)
    @ccall libt8.t8_scalar3d_constant_one(x::Ptr{Cdouble}, t::Cdouble)::Cdouble
end

"""
    t8_scalar3d_constant_zero(x, t)

Returns always 0.

### Returns
0
### Prototype
```c
double t8_scalar3d_constant_zero (const double x[3], double t);
```
"""
function t8_scalar3d_constant_zero(x, t)
    @ccall libt8.t8_scalar3d_constant_zero(x::Ptr{Cdouble}, t::Cdouble)::Cdouble
end

"""
    t8_scalar3d_project_x(x, t)

Return the x-coordinate of the input.

### Returns
x[0]
### Prototype
```c
double t8_scalar3d_project_x (const double x[3], double t);
```
"""
function t8_scalar3d_project_x(x, t)
    @ccall libt8.t8_scalar3d_project_x(x::Ptr{Cdouble}, t::Cdouble)::Cdouble
end

"""
    t8_scalar3d_step_function(x, t)

This function is =1 if the 0.25 <= x <= 0.75 and 0 else.

### Prototype
```c
double t8_scalar3d_step_function (const double x[3], double t);
```
"""
function t8_scalar3d_step_function(x, t)
    @ccall libt8.t8_scalar3d_step_function(x::Ptr{Cdouble}, t::Cdouble)::Cdouble
end

"""
    t8_scalar3d_almost_step_function(x, t)

This function is =1 if 0.25 <= x <= 0.75, it is 0 outside of 0.25-eps and 0.75+eps, it interpolates linearly in between. eps = 0.1 *

### Prototype
```c
double t8_scalar3d_almost_step_function (const double x[3], double t);
```
"""
function t8_scalar3d_almost_step_function(x, t)
    @ccall libt8.t8_scalar3d_almost_step_function(x::Ptr{Cdouble}, t::Cdouble)::Cdouble
end

"""
    t8_scalar3d_exp_distribution(x, t)

A 1-d Bell-curve centered around 0.5

### Prototype
```c
double t8_scalar3d_exp_distribution (const double x[3], double t);
```
"""
function t8_scalar3d_exp_distribution(x, t)
    @ccall libt8.t8_scalar3d_exp_distribution(x::Ptr{Cdouble}, t::Cdouble)::Cdouble
end

"""
    t8_scalar3d_sinx(x, t)

Sinus of 2pi x\\_0

### Returns
sin (2pi x[0])
### Prototype
```c
double t8_scalar3d_sinx (const double x[3], double t);
```
"""
function t8_scalar3d_sinx(x, t)
    @ccall libt8.t8_scalar3d_sinx(x::Ptr{Cdouble}, t::Cdouble)::Cdouble
end

"""
    t8_scalar3d_sinx_cosy(x, t)

Sinus of x times cosinus of y

### Returns
sin (2pi x[0]) * cos (2pi x[1])
### Prototype
```c
double t8_scalar3d_sinx_cosy (const double x[3], double t);
```
"""
function t8_scalar3d_sinx_cosy(x, t)
    @ccall libt8.t8_scalar3d_sinx_cosy(x::Ptr{Cdouble}, t::Cdouble)::Cdouble
end

"""
    t8_scalar3d_sinx_cosy_z(x, t)

Sinus of 10 * x times cosinus of y times z

### Returns
10 * sin (2pi x[0]) * cos (2pi x[1]) * x[3]
### Prototype
```c
double t8_scalar3d_sinx_cosy_z (const double x[3], double t);
```
"""
function t8_scalar3d_sinx_cosy_z(x, t)
    @ccall libt8.t8_scalar3d_sinx_cosy_z(x::Ptr{Cdouble}, t::Cdouble)::Cdouble
end

"""
    t8_scalar3d_sint(x, t)

Sinus of t

### Returns
sin (2pi t)
### Prototype
```c
double t8_scalar3d_sint (const double x[3], double t);
```
"""
function t8_scalar3d_sint(x, t)
    @ccall libt8.t8_scalar3d_sint(x::Ptr{Cdouble}, t::Cdouble)::Cdouble
end

"""
    t8_scalar3d_sphere_75_radius(x, t)

Level-set function of a sphere around origin with radius 0.75

### Returns
|x| - 0.75
### Prototype
```c
double t8_scalar3d_sphere_75_radius (const double x[3], double t);
```
"""
function t8_scalar3d_sphere_75_radius(x, t)
    @ccall libt8.t8_scalar3d_sphere_75_radius(x::Ptr{Cdouble}, t::Cdouble)::Cdouble
end

"""
    t8_scalar3d_sphere_05_midpoint_375_radius(x, t)

Level-set function of a sphere around M = (0.5,0.5,0.5) with radius 0.375

### Returns
|x - M| - 0.375
### Prototype
```c
double t8_scalar3d_sphere_05_midpoint_375_radius (const double x[3], double t);
```
"""
function t8_scalar3d_sphere_05_midpoint_375_radius(x, t)
    @ccall libt8.t8_scalar3d_sphere_05_midpoint_375_radius(x::Ptr{Cdouble}, t::Cdouble)::Cdouble
end

"""
    t8_scalar3d_sphere_03_midpoint_25_radius(x, t)

Level-set function of a sphere around M = (0.3,0.3,0.3) with radius 0.25

### Returns
|x - M| - 0.25
### Prototype
```c
double t8_scalar3d_sphere_03_midpoint_25_radius (const double x[3], double t);
```
"""
function t8_scalar3d_sphere_03_midpoint_25_radius(x, t)
    @ccall libt8.t8_scalar3d_sphere_03_midpoint_25_radius(x::Ptr{Cdouble}, t::Cdouble)::Cdouble
end

"""
    t8_scalar3d_sphere_05_0z_midpoint_375_radius(x, t)

Level-set function of a sphere around M = (0.5,0.5,0) with radius 0.375

### Returns
|x - M| - 0.375
### Prototype
```c
double t8_scalar3d_sphere_05_0z_midpoint_375_radius (const double x[3], double t);
```
"""
function t8_scalar3d_sphere_05_0z_midpoint_375_radius(x, t)
    @ccall libt8.t8_scalar3d_sphere_05_0z_midpoint_375_radius(x::Ptr{Cdouble}, t::Cdouble)::Cdouble
end

"""
    t8_flow_constant_one_vec(x, t, x_out)

Returns always 1 in each coordinate.

### Prototype
```c
void t8_flow_constant_one_vec (const double x[3], double t, double x_out[3]);
```
"""
function t8_flow_constant_one_vec(x, t, x_out)
    @ccall libt8.t8_flow_constant_one_vec(x::Ptr{Cdouble}, t::Cdouble, x_out::Ptr{Cdouble})::Cvoid
end

"""
    t8_flow_constant_one_x_vec(x, t, x_out)

Sets the first coordinate to 1, all other to 0.

### Prototype
```c
void t8_flow_constant_one_x_vec (const double x[3], double t, double x_out[3]);
```
"""
function t8_flow_constant_one_x_vec(x, t, x_out)
    @ccall libt8.t8_flow_constant_one_x_vec(x::Ptr{Cdouble}, t::Cdouble, x_out::Ptr{Cdouble})::Cvoid
end

"""
    t8_flow_constant_one_xy_vec(x, t, x_out)

Sets the first and second coordinate to 1, the third to 0.

### Prototype
```c
void t8_flow_constant_one_xy_vec (const double x[3], double t, double x_out[3]);
```
"""
function t8_flow_constant_one_xy_vec(x, t, x_out)
    @ccall libt8.t8_flow_constant_one_xy_vec(x::Ptr{Cdouble}, t::Cdouble, x_out::Ptr{Cdouble})::Cvoid
end

"""
    t8_flow_constant_one_xyz_vec(x, t, x_out)

Sets all coordinates to a nonzero constant.

### Prototype
```c
void t8_flow_constant_one_xyz_vec (const double x[3], double t, double x_out[3]);
```
"""
function t8_flow_constant_one_xyz_vec(x, t, x_out)
    @ccall libt8.t8_flow_constant_one_xyz_vec(x::Ptr{Cdouble}, t::Cdouble, x_out::Ptr{Cdouble})::Cvoid
end

"""
    t8_flow_rotation_2d(x, t, x_out)

Transform the unit square to [-0.5,0.5]^2 and computes x = 2pi*y, y = -2pi*x

### Prototype
```c
void t8_flow_rotation_2d (const double x[3], double t, double x_out[3]);
```
"""
function t8_flow_rotation_2d(x, t, x_out)
    @ccall libt8.t8_flow_rotation_2d(x::Ptr{Cdouble}, t::Cdouble, x_out::Ptr{Cdouble})::Cvoid
end

"""
    t8_flow_compressible(x_in, t, x_out)

### Prototype
```c
void t8_flow_compressible (const double x_in[3], double t, double x_out[3]);
```
"""
function t8_flow_compressible(x_in, t, x_out)
    @ccall libt8.t8_flow_compressible(x_in::Ptr{Cdouble}, t::Cdouble, x_out::Ptr{Cdouble})::Cvoid
end

"""
    t8_flow_incomp_cube_flow(x, t, x_out)

Incompressible flow in unit cube

### Prototype
```c
void t8_flow_incomp_cube_flow (const double x[3], double t, double x_out[3]);
```
"""
function t8_flow_incomp_cube_flow(x, t, x_out)
    @ccall libt8.t8_flow_incomp_cube_flow(x::Ptr{Cdouble}, t::Cdouble, x_out::Ptr{Cdouble})::Cvoid
end

"""
    t8_flow_around_circle(x, t, x_out)

2d flow around a circle with radius R = 1 and constant inflow with x-speed U = 1.  See https://doi.org/10.13140/RG.2.2.34714.11203

### Prototype
```c
void t8_flow_around_circle (const double x[3], double t, double x_out[3]);
```
"""
function t8_flow_around_circle(x, t, x_out)
    @ccall libt8.t8_flow_around_circle(x::Ptr{Cdouble}, t::Cdouble, x_out::Ptr{Cdouble})::Cvoid
end

"""
    t8_flow_stokes_flow_sphere_shell(x, t, x_out)

### Prototype
```c
void t8_flow_stokes_flow_sphere_shell (const double x[3], double t, double x_out[3]);
```
"""
function t8_flow_stokes_flow_sphere_shell(x, t, x_out)
    @ccall libt8.t8_flow_stokes_flow_sphere_shell(x::Ptr{Cdouble}, t::Cdouble, x_out::Ptr{Cdouble})::Cvoid
end

"""
    t8_flow_around_circle_with_angular_velocity(x, t, x_out)

### Prototype
```c
void t8_flow_around_circle_with_angular_velocity (const double x[3], double t, double x_out[]);
```
"""
function t8_flow_around_circle_with_angular_velocity(x, t, x_out)
    @ccall libt8.t8_flow_around_circle_with_angular_velocity(x::Ptr{Cdouble}, t::Cdouble, x_out::Ptr{Cdouble})::Cvoid
end

"""
    t8_forest_write_netcdf(forest, file_prefix, file_title, dim, num_extern_netcdf_vars, ext_variables, comm)

### Prototype
```c
void t8_forest_write_netcdf (t8_forest_t forest, const char *file_prefix, const char *file_title, int dim, int num_extern_netcdf_vars, t8_netcdf_variable_t * ext_variables[], sc_MPI_Comm comm);
```
"""
function t8_forest_write_netcdf(forest, file_prefix, file_title, dim, num_extern_netcdf_vars, ext_variables, comm)
    @ccall libt8.t8_forest_write_netcdf(forest::t8_forest_t, file_prefix::Cstring, file_title::Cstring, dim::Cint, num_extern_netcdf_vars::Cint, ext_variables::Ptr{Ptr{t8_netcdf_variable_t}}, comm::MPI_Comm)::Cvoid
end

"""
    t8_forest_write_netcdf_ext(forest, file_prefix, file_title, dim, num_extern_netcdf_vars, ext_variables, comm, netcdf_var_storage_mode, netcdf_var_mpi_access)

### Prototype
```c
void t8_forest_write_netcdf_ext (t8_forest_t forest, const char *file_prefix, const char *file_title, int dim, int num_extern_netcdf_vars, t8_netcdf_variable_t * ext_variables[], sc_MPI_Comm comm, int netcdf_var_storage_mode, int netcdf_var_mpi_access);
```
"""
function t8_forest_write_netcdf_ext(forest, file_prefix, file_title, dim, num_extern_netcdf_vars, ext_variables, comm, netcdf_var_storage_mode, netcdf_var_mpi_access)
    @ccall libt8.t8_forest_write_netcdf_ext(forest::t8_forest_t, file_prefix::Cstring, file_title::Cstring, dim::Cint, num_extern_netcdf_vars::Cint, ext_variables::Ptr{Ptr{t8_netcdf_variable_t}}, comm::MPI_Comm, netcdf_var_storage_mode::Cint, netcdf_var_mpi_access::Cint)::Cvoid
end

mutable struct t8_mesh end

const t8_mesh_t = t8_mesh

"""
    t8_mesh_new(dimension, Kglobal, Klocal)

*********************** preallocate *************************

### Prototype
```c
t8_mesh_t *t8_mesh_new (int dimension, t8_gloidx_t Kglobal, t8_locidx_t Klocal);
```
"""
function t8_mesh_new(dimension, Kglobal, Klocal)
    @ccall libt8.t8_mesh_new(dimension::Cint, Kglobal::t8_gloidx_t, Klocal::t8_locidx_t)::Ptr{t8_mesh_t}
end

"""
    t8_mesh_new_unitcube(theclass)

*********** all-in-one convenience constructors *************

### Prototype
```c
t8_mesh_t *t8_mesh_new_unitcube (t8_eclass_t theclass);
```
"""
function t8_mesh_new_unitcube(theclass)
    @ccall libt8.t8_mesh_new_unitcube(theclass::t8_eclass_t)::Ptr{t8_mesh_t}
end

"""
    t8_mesh_set_comm(mesh, comm)

### Prototype
```c
void t8_mesh_set_comm (t8_mesh_t *mesh, sc_MPI_Comm comm);
```
"""
function t8_mesh_set_comm(mesh, comm)
    @ccall libt8.t8_mesh_set_comm(mesh::Ptr{t8_mesh_t}, comm::MPI_Comm)::Cvoid
end

"""
    t8_mesh_set_partition(mesh, enable)

Determine whether we partition in t8_mesh_build. Default true.

### Prototype
```c
void t8_mesh_set_partition (t8_mesh_t *mesh, int enable);
```
"""
function t8_mesh_set_partition(mesh, enable)
    @ccall libt8.t8_mesh_set_partition(mesh::Ptr{t8_mesh_t}, enable::Cint)::Cvoid
end

"""
    t8_mesh_set_element(mesh, theclass, gloid, locid)

### Prototype
```c
void t8_mesh_set_element (t8_mesh_t *mesh, t8_eclass_t theclass, t8_gloidx_t gloid, t8_locidx_t locid);
```
"""
function t8_mesh_set_element(mesh, theclass, gloid, locid)
    @ccall libt8.t8_mesh_set_element(mesh::Ptr{t8_mesh_t}, theclass::t8_eclass_t, gloid::t8_gloidx_t, locid::t8_locidx_t)::Cvoid
end

"""
    t8_mesh_set_local_to_global(mesh, ltog_length, ltog)

### Prototype
```c
void t8_mesh_set_local_to_global (t8_mesh_t *mesh, t8_locidx_t ltog_length, const t8_gloidx_t *ltog);
```
"""
function t8_mesh_set_local_to_global(mesh, ltog_length, ltog)
    @ccall libt8.t8_mesh_set_local_to_global(mesh::Ptr{t8_mesh_t}, ltog_length::t8_locidx_t, ltog::Ptr{t8_gloidx_t})::Cvoid
end

"""
    t8_mesh_set_face(mesh, locid1, face1, locid2, face2, orientation)

### Prototype
```c
void t8_mesh_set_face (t8_mesh_t *mesh, t8_locidx_t locid1, int face1, t8_locidx_t locid2, int face2, int orientation);
```
"""
function t8_mesh_set_face(mesh, locid1, face1, locid2, face2, orientation)
    @ccall libt8.t8_mesh_set_face(mesh::Ptr{t8_mesh_t}, locid1::t8_locidx_t, face1::Cint, locid2::t8_locidx_t, face2::Cint, orientation::Cint)::Cvoid
end

"""
    t8_mesh_set_element_vertices(mesh, locid, vids_length, vids)

### Prototype
```c
void t8_mesh_set_element_vertices (t8_mesh_t *mesh, t8_locidx_t locid, t8_locidx_t vids_length, const t8_locidx_t *vids);
```
"""
function t8_mesh_set_element_vertices(mesh, locid, vids_length, vids)
    @ccall libt8.t8_mesh_set_element_vertices(mesh::Ptr{t8_mesh_t}, locid::t8_locidx_t, vids_length::t8_locidx_t, vids::Ptr{t8_locidx_t})::Cvoid
end

"""
    t8_mesh_build(mesh)

Setup a mesh and turn it into a usable object.

### Prototype
```c
void t8_mesh_build (t8_mesh_t *mesh);
```
"""
function t8_mesh_build(mesh)
    @ccall libt8.t8_mesh_build(mesh::Ptr{t8_mesh_t})::Cvoid
end

"""
    t8_mesh_get_comm(mesh)

### Prototype
```c
sc_MPI_Comm t8_mesh_get_comm (t8_mesh_t *mesh);
```
"""
function t8_mesh_get_comm(mesh)
    @ccall libt8.t8_mesh_get_comm(mesh::Ptr{t8_mesh_t})::Cint
end

"""
    t8_mesh_get_element_count(mesh, theclass)

### Prototype
```c
t8_locidx_t t8_mesh_get_element_count (t8_mesh_t *mesh, t8_eclass_t theclass);
```
"""
function t8_mesh_get_element_count(mesh, theclass)
    @ccall libt8.t8_mesh_get_element_count(mesh::Ptr{t8_mesh_t}, theclass::t8_eclass_t)::t8_locidx_t
end

"""
    t8_mesh_get_element_class(mesh, locid)

### Parameters
* `locid`:\\[in\\] The local number can specify a point of any dimension that is locally relevant. The points are ordered in reverse to the element classes in t8_eclass_t. The local index is cumulative in this order.
### Prototype
```c
t8_locidx_t t8_mesh_get_element_class (t8_mesh_t *mesh, t8_locidx_t locid);
```
"""
function t8_mesh_get_element_class(mesh, locid)
    @ccall libt8.t8_mesh_get_element_class(mesh::Ptr{t8_mesh_t}, locid::t8_locidx_t)::t8_locidx_t
end

"""
    t8_mesh_get_element_locid(mesh, gloid)

### Prototype
```c
t8_locidx_t t8_mesh_get_element_locid (t8_mesh_t *mesh, t8_gloidx_t gloid);
```
"""
function t8_mesh_get_element_locid(mesh, gloid)
    @ccall libt8.t8_mesh_get_element_locid(mesh::Ptr{t8_mesh_t}, gloid::t8_gloidx_t)::t8_locidx_t
end

"""
    t8_mesh_get_element_gloid(mesh, locid)

### Prototype
```c
t8_gloidx_t t8_mesh_get_element_gloid (t8_mesh_t *mesh, t8_locidx_t locid);
```
"""
function t8_mesh_get_element_gloid(mesh, locid)
    @ccall libt8.t8_mesh_get_element_gloid(mesh::Ptr{t8_mesh_t}, locid::t8_locidx_t)::t8_gloidx_t
end

"""
    t8_mesh_get_element(mesh, locid)

### Prototype
```c
t8_element_t t8_mesh_get_element (t8_mesh_t *mesh, t8_locidx_t locid);
```
"""
function t8_mesh_get_element(mesh, locid)
    @ccall libt8.t8_mesh_get_element(mesh::Ptr{t8_mesh_t}, locid::t8_locidx_t)::t8_element_t
end

"""
    t8_mesh_get_element_boundary(mesh, locid, length_boundary, elemid, orientation)

### Prototype
```c
void t8_mesh_get_element_boundary (t8_mesh_t *mesh, t8_locidx_t locid, int length_boundary, t8_locidx_t *elemid, int *orientation);
```
"""
function t8_mesh_get_element_boundary(mesh, locid, length_boundary, elemid, orientation)
    @ccall libt8.t8_mesh_get_element_boundary(mesh::Ptr{t8_mesh_t}, locid::t8_locidx_t, length_boundary::Cint, elemid::Ptr{t8_locidx_t}, orientation::Ptr{Cint})::Cvoid
end

"""
    t8_mesh_get_maximum_support(mesh)

Return the maximum of the length of the support of any local element.

### Prototype
```c
int t8_mesh_get_maximum_support (t8_mesh_t *mesh);
```
"""
function t8_mesh_get_maximum_support(mesh)
    @ccall libt8.t8_mesh_get_maximum_support(mesh::Ptr{t8_mesh_t})::Cint
end

"""
    t8_mesh_get_element_support(mesh, locid, length_support, elemid, orientation)

### Parameters
* `length_support`:\\[in,out\\]
### Prototype
```c
void t8_mesh_get_element_support (t8_mesh_t *mesh, t8_locidx_t locid, int *length_support, t8_locidx_t *elemid, int *orientation);
```
"""
function t8_mesh_get_element_support(mesh, locid, length_support, elemid, orientation)
    @ccall libt8.t8_mesh_get_element_support(mesh::Ptr{t8_mesh_t}, locid::t8_locidx_t, length_support::Ptr{Cint}, elemid::Ptr{t8_locidx_t}, orientation::Ptr{Cint})::Cvoid
end

"""
    t8_mesh_destroy(mesh)

*************************** destruct ************************

### Prototype
```c
void t8_mesh_destroy (t8_mesh_t *mesh);
```
"""
function t8_mesh_destroy(mesh)
    @ccall libt8.t8_mesh_destroy(mesh::Ptr{t8_mesh_t})::Cvoid
end

const t8_nc_int64_t = Int64

const t8_nc_int32_t = Int32

"""
    t8_netcdf_create_var(var_type, var_name, var_long_name, var_unit, var_data)

Create an extern double variable which additionally should be put out to the NetCDF File

### Parameters
* `var_type`:\\[in\\] Defines the datatype of the variable, either T8\\_NETCDF\\_INT, T8\\_NETCDF\\_INT64 or T8\\_NETCDF\\_DOUBLE.
* `var_name`:\\[in\\] A String which will be the name of the created variable.
* `var_long_name`:\\[in\\] A string describing the variable a bit more and what it is about.
* `var_unit`:\\[in\\] The units in which the data is provided.
* `var_data`:\\[in\\] A [`sc_array_t`](@ref) holding the elementwise data of the variable.
* `num_extern_netcdf_vars`:\\[in\\] The number of extern user-defined variables which hold elementwise data (if none, set it to 0).
### Prototype
```c
t8_netcdf_variable_t *t8_netcdf_create_var (t8_netcdf_variable_type_t var_type, const char *var_name, const char *var_long_name, const char *var_unit, sc_array_t *var_data);
```
"""
function t8_netcdf_create_var(var_type, var_name, var_long_name, var_unit, var_data)
    @ccall libt8.t8_netcdf_create_var(var_type::t8_netcdf_variable_type_t, var_name::Cstring, var_long_name::Cstring, var_unit::Cstring, var_data::Ptr{sc_array_t})::Ptr{t8_netcdf_variable_t}
end

"""
    t8_netcdf_create_integer_var(var_name, var_long_name, var_unit, var_data)

Create an extern integer variable which additionally should be put out to the NetCDF File (The disctinction if it wille be a NC\\_INT or NC\\_INT64 variable is based on the elementsize of the given [`sc_array_t`](@ref))

### Parameters
* `var_name`:\\[in\\] A String which will be the name of the created variable.
* `var_long_name`:\\[in\\] A string describing the variable a bit more and what it is about.
* `var_unit`:\\[in\\] The units in which the data is provided.
* `var_data`:\\[in\\] A [`sc_array_t`](@ref) holding the elementwise data of the variable.
* `num_extern_netcdf_vars`:\\[in\\] The number of extern user-defined variables which hold elementwise data (if none, set it to 0).
### Prototype
```c
t8_netcdf_variable_t *t8_netcdf_create_integer_var (const char *var_name, const char *var_long_name, const char *var_unit, sc_array_t *var_data);
```
"""
function t8_netcdf_create_integer_var(var_name, var_long_name, var_unit, var_data)
    @ccall libt8.t8_netcdf_create_integer_var(var_name::Cstring, var_long_name::Cstring, var_unit::Cstring, var_data::Ptr{sc_array_t})::Ptr{t8_netcdf_variable_t}
end

"""
    t8_netcdf_create_double_var(var_name, var_long_name, var_unit, var_data)

Create an extern double variable which additionally should be put out to the NetCDF File

### Parameters
* `var_name`:\\[in\\] A String which will be the name of the created variable.
* `var_long_name`:\\[in\\] A string describing the variable a bit more and what it is about.
* `var_unit`:\\[in\\] The units in which the data is provided.
* `var_data`:\\[in\\] A [`sc_array_t`](@ref) holding the elementwise data of the variable.
* `num_extern_netcdf_vars`:\\[in\\] The number of extern user-defined variables which hold elementwise data (if none, set it to 0).
### Prototype
```c
t8_netcdf_variable_t *t8_netcdf_create_double_var (const char *var_name, const char *var_long_name, const char *var_unit, sc_array_t *var_data);
```
"""
function t8_netcdf_create_double_var(var_name, var_long_name, var_unit, var_data)
    @ccall libt8.t8_netcdf_create_double_var(var_name::Cstring, var_long_name::Cstring, var_unit::Cstring, var_data::Ptr{sc_array_t})::Ptr{t8_netcdf_variable_t}
end

"""
    t8_netcdf_variable_destroy(var_destroy)

Free the allocated memory of the a [`t8_netcdf_variable_t`](@ref)

### Parameters
* `var_destroy`:\\[in\\] A t8\\_netcdf\\_t variable whose allocated memory should be freed.
### Prototype
```c
void t8_netcdf_variable_destroy (t8_netcdf_variable_t * var_destroy);
```
"""
function t8_netcdf_variable_destroy(var_destroy)
    @ccall libt8.t8_netcdf_variable_destroy(var_destroy::Ptr{t8_netcdf_variable_t})::Cvoid
end

"""We can reuse the reference counter type from libsc."""
const t8_refcount_t = sc_refcount_t

"""
    t8_refcount_init(rc)

Initialize a reference counter to 1. It is legal if its status prior to this call is undefined.

### Parameters
* `rc`:\\[out\\] The reference counter is set to one by this call.
### Prototype
```c
void t8_refcount_init (t8_refcount_t *rc);
```
"""
function t8_refcount_init(rc)
    @ccall libt8.t8_refcount_init(rc::Ptr{t8_refcount_t})::Cvoid
end

"""
    t8_refcount_new()

Create a new reference counter with count initialized to 1. Equivalent to calling [`t8_refcount_init`](@ref) on a newly allocated refcount\\_t. It is mandatory to free this with t8_refcount_destroy.

### Returns
An allocated reference counter whose count has been set to one.
### Prototype
```c
t8_refcount_t *t8_refcount_new (void);
```
"""
function t8_refcount_new()
    @ccall libt8.t8_refcount_new()::Ptr{t8_refcount_t}
end

"""
    t8_refcount_destroy(rc)

Destroy a reference counter that we allocated with t8_refcount_new. Its reference count must have decreased to zero.

### Parameters
* `rc`:\\[in,out\\] Allocated, formerly valid reference counter.
### Prototype
```c
void t8_refcount_destroy (t8_refcount_t *rc);
```
"""
function t8_refcount_destroy(rc)
    @ccall libt8.t8_refcount_destroy(rc::Ptr{t8_refcount_t})::Cvoid
end

"""
    t8_step3_main(argc, argv)

This is the main program of this example. It creates a coarse mesh and a forest, adapts the forest and writes some output.

### Prototype
```c
int t8_step3_main (int argc, char **argv);
```
"""
function t8_step3_main(argc, argv)
    @ccall libt8.t8_step3_main(argc::Cint, argv::Ptr{Cstring})::Cint
end

"""
    t8_step3_print_forest_information(forest)

Print the local and global number of elements of a forest.

### Prototype
```c
void t8_step3_print_forest_information (t8_forest_t forest);
```
"""
function t8_step3_print_forest_information(forest)
    @ccall libt8.t8_step3_print_forest_information(forest::t8_forest_t)::Cvoid
end

struct t8_step3_adapt_data
    midpoint::NTuple{3, Cdouble}
    refine_if_inside_radius::Cdouble
    coarsen_if_outside_radius::Cdouble
end

"""
    t8_step3_adapt_forest(forest)

Adapt a forest according to our [`t8_step3_adapt_callback`](@ref) function. Thus, the input forest will get refined inside a sphere  of radius 0.2 around (0.5, 0.5, 0.5) and coarsened outside of radius 0.4.

### Parameters
* `forest`:\\[in\\] A committed forest.
### Returns
A new forest that arises from the input *forest* via adaptation.
### Prototype
```c
t8_forest_t t8_step3_adapt_forest (t8_forest_t forest);
```
"""
function t8_step3_adapt_forest(forest)
    @ccall libt8.t8_step3_adapt_forest(forest::t8_forest_t)::t8_forest_t
end

"""
    t8_step3_adapt_callback(forest, forest_from, which_tree, lelement_id, ts, is_family, num_elements, elements)

### Prototype
```c
int t8_step3_adapt_callback (t8_forest_t forest, t8_forest_t forest_from, t8_locidx_t which_tree, t8_locidx_t lelement_id, t8_eclass_scheme_c *ts, const int is_family, const int num_elements, t8_element_t *elements[]);
```
"""
function t8_step3_adapt_callback(forest, forest_from, which_tree, lelement_id, ts, is_family, num_elements, elements)
    @ccall libt8.t8_step3_adapt_callback(forest::t8_forest_t, forest_from::t8_forest_t, which_tree::t8_locidx_t, lelement_id::t8_locidx_t, ts::Ptr{t8_eclass_scheme_c}, is_family::Cint, num_elements::Cint, elements::Ptr{Ptr{t8_element_t}})::Cint
end

"""
    t8_step4_main(argc, argv)

This is the main program of this example.

### Prototype
```c
int t8_step4_main (int argc, char **argv);
```
"""
function t8_step4_main(argc, argv)
    @ccall libt8.t8_step4_main(argc::Cint, argv::Ptr{Cstring})::Cint
end

"""
    t8_step5_main(argc, argv)

This is the main program of this example.

### Prototype
```c
int t8_step5_main (int argc, char **argv);
```
"""
function t8_step5_main(argc, argv)
    @ccall libt8.t8_step5_main(argc::Cint, argv::Ptr{Cstring})::Cint
end

"""
    t8_step6_main(argc, argv)

This is the main program of this example.

### Prototype
```c
int t8_step6_main (int argc, char **argv);
```
"""
function t8_step6_main(argc, argv)
    @ccall libt8.t8_step6_main(argc::Cint, argv::Ptr{Cstring})::Cint
end

"""
    t8_vec_norm(vec)

Vector norm.

### Parameters
* `vec`:\\[in\\] A 3D vector.
### Returns
The norm of *vec*.
### Prototype
```c
double t8_vec_norm (const double vec[3]);
```
"""
function t8_vec_norm(vec)
    @ccall libt8.t8_vec_norm(vec::Ptr{Cdouble})::Cdouble
end

"""
    t8_vec_dist(vec_x, vec_y)

Euclidean distance of X and Y.

### Parameters
* `vec_x`:\\[in\\] A 3D vector.
* `vec_y`:\\[in\\] A 3D vector.
### Returns
The euclidean distance. Equivalent to norm (X-Y).
### Prototype
```c
double t8_vec_dist (const double vec_x[3], const double vec_y[3]);
```
"""
function t8_vec_dist(vec_x, vec_y)
    @ccall libt8.t8_vec_dist(vec_x::Ptr{Cdouble}, vec_y::Ptr{Cdouble})::Cdouble
end

"""
    t8_vec_ax(vec_x, alpha)

Compute X = alpha * X

### Parameters
* `vec_x`:\\[in,out\\] A 3D vector. On output set to *alpha* * *vec_x*.
* `alpha`:\\[in\\] A factor.
### Prototype
```c
void t8_vec_ax (double vec_x[3], const double alpha);
```
"""
function t8_vec_ax(vec_x, alpha)
    @ccall libt8.t8_vec_ax(vec_x::Ptr{Cdouble}, alpha::Cdouble)::Cvoid
end

"""
    t8_vec_axy(vec_x, vec_y, alpha)

Compute Y = alpha * X

### Parameters
* `vec_x`:\\[in\\] A 3D vector.
* `vec_z`:\\[out\\] On output set to *alpha* * *vec_x*.
* `alpha`:\\[in\\] A factor.
### Prototype
```c
void t8_vec_axy (const double vec_x[3], double vec_y[3], const double alpha);
```
"""
function t8_vec_axy(vec_x, vec_y, alpha)
    @ccall libt8.t8_vec_axy(vec_x::Ptr{Cdouble}, vec_y::Ptr{Cdouble}, alpha::Cdouble)::Cvoid
end

"""
    t8_vec_axb(vec_x, vec_y, alpha, b)

Y = alpha * X + b

!!! note

    It is possible that vec\\_x = vec\\_y on input to overwrite x

### Parameters
* `vec_x`:\\[in\\] A 3D vector.
* `vec_y`:\\[out\\] On input, a 3D vector. On output set to *alpha* * *vec_x* + *b*.
* `alpha`:\\[in\\] A factor.
* `b`:\\[in\\] An offset.
### Prototype
```c
void t8_vec_axb (const double vec_x[3], double vec_y[3], const double alpha, const double b);
```
"""
function t8_vec_axb(vec_x, vec_y, alpha, b)
    @ccall libt8.t8_vec_axb(vec_x::Ptr{Cdouble}, vec_y::Ptr{Cdouble}, alpha::Cdouble, b::Cdouble)::Cvoid
end

"""
    t8_vec_axpy(vec_x, vec_y, alpha)

Y = Y + alpha * X

### Parameters
* `vec_x`:\\[in\\] A 3D vector.
* `vec_y`:\\[in,out\\] On input, a 3D vector. On output set *to* vec\\_y + *alpha* * *vec_x*
* `alpha`:\\[in\\] A factor.
### Prototype
```c
void t8_vec_axpy (const double vec_x[3], double vec_y[3], const double alpha);
```
"""
function t8_vec_axpy(vec_x, vec_y, alpha)
    @ccall libt8.t8_vec_axpy(vec_x::Ptr{Cdouble}, vec_y::Ptr{Cdouble}, alpha::Cdouble)::Cvoid
end

"""
    t8_vec_axpyz(vec_x, vec_y, vec_z, alpha)

Z = Y + alpha * X

### Parameters
* `vec_x`:\\[in\\] A 3D vector.
* `vec_y`:\\[in\\] A 3D vector.
* `vec_z`:\\[out\\] On output set *to* vec\\_y + *alpha* * *vec_x*
### Prototype
```c
void t8_vec_axpyz (const double vec_x[3], const double vec_y[3], double vec_z[3], const double alpha);
```
"""
function t8_vec_axpyz(vec_x, vec_y, vec_z, alpha)
    @ccall libt8.t8_vec_axpyz(vec_x::Ptr{Cdouble}, vec_y::Ptr{Cdouble}, vec_z::Ptr{Cdouble}, alpha::Cdouble)::Cvoid
end

"""
    t8_vec_dot(vec_x, vec_y)

Dot product of X and Y.

### Parameters
* `vec_x`:\\[in\\] A 3D vector.
* `vec_y`:\\[in\\] A 3D vector.
### Returns
The dot product *vec_x* * *vec_y*
### Prototype
```c
double t8_vec_dot (const double vec_x[3], const double vec_y[3]);
```
"""
function t8_vec_dot(vec_x, vec_y)
    @ccall libt8.t8_vec_dot(vec_x::Ptr{Cdouble}, vec_y::Ptr{Cdouble})::Cdouble
end

"""
    t8_vec_cross(vec_x, vec_y, cross)

Cross product of X and Y

### Parameters
* `vec_x`:\\[in\\] A 3D vector.
* `vec_y`:\\[in\\] A 3D vector.
* `cross`:\\[out\\] On output, the cross product of *vec_x* and *vec_y*.
### Prototype
```c
void t8_vec_cross (const double vec_x[3], const double vec_y[3], double cross[3]);
```
"""
function t8_vec_cross(vec_x, vec_y, cross)
    @ccall libt8.t8_vec_cross(vec_x::Ptr{Cdouble}, vec_y::Ptr{Cdouble}, cross::Ptr{Cdouble})::Cvoid
end

# no prototype is found for this function at t8_version.h:67:21, please use with caution
"""
    t8_get_package_string()

Return the package string of t8code. This string has the format "t8 version\\_number".

### Returns
The version string of t8code.
### Prototype
```c
const char *t8_get_package_string ();
```
"""
function t8_get_package_string()
    @ccall libt8.t8_get_package_string()::Cstring
end

# no prototype is found for this function at t8_version.h:72:21, please use with caution
"""
    t8_get_version_number()

Return the version number of t8code as a string.

### Returns
The version number of t8code as a string.
### Prototype
```c
const char *t8_get_version_number ();
```
"""
function t8_get_version_number()
    @ccall libt8.t8_get_version_number()::Cstring
end

# no prototype is found for this function at t8_version.h:77:21, please use with caution
"""
    t8_get_version_point_string()

Return the version point string.

### Returns
The version point point string.
### Prototype
```c
const char *t8_get_version_point_string ();
```
"""
function t8_get_version_point_string()
    @ccall libt8.t8_get_version_point_string()::Cstring
end

# no prototype is found for this function at t8_version.h:82:21, please use with caution
"""
    t8_get_version_major()

Return the major version number of t8code.

### Returns
The major version number of t8code.
### Prototype
```c
int t8_get_version_major ();
```
"""
function t8_get_version_major()
    @ccall libt8.t8_get_version_major()::Cint
end

# no prototype is found for this function at t8_version.h:87:21, please use with caution
"""
    t8_get_version_minor()

Return the minor version number of t8code.

### Returns
The minor version number of t8code.
### Prototype
```c
int t8_get_version_minor ();
```
"""
function t8_get_version_minor()
    @ccall libt8.t8_get_version_minor()::Cint
end

# no prototype is found for this function at t8_version.h:96:21, please use with caution
"""
    t8_get_version_patch()

Return the patch version number of t8code.

!!! note


### Returns
The patch version unmber of t8code. negative on error.
### Prototype
```c
int t8_get_version_patch ();
```
"""
function t8_get_version_patch()
    @ccall libt8.t8_get_version_patch()::Cint
end

@cenum t8_vtk_data_type_t::UInt32 begin
    T8_VTK_SCALAR = 0
    T8_VTK_VECTOR = 1
end

"""
    t8_vtk_data_field_t

| Field       | Note                                       |
| :---------- | :----------------------------------------- |
| type        | Describes of which type the data array is  |
| description | String that describes the data.            |
"""
struct t8_vtk_data_field_t
    type::t8_vtk_data_type_t
    description::NTuple{8192, Cchar}
    data::Ptr{Cdouble}
end

"""
    t8_write_pvtu(filename, num_procs, write_tree, write_rank, write_level, write_id, num_data, data)

### Prototype
```c
int t8_write_pvtu (const char *filename, int num_procs, int write_tree, int write_rank, int write_level, int write_id, int num_data, t8_vtk_data_field_t *data);
```
"""
function t8_write_pvtu(filename, num_procs, write_tree, write_rank, write_level, write_id, num_data, data)
    @ccall libt8.t8_write_pvtu(filename::Cstring, num_procs::Cint, write_tree::Cint, write_rank::Cint, write_level::Cint, write_id::Cint, num_data::Cint, data::Ptr{t8_vtk_data_field_t})::Cint
end

"""
    sc_io_read(mpifile, ptr, zcount, t, errmsg)

### Prototype
```c
void sc_io_read (sc_MPI_File mpifile, void *ptr, size_t zcount, sc_MPI_Datatype t, const char *errmsg);
```
"""
function sc_io_read(mpifile, ptr, zcount, t, errmsg)
    @ccall libsc.sc_io_read(mpifile::MPI_File, ptr::Ptr{Cvoid}, zcount::Csize_t, t::MPI_Datatype, errmsg::Cstring)::Cvoid
end

"""
    sc_io_write(mpifile, ptr, zcount, t, errmsg)

### Prototype
```c
void sc_io_write (sc_MPI_File mpifile, const void *ptr, size_t zcount, sc_MPI_Datatype t, const char *errmsg);
```
"""
function sc_io_write(mpifile, ptr, zcount, t, errmsg)
    @ccall libsc.sc_io_write(mpifile::MPI_File, ptr::Ptr{Cvoid}, zcount::Csize_t, t::MPI_Datatype, errmsg::Cstring)::Cvoid
end

"""Typedef for quadrant coordinates."""
const p4est_qcoord_t = Int32

"""Typedef for counting topological entities (trees, tree vertices)."""
const p4est_topidx_t = Int32

"""Typedef for processor-local indexing of quadrants and nodes."""
const p4est_locidx_t = Int32

"""Typedef for globally unique indexing of quadrants."""
const p4est_gloidx_t = Int64

"""
    sc_io_error_t

Error values for io.

| Enumerator              | Note                                                                         |
| :---------------------- | :--------------------------------------------------------------------------- |
| SC\\_IO\\_ERROR\\_NONE  | The value of zero means no error.                                            |
| SC\\_IO\\_ERROR\\_FATAL | The io object is now dysfunctional.                                          |
| SC\\_IO\\_ERROR\\_AGAIN | Another io operation may resolve it. The function just returned was a noop.  |
"""
@cenum sc_io_error_t::Int32 begin
    SC_IO_ERROR_NONE = 0
    SC_IO_ERROR_FATAL = -1
    SC_IO_ERROR_AGAIN = -2
end

"""
    sc_io_mode_t

| Enumerator              | Note                         |
| :---------------------- | :--------------------------- |
| SC\\_IO\\_MODE\\_WRITE  | Semantics as "w" in fopen.   |
| SC\\_IO\\_MODE\\_APPEND | Semantics as "a" in fopen.   |
| SC\\_IO\\_MODE\\_LAST   | Invalid entry to close list  |
"""
@cenum sc_io_mode_t::UInt32 begin
    SC_IO_MODE_WRITE = 0
    SC_IO_MODE_APPEND = 1
    SC_IO_MODE_LAST = 2
end

"""
    sc_io_encode_t

| Enumerator              | Note                         |
| :---------------------- | :--------------------------- |
| SC\\_IO\\_ENCODE\\_LAST | Invalid entry to close list  |
"""
@cenum sc_io_encode_t::UInt32 begin
    SC_IO_ENCODE_NONE = 0
    SC_IO_ENCODE_LAST = 1
end

"""
    sc_io_type_t

| Enumerator            | Note                         |
| :-------------------- | :--------------------------- |
| SC\\_IO\\_TYPE\\_LAST | Invalid entry to close list  |
"""
@cenum sc_io_type_t::UInt32 begin
    SC_IO_TYPE_BUFFER = 0
    SC_IO_TYPE_FILENAME = 1
    SC_IO_TYPE_FILEFILE = 2
    SC_IO_TYPE_LAST = 3
end

"""
    sc_io_sink

| Field          | Note                          |
| :------------- | :---------------------------- |
| buffer\\_bytes | distinguish from array elems  |
"""
struct sc_io_sink
    iotype::sc_io_type_t
    mode::sc_io_mode_t
    encode::sc_io_encode_t
    buffer::Ptr{sc_array_t}
    buffer_bytes::Csize_t
    file::Ptr{Libc.FILE}
    bytes_in::Csize_t
    bytes_out::Csize_t
end

const sc_io_sink_t = sc_io_sink

"""
    sc_io_source

| Field          | Note                          |
| :------------- | :---------------------------- |
| buffer\\_bytes | distinguish from array elems  |
"""
struct sc_io_source
    iotype::sc_io_type_t
    encode::sc_io_encode_t
    buffer::Ptr{sc_array_t}
    buffer_bytes::Csize_t
    file::Ptr{Libc.FILE}
    bytes_in::Csize_t
    bytes_out::Csize_t
    mirror::Ptr{sc_io_sink_t}
    mirror_buffer::Ptr{sc_array_t}
end

const sc_io_source_t = sc_io_source

"""
    sc_io_open_mode_t

Open modes for sc_io_open

| Enumerator               | Note                                                                              |
| :----------------------- | :-------------------------------------------------------------------------------- |
| SC\\_IO\\_READ           | open a file in read-only mode                                                     |
| SC\\_IO\\_WRITE\\_CREATE | open a file in write-only mode; if the file exists, the file will be overwritten  |
| SC\\_IO\\_WRITE\\_APPEND | append to an already existing file                                                |
"""
@cenum sc_io_open_mode_t::UInt32 begin
    SC_IO_READ = 0
    SC_IO_WRITE_CREATE = 1
    SC_IO_WRITE_APPEND = 2
end

# automatic type deduction for variadic arguments may not be what you want, please use with caution
@generated function sc_io_sink_new(iotype, iomode, ioencode, va_list...)
        :(@ccall(libsc.sc_io_sink_new(iotype::Cint, iomode::Cint, ioencode::Cint; $(to_c_type_pairs(va_list)...))::Ptr{sc_io_sink_t}))
    end

"""
    sc_io_sink_destroy(sink)

Free data sink. Calls [`sc_io_sink_complete`](@ref) and discards the final counts. Errors from complete lead to SC\\_IO\\_ERROR\\_FATAL returned from this function. Call [`sc_io_sink_complete`](@ref) yourself if bytes\\_out is of interest.

### Parameters
* `sink`:\\[in,out\\] The sink object to complete and free.
### Returns
0 on success, nonzero on error.
### Prototype
```c
int sc_io_sink_destroy (sc_io_sink_t * sink);
```
"""
function sc_io_sink_destroy(sink)
    @ccall libsc.sc_io_sink_destroy(sink::Ptr{sc_io_sink_t})::Cint
end

"""
    sc_io_sink_write(sink, data, bytes_avail)

Write data to a sink. Data may be buffered and sunk in a later call. The internal counters sink->bytes\\_in and sink->bytes\\_out are updated.

### Parameters
* `sink`:\\[in,out\\] The sink object to write to.
* `data`:\\[in\\] Data passed into sink.
* `bytes_avail`:\\[in\\] Number of data bytes passed in.
### Returns
0 on success, nonzero on error.
### Prototype
```c
int sc_io_sink_write (sc_io_sink_t * sink, const void *data, size_t bytes_avail);
```
"""
function sc_io_sink_write(sink, data, bytes_avail)
    @ccall libsc.sc_io_sink_write(sink::Ptr{sc_io_sink_t}, data::Ptr{Cvoid}, bytes_avail::Csize_t)::Cint
end

"""
    sc_io_sink_complete(sink, bytes_in, bytes_out)

Flush all buffered output data to sink. This function may return SC\\_IO\\_ERROR\\_AGAIN if another write is required. Currently this may happen if BUFFER requires an integer multiple of bytes. If successful, the updated value of bytes read and written is returned in bytes\\_in/out, and the sink status is reset as if the sink had just been created. In particular, the bytes counters are reset to zero. The internal state of the sink is not changed otherwise. It is legal to continue writing to the sink hereafter. The sink actions taken depend on its type. BUFFER, FILEFILE: none. FILENAME: call fclose on sink->file.

### Parameters
* `sink`:\\[in,out\\] The sink object to write to.
* `bytes_in`:\\[in,out\\] Bytes received since the last new or complete call. May be NULL.
* `bytes_out`:\\[in,out\\] Bytes written since the last new or complete call. May be NULL.
### Returns
0 if completed, nonzero on error.
### Prototype
```c
int sc_io_sink_complete (sc_io_sink_t * sink, size_t *bytes_in, size_t *bytes_out);
```
"""
function sc_io_sink_complete(sink, bytes_in, bytes_out)
    @ccall libsc.sc_io_sink_complete(sink::Ptr{sc_io_sink_t}, bytes_in::Ptr{Csize_t}, bytes_out::Ptr{Csize_t})::Cint
end

"""
    sc_io_sink_align(sink, bytes_align)

Align sink to a byte boundary by writing zeros.

### Parameters
* `sink`:\\[in,out\\] The sink object to align.
* `bytes_align`:\\[in\\] Byte boundary.
### Returns
0 on success, nonzero on error.
### Prototype
```c
int sc_io_sink_align (sc_io_sink_t * sink, size_t bytes_align);
```
"""
function sc_io_sink_align(sink, bytes_align)
    @ccall libsc.sc_io_sink_align(sink::Ptr{sc_io_sink_t}, bytes_align::Csize_t)::Cint
end

# automatic type deduction for variadic arguments may not be what you want, please use with caution
@generated function sc_io_source_new(iotype, ioencode, va_list...)
        :(@ccall(libsc.sc_io_source_new(iotype::Cint, ioencode::Cint; $(to_c_type_pairs(va_list)...))::Ptr{sc_io_source_t}))
    end

"""
    sc_io_source_destroy(source)

Free data source. Calls [`sc_io_source_complete`](@ref) and requires it to return no error. This is to avoid discarding buffered data that has not been passed to read.

### Parameters
* `source`:\\[in,out\\] The source object to free.
### Returns
0 on success. Nonzero if an error is encountered or is\\_complete returns one.
### Prototype
```c
int sc_io_source_destroy (sc_io_source_t * source);
```
"""
function sc_io_source_destroy(source)
    @ccall libsc.sc_io_source_destroy(source::Ptr{sc_io_source_t})::Cint
end

"""
    sc_io_source_read(source, data, bytes_avail, bytes_out)

Read data from a source. The internal counters source->bytes\\_in and source->bytes\\_out are updated. Data is read until the data buffer has not enough room anymore, or source becomes empty. It is possible that data already read internally remains in the source object for the next call. Call [`sc_io_source_complete`](@ref) and check its return value to find out. Returns an error if bytes\\_out is NULL and less than bytes\\_avail are read.

### Parameters
* `source`:\\[in,out\\] The source object to read from.
* `data`:\\[in\\] Data buffer for reading from sink. If NULL the output data will be thrown away.
* `bytes_avail`:\\[in\\] Number of bytes available in data buffer.
* `bytes_out`:\\[in,out\\] If not NULL, byte count read into data buffer. Otherwise, requires to read exactly bytes\\_avail.
### Returns
0 on success, nonzero on error.
### Prototype
```c
int sc_io_source_read (sc_io_source_t * source, void *data, size_t bytes_avail, size_t *bytes_out);
```
"""
function sc_io_source_read(source, data, bytes_avail, bytes_out)
    @ccall libsc.sc_io_source_read(source::Ptr{sc_io_source_t}, data::Ptr{Cvoid}, bytes_avail::Csize_t, bytes_out::Ptr{Csize_t})::Cint
end

"""
    sc_io_source_complete(source, bytes_in, bytes_out)

Determine whether all data buffered from source has been returned by read. If it returns SC\\_IO\\_ERROR\\_AGAIN, another [`sc_io_source_read`](@ref) is required. If the call returns no error, the internal counters source->bytes\\_in and source->bytes\\_out are returned to the caller if requested, and reset to 0. The internal state of the source is not changed otherwise. It is legal to continue reading from the source hereafter.

### Parameters
* `source`:\\[in,out\\] The source object to read from.
* `bytes_in`:\\[in,out\\] If not NULL and true is returned, the total size of the data sourced.
* `bytes_out`:\\[in,out\\] If not NULL and true is returned, total bytes passed out by source\\_read.
### Returns
SC\\_IO\\_ERROR\\_AGAIN if buffered data remaining. Otherwise return ERROR\\_NONE and reset counters.
### Prototype
```c
int sc_io_source_complete (sc_io_source_t * source, size_t *bytes_in, size_t *bytes_out);
```
"""
function sc_io_source_complete(source, bytes_in, bytes_out)
    @ccall libsc.sc_io_source_complete(source::Ptr{sc_io_source_t}, bytes_in::Ptr{Csize_t}, bytes_out::Ptr{Csize_t})::Cint
end

"""
    sc_io_source_align(source, bytes_align)

Align source to a byte boundary by skipping.

### Parameters
* `source`:\\[in,out\\] The source object to align.
* `bytes_align`:\\[in\\] Byte boundary.
### Returns
0 on success, nonzero on error.
### Prototype
```c
int sc_io_source_align (sc_io_source_t * source, size_t bytes_align);
```
"""
function sc_io_source_align(source, bytes_align)
    @ccall libsc.sc_io_source_align(source::Ptr{sc_io_source_t}, bytes_align::Csize_t)::Cint
end

"""
    sc_io_source_activate_mirror(source)

Activate a buffer that mirrors (i.e., stores) the data that was read.

### Parameters
* `source`:\\[in,out\\] The source object to activate mirror in.
### Returns
0 on success, nonzero on error.
### Prototype
```c
int sc_io_source_activate_mirror (sc_io_source_t * source);
```
"""
function sc_io_source_activate_mirror(source)
    @ccall libsc.sc_io_source_activate_mirror(source::Ptr{sc_io_source_t})::Cint
end

"""
    sc_io_source_read_mirror(source, data, bytes_avail, bytes_out)

Read data from the source's mirror. Same behaviour as [`sc_io_source_read`](@ref).

### Parameters
* `source`:\\[in,out\\] The source object to read mirror data from.
### Returns
0 on success, nonzero on error.
### Prototype
```c
int sc_io_source_read_mirror (sc_io_source_t * source, void *data, size_t bytes_avail, size_t *bytes_out);
```
"""
function sc_io_source_read_mirror(source, data, bytes_avail, bytes_out)
    @ccall libsc.sc_io_source_read_mirror(source::Ptr{sc_io_source_t}, data::Ptr{Cvoid}, bytes_avail::Csize_t, bytes_out::Ptr{Csize_t})::Cint
end

"""
    sc_io_have_zlib()

Return a boolean indicating whether zlib has been configured.

### Returns
True if zlib has been found on running configure, or respectively on calling cmake.
### Prototype
```c
int sc_io_have_zlib (void);
```
"""
function sc_io_have_zlib()
    @ccall libsc.sc_io_have_zlib()::Cint
end

"""
    sc_io_encode(data, out)

Encode a block of arbitrary data with the default sc\\_io format. The corresponding decoder function is sc_io_decode. This function cannot crash unless out of memory.

Currently this function calls sc_io_encode_zlib with compression level Z\\_BEST\\_COMPRESSION (subject to change). Without zlib configured that function works uncompressed.

The encoding method and input data size can be retrieved, optionally, from the encoded data by sc_io_decode_info. This function decodes the method as a character, which is 'z' for sc_io_encode_zlib. We reserve the characters A-C, d-z indefinitely.

### Parameters
* `data`:\\[in,out\\] If *out* is NULL, we work in place. In this case, the array must on input have an element size of 1 byte, which is preserved. After reading all data from this array, it assumes the identity of the *out* argument below. Otherwise, this is a read-only argument that may have arbitrary element size. On input, all data in the array is used.
* `out`:\\[in,out\\] If not NULL, a valid array of element size 1. It must be resizable (not a view). We resize the array to the output data, which always includes a final terminating zero.
### Prototype
```c
void sc_io_encode (sc_array_t *data, sc_array_t *out);
```
"""
function sc_io_encode(data, out)
    @ccall libsc.sc_io_encode(data::Ptr{sc_array_t}, out::Ptr{sc_array_t})::Cvoid
end

"""
    sc_io_encode_zlib(data, out, zlib_compression_level)

Encode a block of arbitrary data, compressed, into an ASCII string. This is a two-stage process: zlib compress and then encode to base 64. The output is a NUL-terminated string of printable characters.

We first compress the data into the zlib format (RFC 1950). The compressor must use no preset dictionary (this is the default). If zlib is detected on configuration, we compress with given level. If zlib is not detected, we write data equivalent to Z\\_NO\\_COMPRESSION. The status of zlib detection can be queried at compile time using #ifdef [`SC_HAVE_ZLIB`](@ref) or at run time using sc_io_have_zlib. Both approaches are readable by a standard zlib uncompress call.

Secondly, we process the input data size as an 8-byte big-endian number, then the letter 'z', and then the zlib compressed data, concatenated, with a base 64 encoder. We break lines after 72 code characters. The line breaks are considered part of the output data format. The last line is terminated with a line break and then a NUL.

This routine can work in place or write to an output array. The corresponding decoder function is sc_io_decode. This function cannot crash unless out of memory.

### Parameters
* `data`:\\[in,out\\] If *out* is NULL, we work in place. In this case, the array must on input have an element size of 1 byte, which is preserved. After reading all data from this array, it assumes the identity of the *out* argument below. Otherwise, this is a read-only argument that may have arbitrary element size. On input, all data in the array is used.
* `out`:\\[in,out\\] If not NULL, a valid array of element size 1. It must be resizable (not a view). We resize the array to the output data, which always includes a final terminating zero.
* `zlib_compression_level`:\\[in\\] Compression level between 0 (no compression) and 9 (best compression). The value -1 indicates some default level.
### Prototype
```c
void sc_io_encode_zlib (sc_array_t *data, sc_array_t *out, int zlib_compression_level);
```
"""
function sc_io_encode_zlib(data, out, zlib_compression_level)
    @ccall libsc.sc_io_encode_zlib(data::Ptr{sc_array_t}, out::Ptr{sc_array_t}, zlib_compression_level::Cint)::Cvoid
end

"""
    sc_io_decode_info(data, original_size, format_char, re)

Decode length and format of original input from encoded data. We expect at least 12 bytes of the format produced by sc_io_encode. No matter how much data has been encoded by it, this much is available. We decode the original data size and the character indicating the format.

This function does not require zlib. It works with any well-defined data.

Note that this function is not required before sc_io_decode. Calling this function on any result produced by sc_io_encode will succeed and report a legal format. This function cannot crash.

### Parameters
* `data`:\\[in\\] This must be an array with element size 1. If it contains less than 12 code bytes we error out. It its first 12 bytes do not base 64 decode to 9 bytes we error out. We generally ignore the remaining data.
* `original_size`:\\[out\\] If not NULL and we do not error out, set to the original size as encoded in the data.
* `format_char`:\\[out\\] If not NULL and we do not error out, the ninth character of decoded data indicating the format.
* `re`:\\[in,out\\] Provided for error reporting, presently must be NULL.
### Returns
0 on success, negative value on error.
### Prototype
```c
int sc_io_decode_info (sc_array_t *data, size_t *original_size, char *format_char, void *re);
```
"""
function sc_io_decode_info(data, original_size, format_char, re)
    @ccall libsc.sc_io_decode_info(data::Ptr{sc_array_t}, original_size::Ptr{Csize_t}, format_char::Cstring, re::Ptr{Cvoid})::Cint
end

"""
    sc_io_decode(data, out, max_original_size, re)

Decode a block of base 64 encoded compressed data. The base 64 data must contain a line break after every 72 code characters and a final NUL character right after the last line. This function does not require zlib but benefits for speed.

This is a two-stage process: we decode the input from base 64 first. Then we extract the 8-byte big-endian original data size, the character 'z', and execute a zlib decompression on the remaining decoded data. This function detects malformed input by erroring out.

If we should add another format in the future, the format character may be something else than 'z', as permitted by our specification. To this end, we reserve the characters A-C and d-z indefinitely.

Any error condition is indicated by a negative return value. Possible causes for error are:

- the input data string is not NUL-terminated - the first 12 characters of input do not decode properly - the input data is corrupt for decoding or decompression - the output data array has non-unit element size and the length of the output data is not divisible by the size - the output data would exceed the specified threshold - the output array is a view of insufficient length

We also error out if the data requires a compression dictionary, which would be a violation of above encode format specification.

The corresponding encode function is sc_io_encode. When passing an array as output, we resize it properly. This function cannot crash unless out of memory.

### Parameters
* `data`:\\[in,out\\] If *out* is NULL, we work in place. In that case, output is written into this array after a suitable resize. Either way, we expect a NUL-terminated base 64 encoded string on input that has in turn been obtained by zlib compression. It must be in the exact format produced by sc_io_encode; please see documentation. The element size of the input array must be 1.
* `out`:\\[in,out\\] If not NULL, a valid array (may be a view). If NULL, the input array becomes the output. If the output array is a view and the output data larger than its view size, we error out. We expect commensurable element and data size and resize the output to fit exactly, which restores the original input passed to encoding. An output view array of matching size may be constructed using sc_io_decode_info.
* `max_original_size`:\\[in\\] If nonzero, this is the maximal data size that we will accept after uncompression. If exceeded, return a negative value.
* `re`:\\[in,out\\] Provided for error reporting, presently must be NULL.
### Returns
0 on success, negative on malformed input data or insufficient output space.
### Prototype
```c
int sc_io_decode (sc_array_t *data, sc_array_t *out, size_t max_original_size, void *re);
```
"""
function sc_io_decode(data, out, max_original_size, re)
    @ccall libsc.sc_io_decode(data::Ptr{sc_array_t}, out::Ptr{sc_array_t}, max_original_size::Csize_t, re::Ptr{Cvoid})::Cint
end

"""
    sc_vtk_write_binary(vtkfile, numeric_data, byte_length)

This function writes numeric binary data in VTK base64 encoding.

### Parameters
* `vtkfile`: Stream opened for writing.
* `numeric_data`: A pointer to a numeric data array.
* `byte_length`: The length of the data array in bytes.
### Returns
Returns 0 on success, -1 on file error.
### Prototype
```c
int sc_vtk_write_binary (FILE * vtkfile, char *numeric_data, size_t byte_length);
```
"""
function sc_vtk_write_binary(vtkfile, numeric_data, byte_length)
    @ccall libsc.sc_vtk_write_binary(vtkfile::Ptr{Libc.FILE}, numeric_data::Cstring, byte_length::Csize_t)::Cint
end

"""
    sc_vtk_write_compressed(vtkfile, numeric_data, byte_length)

This function writes numeric binary data in VTK compressed format.

### Parameters
* `vtkfile`: Stream opened for writing.
* `numeric_data`: A pointer to a numeric data array.
* `byte_length`: The length of the data array in bytes.
### Returns
Returns 0 on success, -1 on file error.
### Prototype
```c
int sc_vtk_write_compressed (FILE * vtkfile, char *numeric_data, size_t byte_length);
```
"""
function sc_vtk_write_compressed(vtkfile, numeric_data, byte_length)
    @ccall libsc.sc_vtk_write_compressed(vtkfile::Ptr{Libc.FILE}, numeric_data::Cstring, byte_length::Csize_t)::Cint
end

"""
    sc_fopen(filename, mode, errmsg)

Wrapper for fopen(3). We provide an additional argument that contains the error message.

### Prototype
```c
FILE *sc_fopen (const char *filename, const char *mode, const char *errmsg);
```
"""
function sc_fopen(filename, mode, errmsg)
    @ccall libsc.sc_fopen(filename::Cstring, mode::Cstring, errmsg::Cstring)::Ptr{Libc.FILE}
end

"""
    sc_fwrite(ptr, size, nmemb, file, errmsg)

Write memory content to a file.

!!! note

    This function aborts on file errors.

### Parameters
* `ptr`:\\[in\\] Data array to write to disk.
* `size`:\\[in\\] Size of one array member.
* `nmemb`:\\[in\\] Number of array members.
* `file`:\\[in,out\\] File pointer, must be opened for writing.
* `errmsg`:\\[in\\] Error message passed to `SC_CHECK_ABORT`.
### Prototype
```c
void sc_fwrite (const void *ptr, size_t size, size_t nmemb, FILE * file, const char *errmsg);
```
"""
function sc_fwrite(ptr, size, nmemb, file, errmsg)
    @ccall libsc.sc_fwrite(ptr::Ptr{Cvoid}, size::Csize_t, nmemb::Csize_t, file::Ptr{Libc.FILE}, errmsg::Cstring)::Cvoid
end

"""
    sc_fread(ptr, size, nmemb, file, errmsg)

Read file content into memory.

!!! note

    This function aborts on file errors.

### Parameters
* `ptr`:\\[out\\] Data array to read from disk.
* `size`:\\[in\\] Size of one array member.
* `nmemb`:\\[in\\] Number of array members.
* `file`:\\[in,out\\] File pointer, must be opened for reading.
* `errmsg`:\\[in\\] Error message passed to `SC_CHECK_ABORT`.
### Prototype
```c
void sc_fread (void *ptr, size_t size, size_t nmemb, FILE * file, const char *errmsg);
```
"""
function sc_fread(ptr, size, nmemb, file, errmsg)
    @ccall libsc.sc_fread(ptr::Ptr{Cvoid}, size::Csize_t, nmemb::Csize_t, file::Ptr{Libc.FILE}, errmsg::Cstring)::Cvoid
end

"""
    sc_fflush_fsync_fclose(file)

Best effort to flush a file's data to disc and close it.

### Parameters
* `file`:\\[in,out\\] File open for writing.
### Prototype
```c
void sc_fflush_fsync_fclose (FILE * file);
```
"""
function sc_fflush_fsync_fclose(file)
    @ccall libsc.sc_fflush_fsync_fclose(file::Ptr{Libc.FILE})::Cvoid
end

"""
    sc_io_open(mpicomm, filename, amode, mpiinfo, mpifile)

### Prototype
```c
int sc_io_open (sc_MPI_Comm mpicomm, const char *filename, sc_io_open_mode_t amode, sc_MPI_Info mpiinfo, sc_MPI_File * mpifile);
```
"""
function sc_io_open(mpicomm, filename, amode, mpiinfo, mpifile)
    @ccall libsc.sc_io_open(mpicomm::MPI_Comm, filename::Cstring, amode::sc_io_open_mode_t, mpiinfo::Cint, mpifile::Ptr{Cint})::Cint
end

"""
    sc_io_read_at(mpifile, offset, ptr, zcount, t, ocount)

### Prototype
```c
int sc_io_read_at (sc_MPI_File mpifile, sc_MPI_Offset offset, void *ptr, int zcount, sc_MPI_Datatype t, int *ocount);
```
"""
function sc_io_read_at(mpifile, offset, ptr, zcount, t, ocount)
    @ccall libsc.sc_io_read_at(mpifile::MPI_File, offset::Cint, ptr::Ptr{Cvoid}, zcount::Cint, t::MPI_Datatype, ocount::Ptr{Cint})::Cint
end

"""
    sc_io_read_at_all(mpifile, offset, ptr, zcount, t, ocount)

### Prototype
```c
int sc_io_read_at_all (sc_MPI_File mpifile, sc_MPI_Offset offset, void *ptr, int zcount, sc_MPI_Datatype t, int *ocount);
```
"""
function sc_io_read_at_all(mpifile, offset, ptr, zcount, t, ocount)
    @ccall libsc.sc_io_read_at_all(mpifile::MPI_File, offset::Cint, ptr::Ptr{Cvoid}, zcount::Cint, t::MPI_Datatype, ocount::Ptr{Cint})::Cint
end

"""
    sc_io_read_all(mpifile, ptr, zcount, t, ocount)

### Prototype
```c
int sc_io_read_all (sc_MPI_File mpifile, void *ptr, int zcount, sc_MPI_Datatype t, int *ocount);
```
"""
function sc_io_read_all(mpifile, ptr, zcount, t, ocount)
    @ccall libsc.sc_io_read_all(mpifile::MPI_File, ptr::Ptr{Cvoid}, zcount::Cint, t::MPI_Datatype, ocount::Ptr{Cint})::Cint
end

"""
    sc_io_write_at(mpifile, offset, ptr, zcount, t, ocount)

### Prototype
```c
int sc_io_write_at (sc_MPI_File mpifile, sc_MPI_Offset offset, const void *ptr, size_t zcount, sc_MPI_Datatype t, int *ocount);
```
"""
function sc_io_write_at(mpifile, offset, ptr, zcount, t, ocount)
    @ccall libsc.sc_io_write_at(mpifile::MPI_File, offset::Cint, ptr::Ptr{Cvoid}, zcount::Csize_t, t::MPI_Datatype, ocount::Ptr{Cint})::Cint
end

"""
    sc_io_write_at_all(mpifile, offset, ptr, zcount, t, ocount)

### Prototype
```c
int sc_io_write_at_all (sc_MPI_File mpifile, sc_MPI_Offset offset, const void *ptr, size_t zcount, sc_MPI_Datatype t, int *ocount);
```
"""
function sc_io_write_at_all(mpifile, offset, ptr, zcount, t, ocount)
    @ccall libsc.sc_io_write_at_all(mpifile::MPI_File, offset::Cint, ptr::Ptr{Cvoid}, zcount::Csize_t, t::MPI_Datatype, ocount::Ptr{Cint})::Cint
end

"""
    sc_io_write_all(mpifile, ptr, zcount, t, ocount)

### Prototype
```c
int sc_io_write_all (sc_MPI_File mpifile, const void *ptr, size_t zcount, sc_MPI_Datatype t, int *ocount);
```
"""
function sc_io_write_all(mpifile, ptr, zcount, t, ocount)
    @ccall libsc.sc_io_write_all(mpifile::MPI_File, ptr::Ptr{Cvoid}, zcount::Csize_t, t::MPI_Datatype, ocount::Ptr{Cint})::Cint
end

"""
    sc_io_close(file)

### Prototype
```c
int sc_io_close (sc_MPI_File * file);
```
"""
function sc_io_close(file)
    @ccall libsc.sc_io_close(file::Ptr{Cint})::Cint
end

"""
    p4est_comm_tag

Tags for MPI messages
"""
@cenum p4est_comm_tag::UInt32 begin
    P4EST_COMM_TAG_FIRST = 214
    P4EST_COMM_COUNT_PERTREE = 295
    P4EST_COMM_BALANCE_FIRST_COUNT = 296
    P4EST_COMM_BALANCE_FIRST_LOAD = 297
    P4EST_COMM_BALANCE_SECOND_COUNT = 298
    P4EST_COMM_BALANCE_SECOND_LOAD = 299
    P4EST_COMM_PARTITION_GIVEN = 300
    P4EST_COMM_PARTITION_WEIGHTED_LOW = 301
    P4EST_COMM_PARTITION_WEIGHTED_HIGH = 302
    P4EST_COMM_PARTITION_CORRECTION = 303
    P4EST_COMM_GHOST_COUNT = 304
    P4EST_COMM_GHOST_LOAD = 305
    P4EST_COMM_GHOST_EXCHANGE = 306
    P4EST_COMM_GHOST_EXPAND_COUNT = 307
    P4EST_COMM_GHOST_EXPAND_LOAD = 308
    P4EST_COMM_GHOST_SUPPORT_COUNT = 309
    P4EST_COMM_GHOST_SUPPORT_LOAD = 310
    P4EST_COMM_GHOST_CHECKSUM = 311
    P4EST_COMM_NODES_QUERY = 312
    P4EST_COMM_NODES_REPLY = 313
    P4EST_COMM_SAVE = 314
    P4EST_COMM_LNODES_TEST = 315
    P4EST_COMM_LNODES_PASS = 316
    P4EST_COMM_LNODES_OWNED = 317
    P4EST_COMM_LNODES_ALL = 318
    P4EST_COMM_TAG_LAST = 319
end

"""Tags for MPI messages"""
const p4est_comm_tag_t = p4est_comm_tag

"""
    p4est_log_indent_push()

### Prototype
```c
static inline void p4est_log_indent_push (void);
```
"""
function p4est_log_indent_push()
    @ccall libp4est.p4est_log_indent_push()::Cvoid
end

"""
    p4est_log_indent_pop()

### Prototype
```c
static inline void p4est_log_indent_pop (void);
```
"""
function p4est_log_indent_pop()
    @ccall libp4est.p4est_log_indent_pop()::Cvoid
end

"""
    p4est_init(log_handler, log_threshold)

Registers p4est with the SC Library and sets the logging behavior. This function is optional. This function must only be called before additional threads are created. If this function is not called or called with log\\_handler == NULL, the default SC log handler will be used. If this function is not called or called with log\\_threshold == `SC_LP_DEFAULT`, the default SC log threshold will be used. The default SC log settings can be changed with [`sc_set_log_defaults`](@ref) ().

### Prototype
```c
void p4est_init (sc_log_handler_t log_handler, int log_threshold);
```
"""
function p4est_init(log_handler, log_threshold)
    @ccall libp4est.p4est_init(log_handler::sc_log_handler_t, log_threshold::Cint)::Cvoid
end

"""
    p4est_is_initialized()

Return whether p4est has been initialized or not. Keep in mind that p4est_init is an optional function but it helps with proper parallel logging.

Currently there is no inverse to p4est_init, and no way to deinit it. This is ok since initialization generally does no harm. Just do not call libsc's finalize function while p4est is still in use.

### Returns
True if p4est has been initialized with a call to p4est_init and false otherwise.
### Prototype
```c
int p4est_is_initialized (void);
```
"""
function p4est_is_initialized()
    @ccall libp4est.p4est_is_initialized()::Cint
end

"""
    p4est_topidx_hash2(tt)

### Prototype
```c
static inline unsigned p4est_topidx_hash2 (const p4est_topidx_t * tt);
```
"""
function p4est_topidx_hash2(tt)
    @ccall libp4est.p4est_topidx_hash2(tt::Ptr{p4est_topidx_t})::Cuint
end

"""
    p4est_topidx_hash3(tt)

### Prototype
```c
static inline unsigned p4est_topidx_hash3 (const p4est_topidx_t * tt);
```
"""
function p4est_topidx_hash3(tt)
    @ccall libp4est.p4est_topidx_hash3(tt::Ptr{p4est_topidx_t})::Cuint
end

"""
    p4est_topidx_hash4(tt)

### Prototype
```c
static inline unsigned p4est_topidx_hash4 (const p4est_topidx_t * tt);
```
"""
function p4est_topidx_hash4(tt)
    @ccall libp4est.p4est_topidx_hash4(tt::Ptr{p4est_topidx_t})::Cuint
end

"""
    p4est_topidx_is_sorted(t, length)

### Prototype
```c
static inline int p4est_topidx_is_sorted (p4est_topidx_t * t, int length);
```
"""
function p4est_topidx_is_sorted(t, length)
    @ccall libp4est.p4est_topidx_is_sorted(t::Ptr{p4est_topidx_t}, length::Cint)::Cint
end

"""
    p4est_topidx_bsort(t, length)

### Prototype
```c
static inline void p4est_topidx_bsort (p4est_topidx_t * t, int length);
```
"""
function p4est_topidx_bsort(t, length)
    @ccall libp4est.p4est_topidx_bsort(t::Ptr{p4est_topidx_t}, length::Cint)::Cvoid
end

"""
    p4est_partition_cut_uint64(global_num, p, num_procs)

### Prototype
```c
static inline uint64_t p4est_partition_cut_uint64 (uint64_t global_num, int p, int num_procs);
```
"""
function p4est_partition_cut_uint64(global_num, p, num_procs)
    @ccall libp4est.p4est_partition_cut_uint64(global_num::UInt64, p::Cint, num_procs::Cint)::UInt64
end

"""
    p4est_partition_cut_gloidx(global_num, p, num_procs)

### Prototype
```c
static inline p4est_gloidx_t p4est_partition_cut_gloidx (p4est_gloidx_t global_num, int p, int num_procs);
```
"""
function p4est_partition_cut_gloidx(global_num, p, num_procs)
    @ccall libp4est.p4est_partition_cut_gloidx(global_num::p4est_gloidx_t, p::Cint, num_procs::Cint)::p4est_gloidx_t
end

"""
    p4est_version()

Return the full version of p4est.

### Returns
Return the version of p4est using the format `VERSION\\_MAJOR.VERSION\\_MINOR.VERSION\\_POINT`, where `VERSION_POINT` can contain dots and characters, e.g. to indicate the additional number of commits and a git commit hash.
### Prototype
```c
const char *p4est_version (void);
```
"""
function p4est_version()
    @ccall libp4est.p4est_version()::Cstring
end

"""
    p4est_version_major()

Return the major version of p4est.

### Returns
Return the major version of p4est.
### Prototype
```c
int p4est_version_major (void);
```
"""
function p4est_version_major()
    @ccall libp4est.p4est_version_major()::Cint
end

"""
    p4est_version_minor()

Return the minor version of p4est.

### Returns
Return the minor version of p4est.
### Prototype
```c
int p4est_version_minor (void);
```
"""
function p4est_version_minor()
    @ccall libp4est.p4est_version_minor()::Cint
end

"""
    p4est_connect_type_t

Characterize a type of adjacency.

Several functions involve relationships between neighboring trees and/or quadrants, and their behavior depends on how one defines adjacency: 1) entities are adjacent if they share a face, or 2) entities are adjacent if they share a face or corner. [`p4est_connect_type_t`](@ref) is used to choose the desired behavior. This enum must fit into an int8\\_t.
"""
@cenum p4est_connect_type_t::UInt32 begin
    P4EST_CONNECT_SELF = 20
    P4EST_CONNECT_FACE = 21
    P4EST_CONNECT_CORNER = 22
    P4EST_CONNECT_FULL = 22
end

"""
    p4est_connectivity_encode_t

Typedef for serialization method.

| Enumerator                   | Note                              |
| :--------------------------- | :-------------------------------- |
| P4EST\\_CONN\\_ENCODE\\_LAST | Invalid entry to close the list.  |
"""
@cenum p4est_connectivity_encode_t::UInt32 begin
    P4EST_CONN_ENCODE_NONE = 0
    P4EST_CONN_ENCODE_LAST = 1
end

"""
    p4est_connect_type_int(btype)

Convert the [`p4est_connect_type_t`](@ref) into a number.

### Parameters
* `btype`:\\[in\\] The balance type to convert.
### Returns
Returns 1 or 2.
### Prototype
```c
int p4est_connect_type_int (p4est_connect_type_t btype);
```
"""
function p4est_connect_type_int(btype)
    @ccall libp4est.p4est_connect_type_int(btype::p4est_connect_type_t)::Cint
end

"""
    p4est_connect_type_string(btype)

Convert the [`p4est_connect_type_t`](@ref) into a const string.

### Parameters
* `btype`:\\[in\\] The balance type to convert.
### Returns
Returns a pointer to a constant string.
### Prototype
```c
const char *p4est_connect_type_string (p4est_connect_type_t btype);
```
"""
function p4est_connect_type_string(btype)
    @ccall libp4est.p4est_connect_type_string(btype::p4est_connect_type_t)::Cstring
end

"""
    p4est_connectivity

This structure holds the 2D inter-tree connectivity information. Identification of arbitrary faces and corners is possible.

The arrays tree\\_to\\_* are stored in z ordering. For corners the order wrt. yx is 00 01 10 11. For faces the order is -x +x -y +y. They are allocated [0][0]..[0][3]..[num\\_trees-1][0]..[num\\_trees-1][3].

The values for tree\\_to\\_face are 0..7 where ttf % 4 gives the face number and ttf / 4 the face orientation code. The orientation is 0 for edges that are aligned in z-order, and 1 for edges that are running opposite in z-order.

It is valid to specify num\\_vertices as 0. In this case vertices and tree\\_to\\_vertex are set to NULL. Otherwise the vertex coordinates are stored in the array vertices as [0][0]..[0][2]..[num\\_vertices-1][0]..[num\\_vertices-1][2].

The corners are only stored when they connect trees. In this case tree\\_to\\_corner indexes into *ctt_offset*. Otherwise the tree\\_to\\_corner entry must be -1 and this corner is ignored. If num\\_corners == 0, tree\\_to\\_corner and corner\\_to\\_* arrays are set to NULL.

The arrays corner\\_to\\_* store a variable number of entries per corner. For corner c these are at position [ctt\\_offset[c]]..[ctt\\_offset[c+1]-1]. Their number for corner c is ctt\\_offset[c+1] - ctt\\_offset[c]. The entries encode all trees adjacent to corner c. The size of the corner\\_to\\_* arrays is num\\_ctt = ctt\\_offset[num\\_corners].

The *\\_to\\_attr arrays may have arbitrary contents defined by the user.

| Field                | Note                                                                                 |
| :------------------- | :----------------------------------------------------------------------------------- |
| num\\_vertices       | the number of vertices that define the *embedding* of the forest (not the topology)  |
| num\\_trees          | the number of trees                                                                  |
| num\\_corners        | the number of corners that help define topology                                      |
| vertices             | an array of size (3 * *num_vertices*)                                                |
| tree\\_to\\_vertex   | embed each tree into  ```c++ R^3 ```  for e.g. visualization (see p4est\\_vtk.h)     |
| tree\\_attr\\_bytes  | bytes per tree in tree\\_to\\_attr                                                   |
| tree\\_to\\_attr     | not touched by p4est                                                                 |
| tree\\_to\\_tree     | (4 * *num_trees*) neighbors across faces                                             |
| tree\\_to\\_face     | (4 * *num_trees*) face to face+orientation (see description)                         |
| tree\\_to\\_corner   | (4 * *num_trees*) or NULL (see description)                                          |
| ctt\\_offset         | corner to offset in *corner_to_tree* and *corner_to_corner*                          |
| corner\\_to\\_tree   | list of trees that meet at a corner                                                  |
| corner\\_to\\_corner | list of tree-corners that meet at a corner                                           |
"""
struct p4est_connectivity
    num_vertices::p4est_topidx_t
    num_trees::p4est_topidx_t
    num_corners::p4est_topidx_t
    vertices::Ptr{Cdouble}
    tree_to_vertex::Ptr{p4est_topidx_t}
    tree_attr_bytes::Csize_t
    tree_to_attr::Cstring
    tree_to_tree::Ptr{p4est_topidx_t}
    tree_to_face::Ptr{Int8}
    tree_to_corner::Ptr{p4est_topidx_t}
    ctt_offset::Ptr{p4est_topidx_t}
    corner_to_tree::Ptr{p4est_topidx_t}
    corner_to_corner::Ptr{Int8}
end

"""
This structure holds the 2D inter-tree connectivity information. Identification of arbitrary faces and corners is possible.

The arrays tree\\_to\\_* are stored in z ordering. For corners the order wrt. yx is 00 01 10 11. For faces the order is -x +x -y +y. They are allocated [0][0]..[0][3]..[num\\_trees-1][0]..[num\\_trees-1][3].

The values for tree\\_to\\_face are 0..7 where ttf % 4 gives the face number and ttf / 4 the face orientation code. The orientation is 0 for edges that are aligned in z-order, and 1 for edges that are running opposite in z-order.

It is valid to specify num\\_vertices as 0. In this case vertices and tree\\_to\\_vertex are set to NULL. Otherwise the vertex coordinates are stored in the array vertices as [0][0]..[0][2]..[num\\_vertices-1][0]..[num\\_vertices-1][2].

The corners are only stored when they connect trees. In this case tree\\_to\\_corner indexes into *ctt_offset*. Otherwise the tree\\_to\\_corner entry must be -1 and this corner is ignored. If num\\_corners == 0, tree\\_to\\_corner and corner\\_to\\_* arrays are set to NULL.

The arrays corner\\_to\\_* store a variable number of entries per corner. For corner c these are at position [ctt\\_offset[c]]..[ctt\\_offset[c+1]-1]. Their number for corner c is ctt\\_offset[c+1] - ctt\\_offset[c]. The entries encode all trees adjacent to corner c. The size of the corner\\_to\\_* arrays is num\\_ctt = ctt\\_offset[num\\_corners].

The *\\_to\\_attr arrays may have arbitrary contents defined by the user.
"""
const p4est_connectivity_t = p4est_connectivity

"""
    p4est_connectivity_memory_used(conn)

Calculate memory usage of a connectivity structure.

### Parameters
* `conn`:\\[in\\] Connectivity structure.
### Returns
Memory used in bytes.
### Prototype
```c
size_t p4est_connectivity_memory_used (p4est_connectivity_t * conn);
```
"""
function p4est_connectivity_memory_used(conn)
    @ccall libp4est.p4est_connectivity_memory_used(conn::Ptr{p4est_connectivity_t})::Csize_t
end

struct p4est_corner_transform_t
    ntree::p4est_topidx_t
    ncorner::Int8
end

struct p4est_corner_info_t
    icorner::p4est_topidx_t
    corner_transforms::sc_array_t
end

"""
    p4est_neighbor_transform_t

Generic interface for transformations between a tree and any of its neighbors

| Field             | Note                                                                        |
| :---------------- | :-------------------------------------------------------------------------- |
| neighbor\\_type   | type of connection to neighbor                                              |
| neighbor          | neighbor tree index                                                         |
| index\\_self      | index of interface from self's perspective                                  |
| index\\_neighbor  | index of interface from neighbor's perspective                              |
| perm              | permutation of dimensions when transforming self coords to neighbor coords  |
| sign              | sign changes when transforming self coords to neighbor coords               |
| origin\\_neighbor | point on the interface from self's perspective                              |
"""
struct p4est_neighbor_transform_t
    neighbor_type::p4est_connect_type_t
    neighbor::p4est_topidx_t
    index_self::Int8
    index_neighbor::Int8
    perm::NTuple{2, Int8}
    sign::NTuple{2, Int8}
    origin_self::NTuple{2, p4est_qcoord_t}
    origin_neighbor::NTuple{2, p4est_qcoord_t}
end

"""
    p4est_neighbor_transform_coordinates(nt, self_coords, neigh_coords)

Transform from self's coordinate system to neighbor's coordinate system.

### Parameters
* `nt`:\\[in\\] A neighbor transform.
* `self_coords`:\\[in\\] Input quadrant coordinates in self coordinates.
* `neigh_coords`:\\[out\\] Coordinates transformed into neighbor coordinates.
### Prototype
```c
void p4est_neighbor_transform_coordinates (const p4est_neighbor_transform_t * nt, const p4est_qcoord_t self_coords[P4EST_DIM], p4est_qcoord_t neigh_coords[P4EST_DIM]);
```
"""
function p4est_neighbor_transform_coordinates(nt, self_coords, neigh_coords)
    @ccall libp4est.p4est_neighbor_transform_coordinates(nt::Ptr{p4est_neighbor_transform_t}, self_coords::Ptr{p4est_qcoord_t}, neigh_coords::Ptr{p4est_qcoord_t})::Cvoid
end

"""
    p4est_neighbor_transform_coordinates_reverse(nt, neigh_coords, self_coords)

Transform from neighbor's coordinate system to self's coordinate system.

### Parameters
* `nt`:\\[in\\] A neighbor transform.
* `neigh_coords`:\\[in\\] Input quadrant coordinates in self coordinates.
* `self_coords`:\\[out\\] Coordinates transformed into neighbor coordinates.
### Prototype
```c
void p4est_neighbor_transform_coordinates_reverse (const p4est_neighbor_transform_t * nt, const p4est_qcoord_t neigh_coords[P4EST_DIM], p4est_qcoord_t self_coords[P4EST_DIM]);
```
"""
function p4est_neighbor_transform_coordinates_reverse(nt, neigh_coords, self_coords)
    @ccall libp4est.p4est_neighbor_transform_coordinates_reverse(nt::Ptr{p4est_neighbor_transform_t}, neigh_coords::Ptr{p4est_qcoord_t}, self_coords::Ptr{p4est_qcoord_t})::Cvoid
end

"""
    p4est_connectivity_get_neighbor_transforms(conn, tree_id, boundary_type, boundary_index, neighbor_transform_array)

### Prototype
```c
void p4est_connectivity_get_neighbor_transforms (p4est_connectivity_t *conn, p4est_topidx_t tree_id, p4est_connect_type_t boundary_type, int boundary_index, sc_array_t *neighbor_transform_array);
```
"""
function p4est_connectivity_get_neighbor_transforms(conn, tree_id, boundary_type, boundary_index, neighbor_transform_array)
    @ccall libp4est.p4est_connectivity_get_neighbor_transforms(conn::Ptr{p4est_connectivity_t}, tree_id::p4est_topidx_t, boundary_type::p4est_connect_type_t, boundary_index::Cint, neighbor_transform_array::Ptr{sc_array_t})::Cvoid
end

"""
    p4est_connectivity_face_neighbor_face_corner(fc, f, nf, o)

Transform a face corner across one of the adjacent faces into a neighbor tree. This version expects the neighbor face and orientation separately.

### Parameters
* `fc`:\\[in\\] A face corner number in 0..1.
* `f`:\\[in\\] A face that the face corner number *fc* is relative to.
* `nf`:\\[in\\] A neighbor face that is on the other side of *f*.
* `o`:\\[in\\] The orientation between tree boundary faces *f* and *nf*.
### Returns
The face corner number relative to the neighbor's face.
### Prototype
```c
int p4est_connectivity_face_neighbor_face_corner (int fc, int f, int nf, int o);
```
"""
function p4est_connectivity_face_neighbor_face_corner(fc, f, nf, o)
    @ccall libp4est.p4est_connectivity_face_neighbor_face_corner(fc::Cint, f::Cint, nf::Cint, o::Cint)::Cint
end

"""
    p4est_connectivity_face_neighbor_corner(c, f, nf, o)

Transform a corner across one of the adjacent faces into a neighbor tree. This version expects the neighbor face and orientation separately.

### Parameters
* `c`:\\[in\\] A corner number in 0..3.
* `f`:\\[in\\] A face number that touches the corner *c*.
* `nf`:\\[in\\] A neighbor face that is on the other side of *f*.
* `o`:\\[in\\] The orientation between tree boundary faces *f* and *nf*.
### Returns
The number of the corner seen from the neighbor tree.
### Prototype
```c
int p4est_connectivity_face_neighbor_corner (int c, int f, int nf, int o);
```
"""
function p4est_connectivity_face_neighbor_corner(c, f, nf, o)
    @ccall libp4est.p4est_connectivity_face_neighbor_corner(c::Cint, f::Cint, nf::Cint, o::Cint)::Cint
end

"""
    p4est_connectivity_new(num_vertices, num_trees, num_corners, num_ctt)

Allocate a connectivity structure. The attribute fields are initialized to NULL.

### Parameters
* `num_vertices`:\\[in\\] Number of total vertices (i.e. geometric points).
* `num_trees`:\\[in\\] Number of trees in the forest.
* `num_corners`:\\[in\\] Number of tree-connecting corners.
* `num_ctt`:\\[in\\] Number of total trees in corner\\_to\\_tree array.
### Returns
A connectivity structure with allocated arrays.
### Prototype
```c
p4est_connectivity_t *p4est_connectivity_new (p4est_topidx_t num_vertices, p4est_topidx_t num_trees, p4est_topidx_t num_corners, p4est_topidx_t num_ctt);
```
"""
function p4est_connectivity_new(num_vertices, num_trees, num_corners, num_ctt)
    @ccall libp4est.p4est_connectivity_new(num_vertices::p4est_topidx_t, num_trees::p4est_topidx_t, num_corners::p4est_topidx_t, num_ctt::p4est_topidx_t)::Ptr{p4est_connectivity_t}
end

"""
    p4est_connectivity_new_copy(num_vertices, num_trees, num_corners, vertices, ttv, ttt, ttf, ttc, coff, ctt, ctc)

Allocate a connectivity structure and populate from constants. The attribute fields are initialized to NULL.

### Parameters
* `num_vertices`:\\[in\\] Number of total vertices (i.e. geometric points).
* `num_trees`:\\[in\\] Number of trees in the forest.
* `num_corners`:\\[in\\] Number of tree-connecting corners.
* `coff`:\\[in\\] Corner-to-tree offsets (num\\_corners + 1 values). This must always be non-NULL; in trivial cases it is just a pointer to a p4est\\_topix value of 0.
### Returns
The connectivity is checked for validity.
### Prototype
```c
p4est_connectivity_t *p4est_connectivity_new_copy (p4est_topidx_t num_vertices, p4est_topidx_t num_trees, p4est_topidx_t num_corners, const double *vertices, const p4est_topidx_t * ttv, const p4est_topidx_t * ttt, const int8_t * ttf, const p4est_topidx_t * ttc, const p4est_topidx_t * coff, const p4est_topidx_t * ctt, const int8_t * ctc);
```
"""
function p4est_connectivity_new_copy(num_vertices, num_trees, num_corners, vertices, ttv, ttt, ttf, ttc, coff, ctt, ctc)
    @ccall libp4est.p4est_connectivity_new_copy(num_vertices::p4est_topidx_t, num_trees::p4est_topidx_t, num_corners::p4est_topidx_t, vertices::Ptr{Cdouble}, ttv::Ptr{p4est_topidx_t}, ttt::Ptr{p4est_topidx_t}, ttf::Ptr{Int8}, ttc::Ptr{p4est_topidx_t}, coff::Ptr{p4est_topidx_t}, ctt::Ptr{p4est_topidx_t}, ctc::Ptr{Int8})::Ptr{p4est_connectivity_t}
end

"""
    p4est_connectivity_bcast(conn_in, root, comm)

### Prototype
```c
p4est_connectivity_t *p4est_connectivity_bcast (p4est_connectivity_t * conn_in, int root, sc_MPI_Comm comm);
```
"""
function p4est_connectivity_bcast(conn_in, root, comm)
    @ccall libp4est.p4est_connectivity_bcast(conn_in::Ptr{p4est_connectivity_t}, root::Cint, comm::MPI_Comm)::Ptr{p4est_connectivity_t}
end

"""
    p4est_connectivity_destroy(connectivity)

Destroy a connectivity structure. Also destroy all attributes.

### Prototype
```c
void p4est_connectivity_destroy (p4est_connectivity_t * connectivity);
```
"""
function p4est_connectivity_destroy(connectivity)
    @ccall libp4est.p4est_connectivity_destroy(connectivity::Ptr{p4est_connectivity_t})::Cvoid
end

"""
    p4est_connectivity_set_attr(conn, bytes_per_tree)

Allocate or free the attribute fields in a connectivity.

### Parameters
* `conn`:\\[in,out\\] The conn->*\\_to\\_attr fields must either be NULL or previously be allocated by this function.
* `bytes_per_tree`:\\[in\\] If 0, tree\\_to\\_attr is freed (being NULL is ok). If positive, requested space is allocated.
### Prototype
```c
void p4est_connectivity_set_attr (p4est_connectivity_t * conn, size_t bytes_per_tree);
```
"""
function p4est_connectivity_set_attr(conn, bytes_per_tree)
    @ccall libp4est.p4est_connectivity_set_attr(conn::Ptr{p4est_connectivity_t}, bytes_per_tree::Csize_t)::Cvoid
end

"""
    p4est_connectivity_is_valid(connectivity)

Examine a connectivity structure.

### Returns
Returns true if structure is valid, false otherwise.
### Prototype
```c
int p4est_connectivity_is_valid (p4est_connectivity_t * connectivity);
```
"""
function p4est_connectivity_is_valid(connectivity)
    @ccall libp4est.p4est_connectivity_is_valid(connectivity::Ptr{p4est_connectivity_t})::Cint
end

"""
    p4est_connectivity_is_equal(conn1, conn2)

Check two connectivity structures for equality.

### Returns
Returns true if structures are equal, false otherwise.
### Prototype
```c
int p4est_connectivity_is_equal (p4est_connectivity_t * conn1, p4est_connectivity_t * conn2);
```
"""
function p4est_connectivity_is_equal(conn1, conn2)
    @ccall libp4est.p4est_connectivity_is_equal(conn1::Ptr{p4est_connectivity_t}, conn2::Ptr{p4est_connectivity_t})::Cint
end

"""
    p4est_connectivity_sink(conn, sink)

Write connectivity to a sink object.

### Parameters
* `conn`:\\[in\\] The connectivity to be written.
* `sink`:\\[in,out\\] The connectivity is written into this sink.
### Returns
0 on success, nonzero on error.
### Prototype
```c
int p4est_connectivity_sink (p4est_connectivity_t * conn, sc_io_sink_t * sink);
```
"""
function p4est_connectivity_sink(conn, sink)
    @ccall libp4est.p4est_connectivity_sink(conn::Ptr{p4est_connectivity_t}, sink::Ptr{sc_io_sink_t})::Cint
end

"""
    p4est_connectivity_deflate(conn, code)

Allocate memory and store the connectivity information there.

### Parameters
* `conn`:\\[in\\] The connectivity structure to be exported to memory.
* `code`:\\[in\\] Encoding and compression method for serialization.
### Returns
Newly created array that contains the information.
### Prototype
```c
sc_array_t *p4est_connectivity_deflate (p4est_connectivity_t * conn, p4est_connectivity_encode_t code);
```
"""
function p4est_connectivity_deflate(conn, code)
    @ccall libp4est.p4est_connectivity_deflate(conn::Ptr{p4est_connectivity_t}, code::p4est_connectivity_encode_t)::Ptr{sc_array_t}
end

"""
    p4est_connectivity_save(filename, connectivity)

Save a connectivity structure to disk.

### Parameters
* `filename`:\\[in\\] Name of the file to write.
* `connectivity`:\\[in\\] Valid connectivity structure.
### Returns
Returns 0 on success, nonzero on file error.
### Prototype
```c
int p4est_connectivity_save (const char *filename, p4est_connectivity_t * connectivity);
```
"""
function p4est_connectivity_save(filename, connectivity)
    @ccall libp4est.p4est_connectivity_save(filename::Cstring, connectivity::Ptr{p4est_connectivity_t})::Cint
end

"""
    p4est_connectivity_source(source)

Read connectivity from a source object.

### Parameters
* `source`:\\[in,out\\] The connectivity is read from this source.
### Returns
The newly created connectivity, or NULL on error.
### Prototype
```c
p4est_connectivity_t *p4est_connectivity_source (sc_io_source_t * source);
```
"""
function p4est_connectivity_source(source)
    @ccall libp4est.p4est_connectivity_source(source::Ptr{sc_io_source_t})::Ptr{p4est_connectivity_t}
end

"""
    p4est_connectivity_inflate(buffer)

Create new connectivity from a memory buffer. This function aborts on malloc errors.

### Parameters
* `buffer`:\\[in\\] The connectivity is created from this memory buffer.
### Returns
The newly created connectivity, or NULL on format error of the buffered connectivity data.
### Prototype
```c
p4est_connectivity_t *p4est_connectivity_inflate (sc_array_t * buffer);
```
"""
function p4est_connectivity_inflate(buffer)
    @ccall libp4est.p4est_connectivity_inflate(buffer::Ptr{sc_array_t})::Ptr{p4est_connectivity_t}
end

"""
    p4est_connectivity_load(filename, bytes)

Load a connectivity structure from disk.

### Parameters
* `filename`:\\[in\\] Name of the file to read.
* `bytes`:\\[in,out\\] Size in bytes of connectivity on disk or NULL.
### Returns
Returns valid connectivity, or NULL on file error.
### Prototype
```c
p4est_connectivity_t *p4est_connectivity_load (const char *filename, size_t *bytes);
```
"""
function p4est_connectivity_load(filename, bytes)
    @ccall libp4est.p4est_connectivity_load(filename::Cstring, bytes::Ptr{Csize_t})::Ptr{p4est_connectivity_t}
end

"""
    p4est_connectivity_new_unitsquare()

Create a connectivity structure for the unit square.

### Prototype
```c
p4est_connectivity_t *p4est_connectivity_new_unitsquare (void);
```
"""
function p4est_connectivity_new_unitsquare()
    @ccall libp4est.p4est_connectivity_new_unitsquare()::Ptr{p4est_connectivity_t}
end

"""
    p4est_connectivity_new_periodic()

Create a connectivity structure for an all-periodic unit square.

### Prototype
```c
p4est_connectivity_t *p4est_connectivity_new_periodic (void);
```
"""
function p4est_connectivity_new_periodic()
    @ccall libp4est.p4est_connectivity_new_periodic()::Ptr{p4est_connectivity_t}
end

"""
    p4est_connectivity_new_rotwrap()

Create a connectivity structure for a periodic unit square. The left and right faces are identified, and bottom and top opposite.

### Prototype
```c
p4est_connectivity_t *p4est_connectivity_new_rotwrap (void);
```
"""
function p4est_connectivity_new_rotwrap()
    @ccall libp4est.p4est_connectivity_new_rotwrap()::Ptr{p4est_connectivity_t}
end

"""
    p4est_connectivity_new_twotrees(l_face, r_face, orientation)

Create a connectivity structure for two trees being rotated w.r.t. each other in a user-defined way

### Parameters
* `l_face`:\\[in\\] index of left face
* `r_face`:\\[in\\] index of right face
* `orientation`:\\[in\\] orientation of trees w.r.t. each other
### Prototype
```c
p4est_connectivity_t *p4est_connectivity_new_twotrees (int l_face, int r_face, int orientation);
```
"""
function p4est_connectivity_new_twotrees(l_face, r_face, orientation)
    @ccall libp4est.p4est_connectivity_new_twotrees(l_face::Cint, r_face::Cint, orientation::Cint)::Ptr{p4est_connectivity_t}
end

"""
    p4est_connectivity_new_corner()

Create a connectivity structure for a three-tree mesh around a corner.

### Prototype
```c
p4est_connectivity_t *p4est_connectivity_new_corner (void);
```
"""
function p4est_connectivity_new_corner()
    @ccall libp4est.p4est_connectivity_new_corner()::Ptr{p4est_connectivity_t}
end

"""
    p4est_connectivity_new_pillow()

Create a connectivity structure for two trees on top of each other.

### Prototype
```c
p4est_connectivity_t *p4est_connectivity_new_pillow (void);
```
"""
function p4est_connectivity_new_pillow()
    @ccall libp4est.p4est_connectivity_new_pillow()::Ptr{p4est_connectivity_t}
end

"""
    p4est_connectivity_new_moebius()

Create a connectivity structure for a five-tree moebius band.

### Prototype
```c
p4est_connectivity_t *p4est_connectivity_new_moebius (void);
```
"""
function p4est_connectivity_new_moebius()
    @ccall libp4est.p4est_connectivity_new_moebius()::Ptr{p4est_connectivity_t}
end

"""
    p4est_connectivity_new_star()

Create a connectivity structure for a six-tree star.

### Prototype
```c
p4est_connectivity_t *p4est_connectivity_new_star (void);
```
"""
function p4est_connectivity_new_star()
    @ccall libp4est.p4est_connectivity_new_star()::Ptr{p4est_connectivity_t}
end

"""
    p4est_connectivity_new_cubed()

Create a connectivity structure for the six sides of a unit cube. The ordering of the trees is as follows: 0 1 2 3 <-- 3: axis-aligned top side 4 5. This choice has been made for maximum symmetry (see tree\\_to\\_* in .c file).

### Prototype
```c
p4est_connectivity_t *p4est_connectivity_new_cubed (void);
```
"""
function p4est_connectivity_new_cubed()
    @ccall libp4est.p4est_connectivity_new_cubed()::Ptr{p4est_connectivity_t}
end

"""
    p4est_connectivity_new_disk_nonperiodic()

Create a connectivity structure for a five-tree flat spherical disk. This disk can just as well be used as a square to test non-Cartesian maps. Without any mapping this connectivity covers the square [-3, 3]**2.

### Returns
Initialized and usable connectivity.
### Prototype
```c
p4est_connectivity_t *p4est_connectivity_new_disk_nonperiodic (void);
```
"""
function p4est_connectivity_new_disk_nonperiodic()
    @ccall libp4est.p4est_connectivity_new_disk_nonperiodic()::Ptr{p4est_connectivity_t}
end

"""
    p4est_connectivity_new_disk(periodic_a, periodic_b)

Create a connectivity structure for a five-tree flat spherical disk. This disk can just as well be used as a square to test non-Cartesian maps. Without any mapping this connectivity covers the square [-3, 3]**2.

!!! note

    The API of this function has changed to accept two arguments. You can query the #define `P4EST_CONN_DISK_PERIODIC` to check whether the new version with the argument is in effect.

The ordering of the trees is as follows: 4 1 2 3 0.

The outside x faces may be identified topologically. The outside y faces may be identified topologically. Both identifications may be specified simultaneously. The general shape and periodicity are the same as those obtained with p4est_connectivity_new_brick (1, 1, periodic\\_a, periodic\\_b).

When setting *periodic_a* and *periodic_b* to false, the result is the same as that of p4est_connectivity_new_disk_nonperiodic.

### Parameters
* `periodic_a`:\\[in\\] Bool to make disk periodic in x direction.
* `periodic_b`:\\[in\\] Bool to make disk periodic in y direction.
### Returns
Initialized and usable connectivity.
### Prototype
```c
p4est_connectivity_t *p4est_connectivity_new_disk (int periodic_a, int periodic_b);
```
"""
function p4est_connectivity_new_disk(periodic_a, periodic_b)
    @ccall libp4est.p4est_connectivity_new_disk(periodic_a::Cint, periodic_b::Cint)::Ptr{p4est_connectivity_t}
end

"""
    p4est_connectivity_new_icosahedron()

Create a connectivity for mapping the sphere using an icosahedron.

The regular icosadron is a polyhedron with 20 faces, each of which is an equilateral triangle. To build the p4est connectivity, we group faces 2 by 2 to from 10 quadrangles, and thus 10 trees.

This connectivity is meant to be used together with p4est_geometry_new_icosahedron to map the sphere.

The flat connectivity looks like that: Vextex numbering:

A00 A01 A02 A03 A04 / \\ / \\ / \\ / \\ / \\ A05---A06---A07---A08---A09---A10 \\ / \\ / \\ / \\ / \\ / \\ A11---A12---A13---A14---A15---A16 \\ / \\ / \\ / \\ / \\ / A17 A18 A19 A20 A21

Origin in A05.

Tree numbering:

0 2 4 6 8 1 3 5 7 9

### Prototype
```c
p4est_connectivity_t *p4est_connectivity_new_icosahedron (void);
```
"""
function p4est_connectivity_new_icosahedron()
    @ccall libp4est.p4est_connectivity_new_icosahedron()::Ptr{p4est_connectivity_t}
end

"""
    p4est_connectivity_new_shell2d()

Create a connectivity structure that builds a 2d spherical shell. p8est_connectivity_new_shell

### Prototype
```c
p4est_connectivity_t *p4est_connectivity_new_shell2d (void);
```
"""
function p4est_connectivity_new_shell2d()
    @ccall libp4est.p4est_connectivity_new_shell2d()::Ptr{p4est_connectivity_t}
end

"""
    p4est_connectivity_new_disk2d()

Create a connectivity structure that maps a 2d disk.

This is a 5 trees connectivity meant to be used together with p4est_geometry_new_disk2d to map the disk.

### Prototype
```c
p4est_connectivity_t *p4est_connectivity_new_disk2d (void);
```
"""
function p4est_connectivity_new_disk2d()
    @ccall libp4est.p4est_connectivity_new_disk2d()::Ptr{p4est_connectivity_t}
end

"""
    p4est_connectivity_new_brick(mi, ni, periodic_a, periodic_b)

A rectangular m by n array of trees with configurable periodicity. The brick is periodic in x and y if periodic\\_a and periodic\\_b are true, respectively.

### Prototype
```c
p4est_connectivity_t *p4est_connectivity_new_brick (int mi, int ni, int periodic_a, int periodic_b);
```
"""
function p4est_connectivity_new_brick(mi, ni, periodic_a, periodic_b)
    @ccall libp4est.p4est_connectivity_new_brick(mi::Cint, ni::Cint, periodic_a::Cint, periodic_b::Cint)::Ptr{p4est_connectivity_t}
end

"""
    p4est_connectivity_new_byname(name)

Create connectivity structure from predefined catalogue.

### Parameters
* `name`:\\[in\\] Invokes connectivity\\_new\\_* function. brick23 brick (2, 3, 0, 0) corner corner cubed cubed disk disk moebius moebius periodic periodic pillow pillow rotwrap rotwrap star star unit unitsquare
### Returns
An initialized connectivity if name is defined, NULL else.
### Prototype
```c
p4est_connectivity_t *p4est_connectivity_new_byname (const char *name);
```
"""
function p4est_connectivity_new_byname(name)
    @ccall libp4est.p4est_connectivity_new_byname(name::Cstring)::Ptr{p4est_connectivity_t}
end

"""
    p4est_connectivity_refine(conn, num_per_edge)

Uniformly refine a connectivity. This is useful if you would like to uniformly refine by something other than a power of 2.

### Parameters
* `conn`:\\[in\\] A valid connectivity
* `num_per_edge`:\\[in\\] The number of new trees in each direction. Must use no more than P4EST_OLD_QMAXLEVEL bits.
### Returns
a refined connectivity.
### Prototype
```c
p4est_connectivity_t *p4est_connectivity_refine (p4est_connectivity_t * conn, int num_per_edge);
```
"""
function p4est_connectivity_refine(conn, num_per_edge)
    @ccall libp4est.p4est_connectivity_refine(conn::Ptr{p4est_connectivity_t}, num_per_edge::Cint)::Ptr{p4est_connectivity_t}
end

"""
    p4est_expand_face_transform(iface, nface, ftransform)

Fill an array with the axis combination of a face neighbor transform.

### Parameters
* `iface`:\\[in\\] The number of the originating face.
* `nface`:\\[in\\] Encoded as nface = r * 4 + nf, where nf = 0..3 is the neigbbor's connecting face number and r = 0..1 is the relative orientation to the neighbor's face. This encoding matches [`p4est_connectivity_t`](@ref).
* `ftransform`:\\[out\\] This array holds 9 integers. [0,2] The coordinate axis sequence of the origin face, the first referring to the tangential and the second to the normal. A permutation of (0, 1). [3,5] The coordinate axis sequence of the target face. [6,8] Edge reversal flag for tangential axis (boolean); face code in [0, 3] for the normal coordinate q: 0: q' = -q 1: q' = q + 1 2: q' = q - 1 3: q' = 2 - q [1,4,7] 0 (unused for compatibility with 3D).
### Prototype
```c
void p4est_expand_face_transform (int iface, int nface, int ftransform[]);
```
"""
function p4est_expand_face_transform(iface, nface, ftransform)
    @ccall libp4est.p4est_expand_face_transform(iface::Cint, nface::Cint, ftransform::Ptr{Cint})::Cvoid
end

"""
    p4est_find_face_transform(connectivity, itree, iface, ftransform)

Fill an array with the axis combinations of a tree neighbor transform.

### Parameters
* `itree`:\\[in\\] The number of the originating tree.
* `iface`:\\[in\\] The number of the originating tree's face.
* `ftransform`:\\[out\\] This array holds 9 integers. [0,2] The coordinate axis sequence of the origin face. [3,5] The coordinate axis sequence of the target face. [6,8] Edge reverse flag for axis t; face code for axis n. [1,4,7] 0 (unused for compatibility with 3D).
### Returns
The face neighbor tree if it exists, -1 otherwise.
### Prototype
```c
p4est_topidx_t p4est_find_face_transform (p4est_connectivity_t * connectivity, p4est_topidx_t itree, int iface, int ftransform[]);
```
"""
function p4est_find_face_transform(connectivity, itree, iface, ftransform)
    @ccall libp4est.p4est_find_face_transform(connectivity::Ptr{p4est_connectivity_t}, itree::p4est_topidx_t, iface::Cint, ftransform::Ptr{Cint})::p4est_topidx_t
end

"""
    p4est_find_corner_transform(connectivity, itree, icorner, ci)

Fills an array with information about corner neighbors.

### Parameters
* `itree`:\\[in\\] The number of the originating tree.
* `icorner`:\\[in\\] The number of the originating corner.
* `ci`:\\[in,out\\] A `p4est_corner_info_t` structure with initialized array.
### Prototype
```c
void p4est_find_corner_transform (p4est_connectivity_t * connectivity, p4est_topidx_t itree, int icorner, p4est_corner_info_t * ci);
```
"""
function p4est_find_corner_transform(connectivity, itree, icorner, ci)
    @ccall libp4est.p4est_find_corner_transform(connectivity::Ptr{p4est_connectivity_t}, itree::p4est_topidx_t, icorner::Cint, ci::Ptr{p4est_corner_info_t})::Cvoid
end

"""
    p4est_connectivity_complete(conn)

Internally connect a connectivity based on tree\\_to\\_vertex information. Periodicity that is not inherent in the list of vertices will be lost.

### Parameters
* `conn`:\\[in,out\\] The connectivity needs to have proper vertices and tree\\_to\\_vertex fields. The tree\\_to\\_tree and tree\\_to\\_face fields must be allocated and satisfy [`p4est_connectivity_is_valid`](@ref) (conn) but will be overwritten. The corner fields will be freed and allocated anew.
### Prototype
```c
void p4est_connectivity_complete (p4est_connectivity_t * conn);
```
"""
function p4est_connectivity_complete(conn)
    @ccall libp4est.p4est_connectivity_complete(conn::Ptr{p4est_connectivity_t})::Cvoid
end

"""
    p4est_connectivity_reduce(conn)

Removes corner information of a connectivity such that enough information is left to run [`p4est_connectivity_complete`](@ref) successfully. The reduced connectivity still passes [`p4est_connectivity_is_valid`](@ref).

### Parameters
* `conn`:\\[in,out\\] The connectivity to be reduced.
### Prototype
```c
void p4est_connectivity_reduce (p4est_connectivity_t * conn);
```
"""
function p4est_connectivity_reduce(conn)
    @ccall libp4est.p4est_connectivity_reduce(conn::Ptr{p4est_connectivity_t})::Cvoid
end

"""
    p4est_connectivity_permute(conn, perm, is_current_to_new)

[`p4est_connectivity_permute`](@ref) Given a permutation *perm* of the trees in a connectivity *conn*, permute the trees of *conn* in place and update *conn* to match.

### Parameters
* `conn`:\\[in,out\\] The connectivity whose trees are permuted.
* `perm`:\\[in\\] A permutation array, whose elements are size\\_t's.
* `is_current_to_new`:\\[in\\] if true, the jth entry of perm is the new index for the entry whose current index is j, otherwise the jth entry of perm is the current index of the tree whose index will be j after the permutation.
### Prototype
```c
void p4est_connectivity_permute (p4est_connectivity_t * conn, sc_array_t * perm, int is_current_to_new);
```
"""
function p4est_connectivity_permute(conn, perm, is_current_to_new)
    @ccall libp4est.p4est_connectivity_permute(conn::Ptr{p4est_connectivity_t}, perm::Ptr{sc_array_t}, is_current_to_new::Cint)::Cvoid
end

"""
    p4est_connectivity_join_faces(conn, tree_left, tree_right, face_left, face_right, orientation)

[`p4est_connectivity_join_faces`](@ref) This function takes an existing valid connectivity *conn* and modifies it by joining two tree faces that are currently boundary faces.

### Parameters
* `conn`:\\[in,out\\] connectivity that will be altered.
* `tree_left`:\\[in\\] tree that will be on the left side of the joined faces.
* `tree_right`:\\[in\\] tree that will be on the right side of the joined faces.
* `face_left`:\\[in\\] face of *tree_left* that will be joined.
* `face_right`:\\[in\\] face of *tree_right* that will be joined.
* `orientation`:\\[in\\] the orientation of *face_left* and *face_right* once joined (see the description of [`p4est_connectivity_t`](@ref) to understand orientation).
### Prototype
```c
void p4est_connectivity_join_faces (p4est_connectivity_t * conn, p4est_topidx_t tree_left, p4est_topidx_t tree_right, int face_left, int face_right, int orientation);
```
"""
function p4est_connectivity_join_faces(conn, tree_left, tree_right, face_left, face_right, orientation)
    @ccall libp4est.p4est_connectivity_join_faces(conn::Ptr{p4est_connectivity_t}, tree_left::p4est_topidx_t, tree_right::p4est_topidx_t, face_left::Cint, face_right::Cint, orientation::Cint)::Cvoid
end

"""
    p4est_connectivity_is_equivalent(conn1, conn2)

[`p4est_connectivity_is_equivalent`](@ref) This function compares two connectivities for equivalence: it returns *true* if they are the same connectivity, or if they have the same topology. The definition of topological sameness is strict: there is no attempt made to determine whether permutation and/or rotation of the trees makes the connectivities equivalent.

### Parameters
* `conn1`:\\[in\\] a valid connectivity
* `conn2`:\\[out\\] a valid connectivity
### Prototype
```c
int p4est_connectivity_is_equivalent (p4est_connectivity_t * conn1, p4est_connectivity_t * conn2);
```
"""
function p4est_connectivity_is_equivalent(conn1, conn2)
    @ccall libp4est.p4est_connectivity_is_equivalent(conn1::Ptr{p4est_connectivity_t}, conn2::Ptr{p4est_connectivity_t})::Cint
end

"""
    p4est_corner_array_index(array, it)

### Prototype
```c
static inline p4est_corner_transform_t * p4est_corner_array_index (sc_array_t * array, size_t it);
```
"""
function p4est_corner_array_index(array, it)
    @ccall libp4est.p4est_corner_array_index(array::Ptr{sc_array_t}, it::Csize_t)::Ptr{p4est_corner_transform_t}
end

"""
    p4est_connectivity_read_inp_stream(stream, num_vertices, num_trees, vertices, tree_to_vertex)

Read an ABAQUS input file from a file stream.

This utility function reads a basic ABAQUS file supporting element type with the prefix C2D4, CPS4, and S4 in 2D and of type C3D8 reading them as bilinear quadrilateral and trilinear hexahedral trees respectively.

A basic 2D mesh is given below. The `*Node` section gives the vertex number and x, y, and z components for each vertex. The `*Element` section gives the 4 vertices in 2D (8 vertices in 3D) of each element in counter clockwise order. So in 2D the nodes are given as:

4 3 +-------------------+ | | | | | | | | | | | | +-------------------+ 1 2

and in 3D they are given as:

8 7 +---------------------+ |\\ |\\ | \\ | \\ | \\ | \\ | \\ | \\ | 5+---------------------+6 | | | | +----|----------------+ | 4\\ | 3 \\ | \\ | \\ | \\ | \\ | \\| \\| +---------------------+ 1 2

```c++
 *Heading
  box.inp
 *Node
 1,  -5, -5, 0
 2,   5, -5, 0
 3,   5,  5, 0
 4,  -5,  5, 0
 5,   0, -5, 0
 6,   5,  0, 0
 7,   0,  5, 0
 8,  -5,  0, 0
 9,   1, -1, 0
 10,  0,  0, 0
 11, -2,  1, 0
 *Element, type=CPS4, ELSET=Surface1
 1,  1, 10, 11, 8
 2,  3, 10, 9,  6
 3,  9, 10, 1,  5
 4,  7,  4, 8, 11
 5, 11, 10, 3,  7
 6,  2,  6, 9,  5
```

This code can be called two ways. The first, when `vertex`==NULL and `tree_to_vertex`==NULL, is used to count the number of trees and vertices in the connectivity to be generated by the `.inp` mesh in the *stream*. The second, when `vertices`!=NULL and `tree_to_vertex`!=NULL, fill `vertices` and `tree_to_vertex`. In this case `num_vertices` and `num_trees` need to be set to the maximum number of entries allocated in `vertices` and `tree_to_vertex`.

### Parameters
* `stream`:\\[in,out\\] file stream to read the connectivity from
* `num_vertices`:\\[in,out\\] the number of vertices in the connectivity
* `num_trees`:\\[in,out\\] the number of trees in the connectivity
* `vertices`:\\[out\\] the list of `vertices` of the connectivity
* `tree_to_vertex`:\\[out\\] the `tree_to_vertex` map of the connectivity
### Returns
0 if successful and nonzero if not
### Prototype
```c
int p4est_connectivity_read_inp_stream (FILE * stream, p4est_topidx_t * num_vertices, p4est_topidx_t * num_trees, double *vertices, p4est_topidx_t * tree_to_vertex);
```
"""
function p4est_connectivity_read_inp_stream(stream, num_vertices, num_trees, vertices, tree_to_vertex)
    @ccall libp4est.p4est_connectivity_read_inp_stream(stream::Ptr{Libc.FILE}, num_vertices::Ptr{p4est_topidx_t}, num_trees::Ptr{p4est_topidx_t}, vertices::Ptr{Cdouble}, tree_to_vertex::Ptr{p4est_topidx_t})::Cint
end

"""
    p4est_connectivity_read_inp(filename)

Create a p4est connectivity from an ABAQUS input file.

This utility function reads a basic ABAQUS file supporting element type with the prefix C2D4, CPS4, and S4 in 2D and of type C3D8 reading them as bilinear quadrilateral and trilinear hexahedral trees respectively.

A basic 2D mesh is given below. The `*Node` section gives the vertex number and x, y, and z components for each vertex. The `*Element` section gives the 4 vertices in 2D (8 vertices in 3D) of each element in counter clockwise order. So in 2D the nodes are given as:

4 3 +-------------------+ | | | | | | | | | | | | +-------------------+ 1 2

and in 3D they are given as:

8 7 +---------------------+ |\\ |\\ | \\ | \\ | \\ | \\ | \\ | \\ | 5+---------------------+6 | | | | +----|----------------+ | 4\\ | 3 \\ | \\ | \\ | \\ | \\ | \\| \\| +---------------------+ 1 2

```c++
 *Heading
  box.inp
 *Node
 1,  -5, -5, 0
 2,   5, -5, 0
 3,   5,  5, 0
 4,  -5,  5, 0
 5,   0, -5, 0
 6,   5,  0, 0
 7,   0,  5, 0
 8,  -5,  0, 0
 9,   1, -1, 0
 10,  0,  0, 0
 11, -2,  1, 0
 *Element, type=CPS4, ELSET=Surface1
 1,  1, 10, 11, 8
 2,  3, 10, 9,  6
 3,  9, 10, 1,  5
 4,  7,  4, 8, 11
 5, 11, 10, 3,  7
 6,  2,  6, 9,  5
```

This function reads a mesh from *filename* and returns an associated p4est connectivity.

### Parameters
* `filename`:\\[in\\] file to read the connectivity from
### Returns
an allocated connectivity associated with the mesh in *filename* or NULL if an error occurred.
### Prototype
```c
p4est_connectivity_t *p4est_connectivity_read_inp (const char *filename);
```
"""
function p4est_connectivity_read_inp(filename)
    @ccall libp4est.p4est_connectivity_read_inp(filename::Cstring)::Ptr{p4est_connectivity_t}
end

"""
    p8est_connect_type_t

Characterize a type of adjacency.

Several functions involve relationships between neighboring trees and/or quadrants, and their behavior depends on how one defines adjacency: 1) entities are adjacent if they share a face, or 2) entities are adjacent if they share a face or corner, or 3) entities are adjacent if they share a face, corner or edge. [`p8est_connect_type_t`](@ref) is used to choose the desired behavior. This enum must fit into an int8\\_t.
"""
@cenum p8est_connect_type_t::UInt32 begin
    P8EST_CONNECT_SELF = 30
    P8EST_CONNECT_FACE = 31
    P8EST_CONNECT_EDGE = 32
    P8EST_CONNECT_CORNER = 33
    P8EST_CONNECT_FULL = 33
end

"""
    p8est_connectivity_encode_t

Typedef for serialization method.

| Enumerator                   | Note                              |
| :--------------------------- | :-------------------------------- |
| P8EST\\_CONN\\_ENCODE\\_LAST | Invalid entry to close the list.  |
"""
@cenum p8est_connectivity_encode_t::UInt32 begin
    P8EST_CONN_ENCODE_NONE = 0
    P8EST_CONN_ENCODE_LAST = 1
end

"""
    p8est_connect_type_int(btype)

Convert the [`p8est_connect_type_t`](@ref) into a number.

### Parameters
* `btype`:\\[in\\] The balance type to convert.
### Returns
Returns 1, 2 or 3.
### Prototype
```c
int p8est_connect_type_int (p8est_connect_type_t btype);
```
"""
function p8est_connect_type_int(btype)
    @ccall libp4est.p8est_connect_type_int(btype::p8est_connect_type_t)::Cint
end

"""
    p8est_connect_type_string(btype)

Convert the [`p8est_connect_type_t`](@ref) into a const string.

### Parameters
* `btype`:\\[in\\] The balance type to convert.
### Returns
Returns a pointer to a constant string.
### Prototype
```c
const char *p8est_connect_type_string (p8est_connect_type_t btype);
```
"""
function p8est_connect_type_string(btype)
    @ccall libp4est.p8est_connect_type_string(btype::p8est_connect_type_t)::Cstring
end

"""
    p8est_connectivity

This structure holds the 3D inter-tree connectivity information. Identification of arbitrary faces, edges and corners is possible.

The arrays tree\\_to\\_* are stored in z ordering. For corners the order wrt. zyx is 000 001 010 011 100 101 110 111. For faces the order is -x +x -y +y -z +z. They are allocated [0][0]..[0][N-1]..[num\\_trees-1][0]..[num\\_trees-1][N-1]. where N is 6 for tree and face, 8 for corner, 12 for edge.

The values for tree\\_to\\_face are in 0..23 where ttf % 6 gives the face number and ttf / 6 the face orientation code. The orientation is determined as follows. Let my\\_face and other\\_face be the two face numbers of the connecting trees in 0..5. Then the first face corner of the lower of my\\_face and other\\_face connects to a face corner numbered 0..3 in the higher of my\\_face and other\\_face. The face orientation is defined as this number. If my\\_face == other\\_face, treating either of both faces as the lower one leads to the same result.

It is valid to specify num\\_vertices as 0. In this case vertices and tree\\_to\\_vertex are set to NULL. Otherwise the vertex coordinates are stored in the array vertices as [0][0]..[0][2]..[num\\_vertices-1][0]..[num\\_vertices-1][2].

The edges are only stored when they connect trees. In this case tree\\_to\\_edge indexes into *ett_offset*. Otherwise the tree\\_to\\_edge entry must be -1 and this edge is ignored. If num\\_edges == 0, tree\\_to\\_edge and edge\\_to\\_* arrays are set to NULL.

The arrays edge\\_to\\_* store a variable number of entries per edge. For edge e these are at position [ett\\_offset[e]]..[ett\\_offset[e+1]-1]. Their number for edge e is ett\\_offset[e+1] - ett\\_offset[e]. The entries encode all trees adjacent to edge e. The size of the edge\\_to\\_* arrays is num\\_ett = ett\\_offset[num\\_edges]. The edge\\_to\\_edge array holds values in 0..23, where the lower 12 indicate one edge orientation and the higher 12 the opposite edge orientation.

The corners are only stored when they connect trees. In this case tree\\_to\\_corner indexes into *ctt_offset*. Otherwise the tree\\_to\\_corner entry must be -1 and this corner is ignored. If num\\_corners == 0, tree\\_to\\_corner and corner\\_to\\_* arrays are set to NULL.

The arrays corner\\_to\\_* store a variable number of entries per corner. For corner c these are at position [ctt\\_offset[c]]..[ctt\\_offset[c+1]-1]. Their number for corner c is ctt\\_offset[c+1] - ctt\\_offset[c]. The entries encode all trees adjacent to corner c. The size of the corner\\_to\\_* arrays is num\\_ctt = ctt\\_offset[num\\_corners].

The *\\_to\\_attr arrays may have arbitrary contents defined by the user.

| Field                | Note                                                                                 |
| :------------------- | :----------------------------------------------------------------------------------- |
| num\\_vertices       | the number of vertices that define the *embedding* of the forest (not the topology)  |
| num\\_trees          | the number of trees                                                                  |
| num\\_edges          | the number of edges that help define the topology                                    |
| num\\_corners        | the number of corners that help define the topology                                  |
| vertices             | an array of size (3 * *num_vertices*)                                                |
| tree\\_to\\_vertex   | embed each tree into  ```c++ R^3 ```  for e.g. visualization (see p8est\\_vtk.h)     |
| tree\\_attr\\_bytes  | bytes per tree in tree\\_to\\_attr                                                   |
| tree\\_to\\_attr     | not touched by p4est                                                                 |
| tree\\_to\\_tree     | (6 * *num_trees*) neighbors across faces                                             |
| tree\\_to\\_face     | (6 * *num_trees*) face to face+orientation (see description)                         |
| tree\\_to\\_edge     | (12 * *num_trees*) or NULL (see description)                                         |
| ett\\_offset         | edge to offset in *edge_to_tree* and *edge_to_edge*                                  |
| edge\\_to\\_tree     | list of trees that meet at an edge                                                   |
| edge\\_to\\_edge     | list of tree-edges+orientations that meet at an edge (see description)               |
| tree\\_to\\_corner   | (8 * *num_trees*) or NULL (see description)                                          |
| ctt\\_offset         | corner to offset in *corner_to_tree* and *corner_to_corner*                          |
| corner\\_to\\_tree   | list of trees that meet at a corner                                                  |
| corner\\_to\\_corner | list of tree-corners that meet at a corner                                           |
"""
struct p8est_connectivity
    num_vertices::p4est_topidx_t
    num_trees::p4est_topidx_t
    num_edges::p4est_topidx_t
    num_corners::p4est_topidx_t
    vertices::Ptr{Cdouble}
    tree_to_vertex::Ptr{p4est_topidx_t}
    tree_attr_bytes::Csize_t
    tree_to_attr::Cstring
    tree_to_tree::Ptr{p4est_topidx_t}
    tree_to_face::Ptr{Int8}
    tree_to_edge::Ptr{p4est_topidx_t}
    ett_offset::Ptr{p4est_topidx_t}
    edge_to_tree::Ptr{p4est_topidx_t}
    edge_to_edge::Ptr{Int8}
    tree_to_corner::Ptr{p4est_topidx_t}
    ctt_offset::Ptr{p4est_topidx_t}
    corner_to_tree::Ptr{p4est_topidx_t}
    corner_to_corner::Ptr{Int8}
end

"""
This structure holds the 3D inter-tree connectivity information. Identification of arbitrary faces, edges and corners is possible.

The arrays tree\\_to\\_* are stored in z ordering. For corners the order wrt. zyx is 000 001 010 011 100 101 110 111. For faces the order is -x +x -y +y -z +z. They are allocated [0][0]..[0][N-1]..[num\\_trees-1][0]..[num\\_trees-1][N-1]. where N is 6 for tree and face, 8 for corner, 12 for edge.

The values for tree\\_to\\_face are in 0..23 where ttf % 6 gives the face number and ttf / 6 the face orientation code. The orientation is determined as follows. Let my\\_face and other\\_face be the two face numbers of the connecting trees in 0..5. Then the first face corner of the lower of my\\_face and other\\_face connects to a face corner numbered 0..3 in the higher of my\\_face and other\\_face. The face orientation is defined as this number. If my\\_face == other\\_face, treating either of both faces as the lower one leads to the same result.

It is valid to specify num\\_vertices as 0. In this case vertices and tree\\_to\\_vertex are set to NULL. Otherwise the vertex coordinates are stored in the array vertices as [0][0]..[0][2]..[num\\_vertices-1][0]..[num\\_vertices-1][2].

The edges are only stored when they connect trees. In this case tree\\_to\\_edge indexes into *ett_offset*. Otherwise the tree\\_to\\_edge entry must be -1 and this edge is ignored. If num\\_edges == 0, tree\\_to\\_edge and edge\\_to\\_* arrays are set to NULL.

The arrays edge\\_to\\_* store a variable number of entries per edge. For edge e these are at position [ett\\_offset[e]]..[ett\\_offset[e+1]-1]. Their number for edge e is ett\\_offset[e+1] - ett\\_offset[e]. The entries encode all trees adjacent to edge e. The size of the edge\\_to\\_* arrays is num\\_ett = ett\\_offset[num\\_edges]. The edge\\_to\\_edge array holds values in 0..23, where the lower 12 indicate one edge orientation and the higher 12 the opposite edge orientation.

The corners are only stored when they connect trees. In this case tree\\_to\\_corner indexes into *ctt_offset*. Otherwise the tree\\_to\\_corner entry must be -1 and this corner is ignored. If num\\_corners == 0, tree\\_to\\_corner and corner\\_to\\_* arrays are set to NULL.

The arrays corner\\_to\\_* store a variable number of entries per corner. For corner c these are at position [ctt\\_offset[c]]..[ctt\\_offset[c+1]-1]. Their number for corner c is ctt\\_offset[c+1] - ctt\\_offset[c]. The entries encode all trees adjacent to corner c. The size of the corner\\_to\\_* arrays is num\\_ctt = ctt\\_offset[num\\_corners].

The *\\_to\\_attr arrays may have arbitrary contents defined by the user.
"""
const p8est_connectivity_t = p8est_connectivity

"""
    p8est_connectivity_memory_used(conn)

Calculate memory usage of a connectivity structure.

### Parameters
* `conn`:\\[in\\] Connectivity structure.
### Returns
Memory used in bytes.
### Prototype
```c
size_t p8est_connectivity_memory_used (p8est_connectivity_t * conn);
```
"""
function p8est_connectivity_memory_used(conn)
    @ccall libp4est.p8est_connectivity_memory_used(conn::Ptr{p8est_connectivity_t})::Csize_t
end

struct p8est_edge_transform_t
    ntree::p4est_topidx_t
    nedge::Int8
    naxis::NTuple{3, Int8}
    nflip::Int8
    corners::Int8
end

struct p8est_edge_info_t
    iedge::Int8
    edge_transforms::sc_array_t
end

struct p8est_corner_transform_t
    ntree::p4est_topidx_t
    ncorner::Int8
end

struct p8est_corner_info_t
    icorner::p4est_topidx_t
    corner_transforms::sc_array_t
end

"""
    p8est_neighbor_transform_t

Generic interface for transformations between a tree and any of its neighbors

| Field             | Note                                                                        |
| :---------------- | :-------------------------------------------------------------------------- |
| neighbor\\_type   | type of connection to neighbor                                              |
| neighbor          | neighbor tree index                                                         |
| index\\_self      | index of interface from self's perspective                                  |
| index\\_neighbor  | index of interface from neighbor's perspective                              |
| perm              | permutation of dimensions when transforming self coords to neighbor coords  |
| sign              | sign changes when transforming self coords to neighbor coords               |
| origin\\_neighbor | point on the interface from self's perspective                              |
"""
struct p8est_neighbor_transform_t
    neighbor_type::p8est_connect_type_t
    neighbor::p4est_topidx_t
    index_self::Int8
    index_neighbor::Int8
    perm::NTuple{3, Int8}
    sign::NTuple{3, Int8}
    origin_self::NTuple{3, p4est_qcoord_t}
    origin_neighbor::NTuple{3, p4est_qcoord_t}
end

"""
    p8est_neighbor_transform_coordinates(nt, self_coords, neigh_coords)

Transform from self's coordinate system to neighbor's coordinate system.

### Parameters
* `nt`:\\[in\\] A neighbor transform.
* `self_coords`:\\[in\\] Input quadrant coordinates in self coordinates.
* `neigh_coords`:\\[out\\] Coordinates transformed into neighbor coordinates.
### Prototype
```c
void p8est_neighbor_transform_coordinates (const p8est_neighbor_transform_t * nt, const p4est_qcoord_t self_coords[P8EST_DIM], p4est_qcoord_t neigh_coords[P8EST_DIM]);
```
"""
function p8est_neighbor_transform_coordinates(nt, self_coords, neigh_coords)
    @ccall libp4est.p8est_neighbor_transform_coordinates(nt::Ptr{p8est_neighbor_transform_t}, self_coords::Ptr{p4est_qcoord_t}, neigh_coords::Ptr{p4est_qcoord_t})::Cvoid
end

"""
    p8est_neighbor_transform_coordinates_reverse(nt, neigh_coords, self_coords)

Transform from neighbor's coordinate system to self's coordinate system.

### Parameters
* `nt`:\\[in\\] A neighbor transform.
* `neigh_coords`:\\[in\\] Input quadrant coordinates in self coordinates.
* `self_coords`:\\[out\\] Coordinates transformed into neighbor coordinates.
### Prototype
```c
void p8est_neighbor_transform_coordinates_reverse (const p8est_neighbor_transform_t * nt, const p4est_qcoord_t neigh_coords[P8EST_DIM], p4est_qcoord_t self_coords[P8EST_DIM]);
```
"""
function p8est_neighbor_transform_coordinates_reverse(nt, neigh_coords, self_coords)
    @ccall libp4est.p8est_neighbor_transform_coordinates_reverse(nt::Ptr{p8est_neighbor_transform_t}, neigh_coords::Ptr{p4est_qcoord_t}, self_coords::Ptr{p4est_qcoord_t})::Cvoid
end

"""
    p8est_connectivity_get_neighbor_transforms(conn, tree_id, boundary_type, boundary_index, neighbor_transform_array)

### Prototype
```c
void p8est_connectivity_get_neighbor_transforms (p8est_connectivity_t *conn, p4est_topidx_t tree_id, p8est_connect_type_t boundary_type, int boundary_index, sc_array_t *neighbor_transform_array);
```
"""
function p8est_connectivity_get_neighbor_transforms(conn, tree_id, boundary_type, boundary_index, neighbor_transform_array)
    @ccall libp4est.p8est_connectivity_get_neighbor_transforms(conn::Ptr{p8est_connectivity_t}, tree_id::p4est_topidx_t, boundary_type::p8est_connect_type_t, boundary_index::Cint, neighbor_transform_array::Ptr{sc_array_t})::Cvoid
end

"""
    p8est_connectivity_face_neighbor_corner_set(c, f, nf, set)

Transform a corner across one of the adjacent faces into a neighbor tree. It expects a face permutation index that has been precomputed.

### Parameters
* `c`:\\[in\\] A corner number in 0..7.
* `f`:\\[in\\] A face number that touches the corner *c*.
* `nf`:\\[in\\] A neighbor face that is on the other side of *f*.
* `set`:\\[in\\] A value from *p8est_face_permutation_sets* that is obtained using *f*, *nf*, and a valid orientation: ref = p8est\\_face\\_permutation\\_refs[f][nf]; set = p8est\\_face\\_permutation\\_sets[ref][orientation];
### Returns
The corner number in 0..7 seen from the other face.
### Prototype
```c
int p8est_connectivity_face_neighbor_corner_set (int c, int f, int nf, int set);
```
"""
function p8est_connectivity_face_neighbor_corner_set(c, f, nf, set)
    @ccall libp4est.p8est_connectivity_face_neighbor_corner_set(c::Cint, f::Cint, nf::Cint, set::Cint)::Cint
end

"""
    p8est_connectivity_face_neighbor_face_corner(fc, f, nf, o)

Transform a face corner across one of the adjacent faces into a neighbor tree. This version expects the neighbor face and orientation separately.

### Parameters
* `fc`:\\[in\\] A face corner number in 0..3.
* `f`:\\[in\\] A face that the face corner *fc* is relative to.
* `nf`:\\[in\\] A neighbor face that is on the other side of *f*.
* `o`:\\[in\\] The orientation between tree boundary faces *f* and *nf*.
### Returns
The face corner number relative to the neighbor's face.
### Prototype
```c
int p8est_connectivity_face_neighbor_face_corner (int fc, int f, int nf, int o);
```
"""
function p8est_connectivity_face_neighbor_face_corner(fc, f, nf, o)
    @ccall libp4est.p8est_connectivity_face_neighbor_face_corner(fc::Cint, f::Cint, nf::Cint, o::Cint)::Cint
end

"""
    p8est_connectivity_face_neighbor_corner(c, f, nf, o)

Transform a corner across one of the adjacent faces into a neighbor tree. This version expects the neighbor face and orientation separately.

### Parameters
* `c`:\\[in\\] A corner number in 0..7.
* `f`:\\[in\\] A face number that touches the corner *c*.
* `nf`:\\[in\\] A neighbor face that is on the other side of *f*.
* `o`:\\[in\\] The orientation between tree boundary faces *f* and *nf*.
### Returns
The number of the corner seen from the neighbor tree.
### Prototype
```c
int p8est_connectivity_face_neighbor_corner (int c, int f, int nf, int o);
```
"""
function p8est_connectivity_face_neighbor_corner(c, f, nf, o)
    @ccall libp4est.p8est_connectivity_face_neighbor_corner(c::Cint, f::Cint, nf::Cint, o::Cint)::Cint
end

"""
    p8est_connectivity_face_neighbor_face_edge(fe, f, nf, o)

Transform a face-edge across one of the adjacent faces into a neighbor tree. This version expects the neighbor face and orientation separately.

### Parameters
* `fe`:\\[in\\] A face edge number in 0..3.
* `f`:\\[in\\] A face number that touches the edge *e*.
* `nf`:\\[in\\] A neighbor face that is on the other side of *f*.
* `o`:\\[in\\] The orientation between tree boundary faces *f* and *nf*.
### Returns
The face edge number seen from the neighbor tree.
### Prototype
```c
int p8est_connectivity_face_neighbor_face_edge (int fe, int f, int nf, int o);
```
"""
function p8est_connectivity_face_neighbor_face_edge(fe, f, nf, o)
    @ccall libp4est.p8est_connectivity_face_neighbor_face_edge(fe::Cint, f::Cint, nf::Cint, o::Cint)::Cint
end

"""
    p8est_connectivity_face_neighbor_edge(e, f, nf, o)

Transform an edge across one of the adjacent faces into a neighbor tree. This version expects the neighbor face and orientation separately.

### Parameters
* `e`:\\[in\\] A edge number in 0..11.
* `f`:\\[in\\] A face 0..5 that touches the edge *e*.
* `nf`:\\[in\\] A neighbor face that is on the other side of *f*.
* `o`:\\[in\\] The orientation between tree boundary faces *f* and *nf*.
### Returns
The edge's number seen from the neighbor.
### Prototype
```c
int p8est_connectivity_face_neighbor_edge (int e, int f, int nf, int o);
```
"""
function p8est_connectivity_face_neighbor_edge(e, f, nf, o)
    @ccall libp4est.p8est_connectivity_face_neighbor_edge(e::Cint, f::Cint, nf::Cint, o::Cint)::Cint
end

"""
    p8est_connectivity_edge_neighbor_edge_corner(ec, o)

Transform an edge corner across one of the adjacent edges into a neighbor tree.

### Parameters
* `ec`:\\[in\\] An edge corner number in 0..1.
* `o`:\\[in\\] The orientation of a tree boundary edge connection.
### Returns
The edge corner number seen from the other tree.
### Prototype
```c
int p8est_connectivity_edge_neighbor_edge_corner (int ec, int o);
```
"""
function p8est_connectivity_edge_neighbor_edge_corner(ec, o)
    @ccall libp4est.p8est_connectivity_edge_neighbor_edge_corner(ec::Cint, o::Cint)::Cint
end

"""
    p8est_connectivity_edge_neighbor_corner(c, e, ne, o)

Transform a corner across one of the adjacent edges into a neighbor tree. This version expects the neighbor edge and orientation separately.

### Parameters
* `c`:\\[in\\] A corner number in 0..7.
* `e`:\\[in\\] An edge 0..11 that touches the corner *c*.
* `ne`:\\[in\\] A neighbor edge that is on the other side of *.*
* `o`:\\[in\\] The orientation between tree boundary edges *e* and *ne*.
### Returns
Corner number seen from the neighbor.
### Prototype
```c
int p8est_connectivity_edge_neighbor_corner (int c, int e, int ne, int o);
```
"""
function p8est_connectivity_edge_neighbor_corner(c, e, ne, o)
    @ccall libp4est.p8est_connectivity_edge_neighbor_corner(c::Cint, e::Cint, ne::Cint, o::Cint)::Cint
end

"""
    p8est_connectivity_new(num_vertices, num_trees, num_edges, num_ett, num_corners, num_ctt)

Allocate a connectivity structure. The attribute fields are initialized to NULL.

### Parameters
* `num_vertices`:\\[in\\] Number of total vertices (i.e. geometric points).
* `num_trees`:\\[in\\] Number of trees in the forest.
* `num_edges`:\\[in\\] Number of tree-connecting edges.
* `num_ett`:\\[in\\] Number of total trees in edge\\_to\\_tree array.
* `num_corners`:\\[in\\] Number of tree-connecting corners.
* `num_ctt`:\\[in\\] Number of total trees in corner\\_to\\_tree array.
### Returns
A connectivity structure with allocated arrays.
### Prototype
```c
p8est_connectivity_t *p8est_connectivity_new (p4est_topidx_t num_vertices, p4est_topidx_t num_trees, p4est_topidx_t num_edges, p4est_topidx_t num_ett, p4est_topidx_t num_corners, p4est_topidx_t num_ctt);
```
"""
function p8est_connectivity_new(num_vertices, num_trees, num_edges, num_ett, num_corners, num_ctt)
    @ccall libp4est.p8est_connectivity_new(num_vertices::p4est_topidx_t, num_trees::p4est_topidx_t, num_edges::p4est_topidx_t, num_ett::p4est_topidx_t, num_corners::p4est_topidx_t, num_ctt::p4est_topidx_t)::Ptr{p8est_connectivity_t}
end

"""
    p8est_connectivity_new_copy(num_vertices, num_trees, num_edges, num_corners, vertices, ttv, ttt, ttf, tte, eoff, ett, ete, ttc, coff, ctt, ctc)

Allocate a connectivity structure and populate from constants. The attribute fields are initialized to NULL.

### Parameters
* `num_vertices`:\\[in\\] Number of total vertices (i.e. geometric points).
* `num_trees`:\\[in\\] Number of trees in the forest.
* `num_edges`:\\[in\\] Number of tree-connecting edges.
* `num_corners`:\\[in\\] Number of tree-connecting corners.
* `eoff`:\\[in\\] Edge-to-tree offsets (num\\_edges + 1 values). This must always be non-NULL; in trivial cases it is just a pointer to a p4est\\_topix value of 0.
* `coff`:\\[in\\] Corner-to-tree offsets (num\\_corners + 1 values). This must always be non-NULL; in trivial cases it is just a pointer to a p4est\\_topix value of 0.
### Returns
The connectivity is checked for validity.
### Prototype
```c
p8est_connectivity_t *p8est_connectivity_new_copy (p4est_topidx_t num_vertices, p4est_topidx_t num_trees, p4est_topidx_t num_edges, p4est_topidx_t num_corners, const double *vertices, const p4est_topidx_t * ttv, const p4est_topidx_t * ttt, const int8_t * ttf, const p4est_topidx_t * tte, const p4est_topidx_t * eoff, const p4est_topidx_t * ett, const int8_t * ete, const p4est_topidx_t * ttc, const p4est_topidx_t * coff, const p4est_topidx_t * ctt, const int8_t * ctc);
```
"""
function p8est_connectivity_new_copy(num_vertices, num_trees, num_edges, num_corners, vertices, ttv, ttt, ttf, tte, eoff, ett, ete, ttc, coff, ctt, ctc)
    @ccall libp4est.p8est_connectivity_new_copy(num_vertices::p4est_topidx_t, num_trees::p4est_topidx_t, num_edges::p4est_topidx_t, num_corners::p4est_topidx_t, vertices::Ptr{Cdouble}, ttv::Ptr{p4est_topidx_t}, ttt::Ptr{p4est_topidx_t}, ttf::Ptr{Int8}, tte::Ptr{p4est_topidx_t}, eoff::Ptr{p4est_topidx_t}, ett::Ptr{p4est_topidx_t}, ete::Ptr{Int8}, ttc::Ptr{p4est_topidx_t}, coff::Ptr{p4est_topidx_t}, ctt::Ptr{p4est_topidx_t}, ctc::Ptr{Int8})::Ptr{p8est_connectivity_t}
end

"""
    p8est_connectivity_bcast(conn_in, root, comm)

### Prototype
```c
p8est_connectivity_t *p8est_connectivity_bcast (p8est_connectivity_t * conn_in, int root, sc_MPI_Comm comm);
```
"""
function p8est_connectivity_bcast(conn_in, root, comm)
    @ccall libp4est.p8est_connectivity_bcast(conn_in::Ptr{p8est_connectivity_t}, root::Cint, comm::MPI_Comm)::Ptr{p8est_connectivity_t}
end

"""
    p8est_connectivity_destroy(connectivity)

Destroy a connectivity structure. Also destroy all attributes.

### Prototype
```c
void p8est_connectivity_destroy (p8est_connectivity_t * connectivity);
```
"""
function p8est_connectivity_destroy(connectivity)
    @ccall libp4est.p8est_connectivity_destroy(connectivity::Ptr{p8est_connectivity_t})::Cvoid
end

"""
    p8est_connectivity_set_attr(conn, bytes_per_tree)

Allocate or free the attribute fields in a connectivity.

### Parameters
* `conn`:\\[in,out\\] The conn->*\\_to\\_attr fields must either be NULL or previously be allocated by this function.
* `bytes_per_tree`:\\[in\\] If 0, tree\\_to\\_attr is freed (being NULL is ok). If positive, requested space is allocated.
### Prototype
```c
void p8est_connectivity_set_attr (p8est_connectivity_t * conn, size_t bytes_per_tree);
```
"""
function p8est_connectivity_set_attr(conn, bytes_per_tree)
    @ccall libp4est.p8est_connectivity_set_attr(conn::Ptr{p8est_connectivity_t}, bytes_per_tree::Csize_t)::Cvoid
end

"""
    p8est_connectivity_is_valid(connectivity)

Examine a connectivity structure.

### Returns
Returns true if structure is valid, false otherwise.
### Prototype
```c
int p8est_connectivity_is_valid (p8est_connectivity_t * connectivity);
```
"""
function p8est_connectivity_is_valid(connectivity)
    @ccall libp4est.p8est_connectivity_is_valid(connectivity::Ptr{p8est_connectivity_t})::Cint
end

"""
    p8est_connectivity_is_equal(conn1, conn2)

Check two connectivity structures for equality.

### Returns
Returns true if structures are equal, false otherwise.
### Prototype
```c
int p8est_connectivity_is_equal (p8est_connectivity_t * conn1, p8est_connectivity_t * conn2);
```
"""
function p8est_connectivity_is_equal(conn1, conn2)
    @ccall libp4est.p8est_connectivity_is_equal(conn1::Ptr{p8est_connectivity_t}, conn2::Ptr{p8est_connectivity_t})::Cint
end

"""
    p8est_connectivity_sink(conn, sink)

Write connectivity to a sink object.

### Parameters
* `conn`:\\[in\\] The connectivity to be written.
* `sink`:\\[in,out\\] The connectivity is written into this sink.
### Returns
0 on success, nonzero on error.
### Prototype
```c
int p8est_connectivity_sink (p8est_connectivity_t * conn, sc_io_sink_t * sink);
```
"""
function p8est_connectivity_sink(conn, sink)
    @ccall libp4est.p8est_connectivity_sink(conn::Ptr{p8est_connectivity_t}, sink::Ptr{sc_io_sink_t})::Cint
end

"""
    p8est_connectivity_deflate(conn, code)

Allocate memory and store the connectivity information there.

### Parameters
* `conn`:\\[in\\] The connectivity structure to be exported to memory.
* `code`:\\[in\\] Encoding and compression method for serialization.
### Returns
Newly created array that contains the information.
### Prototype
```c
sc_array_t *p8est_connectivity_deflate (p8est_connectivity_t * conn, p8est_connectivity_encode_t code);
```
"""
function p8est_connectivity_deflate(conn, code)
    @ccall libp4est.p8est_connectivity_deflate(conn::Ptr{p8est_connectivity_t}, code::p8est_connectivity_encode_t)::Ptr{sc_array_t}
end

"""
    p8est_connectivity_save(filename, connectivity)

Save a connectivity structure to disk.

### Parameters
* `filename`:\\[in\\] Name of the file to write.
* `connectivity`:\\[in\\] Valid connectivity structure.
### Returns
Returns 0 on success, nonzero on file error.
### Prototype
```c
int p8est_connectivity_save (const char *filename, p8est_connectivity_t * connectivity);
```
"""
function p8est_connectivity_save(filename, connectivity)
    @ccall libp4est.p8est_connectivity_save(filename::Cstring, connectivity::Ptr{p8est_connectivity_t})::Cint
end

"""
    p8est_connectivity_source(source)

Read connectivity from a source object.

### Parameters
* `source`:\\[in,out\\] The connectivity is read from this source.
### Returns
The newly created connectivity, or NULL on error.
### Prototype
```c
p8est_connectivity_t *p8est_connectivity_source (sc_io_source_t * source);
```
"""
function p8est_connectivity_source(source)
    @ccall libp4est.p8est_connectivity_source(source::Ptr{sc_io_source_t})::Ptr{p8est_connectivity_t}
end

"""
    p8est_connectivity_inflate(buffer)

Create new connectivity from a memory buffer. This function aborts on malloc errors.

### Parameters
* `buffer`:\\[in\\] The connectivity is created from this memory buffer.
### Returns
The newly created connectivity, or NULL on format error of the buffered connectivity data.
### Prototype
```c
p8est_connectivity_t *p8est_connectivity_inflate (sc_array_t * buffer);
```
"""
function p8est_connectivity_inflate(buffer)
    @ccall libp4est.p8est_connectivity_inflate(buffer::Ptr{sc_array_t})::Ptr{p8est_connectivity_t}
end

"""
    p8est_connectivity_load(filename, bytes)

Load a connectivity structure from disk.

### Parameters
* `filename`:\\[in\\] Name of the file to read.
* `bytes`:\\[out\\] Size in bytes of connectivity on disk or NULL.
### Returns
Returns valid connectivity, or NULL on file error.
### Prototype
```c
p8est_connectivity_t *p8est_connectivity_load (const char *filename, size_t *bytes);
```
"""
function p8est_connectivity_load(filename, bytes)
    @ccall libp4est.p8est_connectivity_load(filename::Cstring, bytes::Ptr{Csize_t})::Ptr{p8est_connectivity_t}
end

"""
    p8est_connectivity_new_unitcube()

Create a connectivity structure for the unit cube.

### Prototype
```c
p8est_connectivity_t *p8est_connectivity_new_unitcube (void);
```
"""
function p8est_connectivity_new_unitcube()
    @ccall libp4est.p8est_connectivity_new_unitcube()::Ptr{p8est_connectivity_t}
end

"""
    p8est_connectivity_new_periodic()

Create a connectivity structure for an all-periodic unit cube.

### Prototype
```c
p8est_connectivity_t *p8est_connectivity_new_periodic (void);
```
"""
function p8est_connectivity_new_periodic()
    @ccall libp4est.p8est_connectivity_new_periodic()::Ptr{p8est_connectivity_t}
end

"""
    p8est_connectivity_new_rotwrap()

Create a connectivity structure for a mostly periodic unit cube. The left and right faces are identified, and bottom and top rotated. Front and back are not identified.

### Prototype
```c
p8est_connectivity_t *p8est_connectivity_new_rotwrap (void);
```
"""
function p8est_connectivity_new_rotwrap()
    @ccall libp4est.p8est_connectivity_new_rotwrap()::Ptr{p8est_connectivity_t}
end

"""
    p8est_connectivity_new_twocubes()

Create a connectivity structure that contains two cubes.

### Prototype
```c
p8est_connectivity_t *p8est_connectivity_new_twocubes (void);
```
"""
function p8est_connectivity_new_twocubes()
    @ccall libp4est.p8est_connectivity_new_twocubes()::Ptr{p8est_connectivity_t}
end

"""
    p8est_connectivity_new_twotrees(l_face, r_face, orientation)

Create a connectivity structure for two trees being rotated w.r.t. each other in a user-defined way.

### Parameters
* `l_face`:\\[in\\] index of left face
* `r_face`:\\[in\\] index of right face
* `orientation`:\\[in\\] orientation of trees w.r.t. each other
### Prototype
```c
p8est_connectivity_t *p8est_connectivity_new_twotrees (int l_face, int r_face, int orientation);
```
"""
function p8est_connectivity_new_twotrees(l_face, r_face, orientation)
    @ccall libp4est.p8est_connectivity_new_twotrees(l_face::Cint, r_face::Cint, orientation::Cint)::Ptr{p8est_connectivity_t}
end

"""
    p8est_connectivity_new_twowrap()

Create a connectivity structure that contains two cubes where the two far ends are identified periodically.

### Prototype
```c
p8est_connectivity_t *p8est_connectivity_new_twowrap (void);
```
"""
function p8est_connectivity_new_twowrap()
    @ccall libp4est.p8est_connectivity_new_twowrap()::Ptr{p8est_connectivity_t}
end

"""
    p8est_connectivity_new_rotcubes()

Create a connectivity structure that contains a few cubes. These are rotated against each other to stress the topology routines.

### Prototype
```c
p8est_connectivity_t *p8est_connectivity_new_rotcubes (void);
```
"""
function p8est_connectivity_new_rotcubes()
    @ccall libp4est.p8est_connectivity_new_rotcubes()::Ptr{p8est_connectivity_t}
end

"""
    p8est_connectivity_new_brick(m, n, p, periodic_a, periodic_b, periodic_c)

An m by n by p array with periodicity in x, y, and z if periodic\\_a, periodic\\_b, and periodic\\_c are true, respectively.

### Prototype
```c
p8est_connectivity_t *p8est_connectivity_new_brick (int m, int n, int p, int periodic_a, int periodic_b, int periodic_c);
```
"""
function p8est_connectivity_new_brick(m, n, p, periodic_a, periodic_b, periodic_c)
    @ccall libp4est.p8est_connectivity_new_brick(m::Cint, n::Cint, p::Cint, periodic_a::Cint, periodic_b::Cint, periodic_c::Cint)::Ptr{p8est_connectivity_t}
end

"""
    p8est_connectivity_new_shell()

Create a connectivity structure that builds a spherical shell. It is made up of six connected parts [-1,1]x[-1,1]x[1,2]. This connectivity reuses vertices and relies on a geometry transformation. It is thus not suitable for [`p8est_connectivity_complete`](@ref).

### Prototype
```c
p8est_connectivity_t *p8est_connectivity_new_shell (void);
```
"""
function p8est_connectivity_new_shell()
    @ccall libp4est.p8est_connectivity_new_shell()::Ptr{p8est_connectivity_t}
end

"""
    p8est_connectivity_new_sphere()

Create a connectivity structure that builds a solid sphere. It is made up of two layers and a cube in the center. This connectivity reuses vertices and relies on a geometry transformation. It is thus not suitable for [`p8est_connectivity_complete`](@ref).

### Prototype
```c
p8est_connectivity_t *p8est_connectivity_new_sphere (void);
```
"""
function p8est_connectivity_new_sphere()
    @ccall libp4est.p8est_connectivity_new_sphere()::Ptr{p8est_connectivity_t}
end

"""
    p8est_connectivity_new_torus(nSegments)

Create a connectivity structure that builds a revolution torus.

This connectivity reuses vertices and relies on a geometry transformation. It is thus not suitable for [`p8est_connectivity_complete`](@ref).

This connectivity reuses ideas from disk2d connectivity. More precisely the torus is divided into segments around the revolution axis, each segments is made of 5 trees (à la disk2d). The total number of trees if 5 times the number of segments.

This connectivity is meant to be used with p8est_geometry_new_torus

### Parameters
* `nSegments`:\\[in\\] number of trees along the great circle
### Prototype
```c
p8est_connectivity_t *p8est_connectivity_new_torus (int nSegments);
```
"""
function p8est_connectivity_new_torus(nSegments)
    @ccall libp4est.p8est_connectivity_new_torus(nSegments::Cint)::Ptr{p8est_connectivity_t}
end

"""
    p8est_connectivity_new_byname(name)

Create connectivity structure from predefined catalogue.

### Parameters
* `name`:\\[in\\] Invokes connectivity\\_new\\_* function. brick235 brick (2, 3, 5, 0, 0, 0) periodic periodic rotcubes rotcubes rotwrap rotwrap shell shell sphere sphere twocubes twocubes twowrap twowrap unit unitcube
### Returns
An initialized connectivity if name is defined, NULL else.
### Prototype
```c
p8est_connectivity_t *p8est_connectivity_new_byname (const char *name);
```
"""
function p8est_connectivity_new_byname(name)
    @ccall libp4est.p8est_connectivity_new_byname(name::Cstring)::Ptr{p8est_connectivity_t}
end

"""
    p8est_connectivity_refine(conn, num_per_edge)

Uniformly refine a connectivity. This is useful if you would like to uniformly refine by something other than a power of 2.

### Parameters
* `conn`:\\[in\\] A valid connectivity
* `num_per_edge`:\\[in\\] The number of new trees in each direction. Must use no more than P8EST_OLD_QMAXLEVEL bits.
### Returns
a refined connectivity.
### Prototype
```c
p8est_connectivity_t *p8est_connectivity_refine (p8est_connectivity_t * conn, int num_per_edge);
```
"""
function p8est_connectivity_refine(conn, num_per_edge)
    @ccall libp4est.p8est_connectivity_refine(conn::Ptr{p8est_connectivity_t}, num_per_edge::Cint)::Ptr{p8est_connectivity_t}
end

"""
    p8est_expand_face_transform(iface, nface, ftransform)

Fill an array with the axis combination of a face neighbor transform.

### Parameters
* `iface`:\\[in\\] The number of the originating face.
* `nface`:\\[in\\] Encoded as nface = r * 6 + nf, where nf = 0..5 is the neigbbor's connecting face number and r = 0..3 is the relative orientation to the neighbor's face. This encoding matches [`p8est_connectivity_t`](@ref).
* `ftransform`:\\[out\\] This array holds 9 integers. [0]..[2] The coordinate axis sequence of the origin face, the first two referring to the tangentials and the third to the normal. A permutation of (0, 1, 2). [3]..[5] The coordinate axis sequence of the target face. [6]..[8] Edge reversal flags for tangential axes (boolean); face code in [0, 3] for the normal coordinate q: 0: q' = -q 1: q' = q + 1 2: q' = q - 1 3: q' = 2 - q
### Prototype
```c
void p8est_expand_face_transform (int iface, int nface, int ftransform[]);
```
"""
function p8est_expand_face_transform(iface, nface, ftransform)
    @ccall libp4est.p8est_expand_face_transform(iface::Cint, nface::Cint, ftransform::Ptr{Cint})::Cvoid
end

"""
    p8est_find_face_transform(connectivity, itree, iface, ftransform)

Fill an array with the axis combination of a face neighbor transform.

### Parameters
* `itree`:\\[in\\] The number of the originating tree.
* `iface`:\\[in\\] The number of the originating tree's face.
* `ftransform`:\\[out\\] This array holds 9 integers. [0]..[2] The coordinate axis sequence of the origin face. [3]..[5] The coordinate axis sequence of the target face. [6]..[8] Edge reverse flag for axes t1, t2; face code for n.
### Returns
The face neighbor tree if it exists, -1 otherwise.
### Prototype
```c
p4est_topidx_t p8est_find_face_transform (p8est_connectivity_t * connectivity, p4est_topidx_t itree, int iface, int ftransform[]);
```
"""
function p8est_find_face_transform(connectivity, itree, iface, ftransform)
    @ccall libp4est.p8est_find_face_transform(connectivity::Ptr{p8est_connectivity_t}, itree::p4est_topidx_t, iface::Cint, ftransform::Ptr{Cint})::p4est_topidx_t
end

"""
    p8est_find_edge_transform(connectivity, itree, iedge, ei)

Fills an array with information about edge neighbors.

### Parameters
* `itree`:\\[in\\] The number of the originating tree.
* `iedge`:\\[in\\] The number of the originating edge.
* `ei`:\\[in,out\\] A `p8est_edge_info_t` structure with initialized array.
### Prototype
```c
void p8est_find_edge_transform (p8est_connectivity_t * connectivity, p4est_topidx_t itree, int iedge, p8est_edge_info_t * ei);
```
"""
function p8est_find_edge_transform(connectivity, itree, iedge, ei)
    @ccall libp4est.p8est_find_edge_transform(connectivity::Ptr{p8est_connectivity_t}, itree::p4est_topidx_t, iedge::Cint, ei::Ptr{p8est_edge_info_t})::Cvoid
end

"""
    p8est_find_corner_transform(connectivity, itree, icorner, ci)

Fills an array with information about corner neighbors.

### Parameters
* `itree`:\\[in\\] The number of the originating tree.
* `icorner`:\\[in\\] The number of the originating corner.
* `ci`:\\[in,out\\] A `p8est_corner_info_t` structure with initialized array.
### Prototype
```c
void p8est_find_corner_transform (p8est_connectivity_t * connectivity, p4est_topidx_t itree, int icorner, p8est_corner_info_t * ci);
```
"""
function p8est_find_corner_transform(connectivity, itree, icorner, ci)
    @ccall libp4est.p8est_find_corner_transform(connectivity::Ptr{p8est_connectivity_t}, itree::p4est_topidx_t, icorner::Cint, ci::Ptr{p8est_corner_info_t})::Cvoid
end

"""
    p8est_connectivity_complete(conn)

Internally connect a connectivity based on tree\\_to\\_vertex information. Periodicity that is not inherent in the list of vertices will be lost.

### Parameters
* `conn`:\\[in,out\\] The connectivity needs to have proper vertices and tree\\_to\\_vertex fields. The tree\\_to\\_tree and tree\\_to\\_face fields must be allocated and satisfy [`p8est_connectivity_is_valid`](@ref) (conn) but will be overwritten. The edge and corner fields will be freed and allocated anew.
### Prototype
```c
void p8est_connectivity_complete (p8est_connectivity_t * conn);
```
"""
function p8est_connectivity_complete(conn)
    @ccall libp4est.p8est_connectivity_complete(conn::Ptr{p8est_connectivity_t})::Cvoid
end

"""
    p8est_connectivity_reduce(conn)

Removes corner and edge information of a connectivity such that enough information is left to run [`p8est_connectivity_complete`](@ref) successfully. The reduced connectivity still passes [`p8est_connectivity_is_valid`](@ref).

### Parameters
* `conn`:\\[in,out\\] The connectivity to be reduced.
### Prototype
```c
void p8est_connectivity_reduce (p8est_connectivity_t * conn);
```
"""
function p8est_connectivity_reduce(conn)
    @ccall libp4est.p8est_connectivity_reduce(conn::Ptr{p8est_connectivity_t})::Cvoid
end

"""
    p8est_connectivity_permute(conn, perm, is_current_to_new)

[`p8est_connectivity_permute`](@ref) Given a permutation *perm* of the trees in a connectivity *conn*, permute the trees of *conn* in place and update *conn* to match.

### Parameters
* `conn`:\\[in,out\\] The connectivity whose trees are permuted.
* `perm`:\\[in\\] A permutation array, whose elements are size\\_t's.
* `is_current_to_new`:\\[in\\] if true, the jth entry of perm is the new index for the entry whose current index is j, otherwise the jth entry of perm is the current index of the tree whose index will be j after the permutation.
### Prototype
```c
void p8est_connectivity_permute (p8est_connectivity_t * conn, sc_array_t * perm, int is_current_to_new);
```
"""
function p8est_connectivity_permute(conn, perm, is_current_to_new)
    @ccall libp4est.p8est_connectivity_permute(conn::Ptr{p8est_connectivity_t}, perm::Ptr{sc_array_t}, is_current_to_new::Cint)::Cvoid
end

"""
    p8est_connectivity_join_faces(conn, tree_left, tree_right, face_left, face_right, orientation)

[`p8est_connectivity_join_faces`](@ref) This function takes an existing valid connectivity *conn* and modifies it by joining two tree faces that are currently boundary faces.

### Parameters
* `conn`:\\[in,out\\] connectivity that will be altered.
* `tree_left`:\\[in\\] tree that will be on the left side of the joined faces.
* `tree_right`:\\[in\\] tree that will be on the right side of the joined faces.
* `face_left`:\\[in\\] face of *tree_left* that will be joined.
* `face_right`:\\[in\\] face of *tree_right* that will be joined.
* `orientation`:\\[in\\] the orientation of *face_left* and *face_right* once joined (see the description of [`p8est_connectivity_t`](@ref) to understand orientation).
### Prototype
```c
void p8est_connectivity_join_faces (p8est_connectivity_t * conn, p4est_topidx_t tree_left, p4est_topidx_t tree_right, int face_left, int face_right, int orientation);
```
"""
function p8est_connectivity_join_faces(conn, tree_left, tree_right, face_left, face_right, orientation)
    @ccall libp4est.p8est_connectivity_join_faces(conn::Ptr{p8est_connectivity_t}, tree_left::p4est_topidx_t, tree_right::p4est_topidx_t, face_left::Cint, face_right::Cint, orientation::Cint)::Cvoid
end

"""
    p8est_connectivity_is_equivalent(conn1, conn2)

[`p8est_connectivity_is_equivalent`](@ref) This function compares two connectivities for equivalence: it returns *true* if they are the same connectivity, or if they have the same topology. The definition of topological sameness is strict: there is no attempt made to determine whether permutation and/or rotation of the trees makes the connectivities equivalent.

### Parameters
* `conn1`:\\[in\\] a valid connectivity
* `conn2`:\\[out\\] a valid connectivity
### Prototype
```c
int p8est_connectivity_is_equivalent (p8est_connectivity_t * conn1, p8est_connectivity_t * conn2);
```
"""
function p8est_connectivity_is_equivalent(conn1, conn2)
    @ccall libp4est.p8est_connectivity_is_equivalent(conn1::Ptr{p8est_connectivity_t}, conn2::Ptr{p8est_connectivity_t})::Cint
end

"""
    p8est_edge_array_index(array, it)

### Prototype
```c
static inline p8est_edge_transform_t * p8est_edge_array_index (sc_array_t * array, size_t it);
```
"""
function p8est_edge_array_index(array, it)
    @ccall libp4est.p8est_edge_array_index(array::Ptr{sc_array_t}, it::Csize_t)::Ptr{p8est_edge_transform_t}
end

"""
    p8est_corner_array_index(array, it)

### Prototype
```c
static inline p8est_corner_transform_t * p8est_corner_array_index (sc_array_t * array, size_t it);
```
"""
function p8est_corner_array_index(array, it)
    @ccall libp4est.p8est_corner_array_index(array::Ptr{sc_array_t}, it::Csize_t)::Ptr{p8est_corner_transform_t}
end

"""
    p8est_connectivity_read_inp_stream(stream, num_vertices, num_trees, vertices, tree_to_vertex)

Read an ABAQUS input file from a file stream.

This utility function reads a basic ABAQUS file supporting element type with the prefix C2D4, CPS4, and S4 in 2D and of type C3D8 reading them as bilinear quadrilateral and trilinear hexahedral trees respectively.

A basic 2D mesh is given below. The `*Node` section gives the vertex number and x, y, and z components for each vertex. The `*Element` section gives the 4 vertices in 2D (8 vertices in 3D) of each element in counter clockwise order. So in 2D the nodes are given as:

4 3 +-------------------+ | | | | | | | | | | | | +-------------------+ 1 2

and in 3D they are given as:

8 7 +---------------------+ |\\ |\\ | \\ | \\ | \\ | \\ | \\ | \\ | 5+---------------------+6 | | | | +----|----------------+ | 4\\ | 3 \\ | \\ | \\ | \\ | \\ | \\| \\| +---------------------+ 1 2

```c++
 *Heading
  box.inp
 *Node
     1,    5,   -5,    5
     2,    5,    5,    5
     3,    5,    0,    5
     4,   -5,    5,    5
     5,    0,    5,    5
     6,   -5,   -5,    5
     7,   -5,    0,    5
     8,    0,   -5,    5
     9,    0,    0,    5
    10,    5,    5,   -5
    11,    5,   -5,   -5
    12,    5,    0,   -5
    13,   -5,   -5,   -5
    14,    0,   -5,   -5
    15,   -5,    5,   -5
    16,   -5,    0,   -5
    17,    0,    5,   -5
    18,    0,    0,   -5
    19,   -5,   -5,    0
    20,    5,   -5,    0
    21,    0,   -5,    0
    22,   -5,    5,    0
    23,   -5,    0,    0
    24,    5,    5,    0
    25,    0,    5,    0
    26,    5,    0,    0
    27,    0,    0,    0
 *Element, type=C3D8, ELSET=EB1
     1,       6,      19,      23,       7,       8,      21,      27,       9
     2,      19,      13,      16,      23,      21,      14,      18,      27
     3,       7,      23,      22,       4,       9,      27,      25,       5
     4,      23,      16,      15,      22,      27,      18,      17,      25
     5,       8,      21,      27,       9,       1,      20,      26,       3
     6,      21,      14,      18,      27,      20,      11,      12,      26
     7,       9,      27,      25,       5,       3,      26,      24,       2
     8,      27,      18,      17,      25,      26,      12,      10,      24
```

This code can be called two ways. The first, when `vertex`==NULL and `tree_to_vertex`==NULL, is used to count the number of trees and vertices in the connectivity to be generated by the `.inp` mesh in the *stream*. The second, when `vertices`!=NULL and `tree_to_vertex`!=NULL, fill `vertices` and `tree_to_vertex`. In this case `num_vertices` and `num_trees` need to be set to the maximum number of entries allocated in `vertices` and `tree_to_vertex`.

### Parameters
* `stream`:\\[in,out\\] file stream to read the connectivity from
* `num_vertices`:\\[in,out\\] the number of vertices in the connectivity
* `num_trees`:\\[in,out\\] the number of trees in the connectivity
* `vertices`:\\[out\\] the list of `vertices` of the connectivity
* `tree_to_vertex`:\\[out\\] the `tree_to_vertex` map of the connectivity
### Returns
0 if successful and nonzero if not
### Prototype
```c
int p8est_connectivity_read_inp_stream (FILE * stream, p4est_topidx_t * num_vertices, p4est_topidx_t * num_trees, double *vertices, p4est_topidx_t * tree_to_vertex);
```
"""
function p8est_connectivity_read_inp_stream(stream, num_vertices, num_trees, vertices, tree_to_vertex)
    @ccall libp4est.p8est_connectivity_read_inp_stream(stream::Ptr{Libc.FILE}, num_vertices::Ptr{p4est_topidx_t}, num_trees::Ptr{p4est_topidx_t}, vertices::Ptr{Cdouble}, tree_to_vertex::Ptr{p4est_topidx_t})::Cint
end

"""
    p8est_connectivity_read_inp(filename)

Create a p4est connectivity from an ABAQUS input file.

This utility function reads a basic ABAQUS file supporting element type with the prefix C2D4, CPS4, and S4 in 2D and of type C3D8 reading them as bilinear quadrilateral and trilinear hexahedral trees respectively.

A basic 2D mesh is given below. The `*Node` section gives the vertex number and x, y, and z components for each vertex. The `*Element` section gives the 4 vertices in 2D (8 vertices in 3D) of each element in counter clockwise order. So in 2D the nodes are given as:

4 3 +-------------------+ | | | | | | | | | | | | +-------------------+ 1 2

and in 3D they are given as:

8 7 +---------------------+ |\\ |\\ | \\ | \\ | \\ | \\ | \\ | \\ | 5+---------------------+6 | | | | +----|----------------+ | 4\\ | 3 \\ | \\ | \\ | \\ | \\ | \\| \\| +---------------------+ 1 2

```c++
 *Heading
  box.inp
 *Node
     1,    5,   -5,    5
     2,    5,    5,    5
     3,    5,    0,    5
     4,   -5,    5,    5
     5,    0,    5,    5
     6,   -5,   -5,    5
     7,   -5,    0,    5
     8,    0,   -5,    5
     9,    0,    0,    5
    10,    5,    5,   -5
    11,    5,   -5,   -5
    12,    5,    0,   -5
    13,   -5,   -5,   -5
    14,    0,   -5,   -5
    15,   -5,    5,   -5
    16,   -5,    0,   -5
    17,    0,    5,   -5
    18,    0,    0,   -5
    19,   -5,   -5,    0
    20,    5,   -5,    0
    21,    0,   -5,    0
    22,   -5,    5,    0
    23,   -5,    0,    0
    24,    5,    5,    0
    25,    0,    5,    0
    26,    5,    0,    0
    27,    0,    0,    0
 *Element, type=C3D8, ELSET=EB1
     1,       6,      19,      23,       7,       8,      21,      27,       9
     2,      19,      13,      16,      23,      21,      14,      18,      27
     3,       7,      23,      22,       4,       9,      27,      25,       5
     4,      23,      16,      15,      22,      27,      18,      17,      25
     5,       8,      21,      27,       9,       1,      20,      26,       3
     6,      21,      14,      18,      27,      20,      11,      12,      26
     7,       9,      27,      25,       5,       3,      26,      24,       2
     8,      27,      18,      17,      25,      26,      12,      10,      24
```

This function reads a mesh from *filename* and returns an associated p4est connectivity.

### Parameters
* `filename`:\\[in\\] file to read the connectivity from
### Returns
an allocated connectivity associated with the mesh in *filename*
### Prototype
```c
p8est_connectivity_t *p8est_connectivity_read_inp (const char *filename);
```
"""
function p8est_connectivity_read_inp(filename)
    @ccall libp4est.p8est_connectivity_read_inp(filename::Cstring)::Ptr{p8est_connectivity_t}
end

"""
    t8_cmesh_new_from_p4est(conn, comm, do_partition)

### Prototype
```c
t8_cmesh_t t8_cmesh_new_from_p4est (p4est_connectivity_t * conn, sc_MPI_Comm comm, int do_partition);
```
"""
function t8_cmesh_new_from_p4est(conn, comm, do_partition)
    @ccall libt8.t8_cmesh_new_from_p4est(conn::Ptr{p4est_connectivity_t}, comm::MPI_Comm, do_partition::Cint)::t8_cmesh_t
end

"""
    t8_cmesh_new_from_p8est(conn, comm, do_partition)

### Prototype
```c
t8_cmesh_t t8_cmesh_new_from_p8est (p8est_connectivity_t * conn, sc_MPI_Comm comm, int do_partition);
```
"""
function t8_cmesh_new_from_p8est(conn, comm, do_partition)
    @ccall libt8.t8_cmesh_new_from_p8est(conn::Ptr{p8est_connectivity_t}, comm::MPI_Comm, do_partition::Cint)::t8_cmesh_t
end

"""
    t8_cmesh_new_empty(comm, do_partition, dimension)

### Prototype
```c
t8_cmesh_t t8_cmesh_new_empty (sc_MPI_Comm comm, int do_partition, int dimension);
```
"""
function t8_cmesh_new_empty(comm, do_partition, dimension)
    @ccall libt8.t8_cmesh_new_empty(comm::MPI_Comm, do_partition::Cint, dimension::Cint)::t8_cmesh_t
end

"""
    t8_cmesh_new_from_class(eclass, comm)

### Prototype
```c
t8_cmesh_t t8_cmesh_new_from_class (t8_eclass_t eclass, sc_MPI_Comm comm);
```
"""
function t8_cmesh_new_from_class(eclass, comm)
    @ccall libt8.t8_cmesh_new_from_class(eclass::t8_eclass_t, comm::MPI_Comm)::t8_cmesh_t
end

"""
    t8_cmesh_new_hypercube(eclass, comm, do_bcast, do_partition, periodic)

### Prototype
```c
t8_cmesh_t t8_cmesh_new_hypercube (t8_eclass_t eclass, sc_MPI_Comm comm, int do_bcast, int do_partition, int periodic);
```
"""
function t8_cmesh_new_hypercube(eclass, comm, do_bcast, do_partition, periodic)
    @ccall libt8.t8_cmesh_new_hypercube(eclass::t8_eclass_t, comm::MPI_Comm, do_bcast::Cint, do_partition::Cint, periodic::Cint)::t8_cmesh_t
end

"""
    t8_cmesh_new_hypercube_hybrid(comm, do_partition, periodic)

### Prototype
```c
t8_cmesh_t t8_cmesh_new_hypercube_hybrid (sc_MPI_Comm comm, int do_partition, int periodic);
```
"""
function t8_cmesh_new_hypercube_hybrid(comm, do_partition, periodic)
    @ccall libt8.t8_cmesh_new_hypercube_hybrid(comm::MPI_Comm, do_partition::Cint, periodic::Cint)::t8_cmesh_t
end

"""
    t8_cmesh_new_periodic(comm, dim)

### Prototype
```c
t8_cmesh_t t8_cmesh_new_periodic (sc_MPI_Comm comm, int dim);
```
"""
function t8_cmesh_new_periodic(comm, dim)
    @ccall libt8.t8_cmesh_new_periodic(comm::MPI_Comm, dim::Cint)::t8_cmesh_t
end

"""
    t8_cmesh_new_periodic_tri(comm)

### Prototype
```c
t8_cmesh_t t8_cmesh_new_periodic_tri (sc_MPI_Comm comm);
```
"""
function t8_cmesh_new_periodic_tri(comm)
    @ccall libt8.t8_cmesh_new_periodic_tri(comm::MPI_Comm)::t8_cmesh_t
end

"""
    t8_cmesh_new_periodic_hybrid(comm)

### Prototype
```c
t8_cmesh_t t8_cmesh_new_periodic_hybrid (sc_MPI_Comm comm);
```
"""
function t8_cmesh_new_periodic_hybrid(comm)
    @ccall libt8.t8_cmesh_new_periodic_hybrid(comm::MPI_Comm)::t8_cmesh_t
end

"""
    t8_cmesh_new_periodic_line_more_trees(comm)

### Prototype
```c
t8_cmesh_t t8_cmesh_new_periodic_line_more_trees (sc_MPI_Comm comm);
```
"""
function t8_cmesh_new_periodic_line_more_trees(comm)
    @ccall libt8.t8_cmesh_new_periodic_line_more_trees(comm::MPI_Comm)::t8_cmesh_t
end

"""
    t8_cmesh_new_bigmesh(eclass, num_trees, comm)

### Prototype
```c
t8_cmesh_t t8_cmesh_new_bigmesh (t8_eclass_t eclass, int num_trees, sc_MPI_Comm comm);
```
"""
function t8_cmesh_new_bigmesh(eclass, num_trees, comm)
    @ccall libt8.t8_cmesh_new_bigmesh(eclass::t8_eclass_t, num_trees::Cint, comm::MPI_Comm)::t8_cmesh_t
end

"""
    t8_cmesh_new_line_zigzag(comm)

### Prototype
```c
t8_cmesh_t t8_cmesh_new_line_zigzag (sc_MPI_Comm comm);
```
"""
function t8_cmesh_new_line_zigzag(comm)
    @ccall libt8.t8_cmesh_new_line_zigzag(comm::MPI_Comm)::t8_cmesh_t
end

"""
    t8_cmesh_new_prism_cake(comm, num_of_prisms)

### Prototype
```c
t8_cmesh_t t8_cmesh_new_prism_cake (sc_MPI_Comm comm, int num_of_prisms);
```
"""
function t8_cmesh_new_prism_cake(comm, num_of_prisms)
    @ccall libt8.t8_cmesh_new_prism_cake(comm::MPI_Comm, num_of_prisms::Cint)::t8_cmesh_t
end

"""
    t8_cmesh_new_prism_deformed(comm)

### Prototype
```c
t8_cmesh_t t8_cmesh_new_prism_deformed (sc_MPI_Comm comm);
```
"""
function t8_cmesh_new_prism_deformed(comm)
    @ccall libt8.t8_cmesh_new_prism_deformed(comm::MPI_Comm)::t8_cmesh_t
end

"""
    t8_cmesh_new_pyramid_deformed(comm)

### Prototype
```c
t8_cmesh_t t8_cmesh_new_pyramid_deformed (sc_MPI_Comm comm);
```
"""
function t8_cmesh_new_pyramid_deformed(comm)
    @ccall libt8.t8_cmesh_new_pyramid_deformed(comm::MPI_Comm)::t8_cmesh_t
end

"""
    t8_cmesh_new_prism_cake_funny_oriented(comm)

### Prototype
```c
t8_cmesh_t t8_cmesh_new_prism_cake_funny_oriented (sc_MPI_Comm comm);
```
"""
function t8_cmesh_new_prism_cake_funny_oriented(comm)
    @ccall libt8.t8_cmesh_new_prism_cake_funny_oriented(comm::MPI_Comm)::t8_cmesh_t
end

"""
    t8_cmesh_new_prism_geometry(comm)

### Prototype
```c
t8_cmesh_t t8_cmesh_new_prism_geometry (sc_MPI_Comm comm);
```
"""
function t8_cmesh_new_prism_geometry(comm)
    @ccall libt8.t8_cmesh_new_prism_geometry(comm::MPI_Comm)::t8_cmesh_t
end

"""
    t8_cmesh_new_disjoint_bricks(num_x, num_y, num_z, x_periodic, y_periodic, z_periodic, comm)

### Prototype
```c
t8_cmesh_t t8_cmesh_new_disjoint_bricks (t8_gloidx_t num_x, t8_gloidx_t num_y, t8_gloidx_t num_z, int x_periodic, int y_periodic, int z_periodic, sc_MPI_Comm comm);
```
"""
function t8_cmesh_new_disjoint_bricks(num_x, num_y, num_z, x_periodic, y_periodic, z_periodic, comm)
    @ccall libt8.t8_cmesh_new_disjoint_bricks(num_x::t8_gloidx_t, num_y::t8_gloidx_t, num_z::t8_gloidx_t, x_periodic::Cint, y_periodic::Cint, z_periodic::Cint, comm::MPI_Comm)::t8_cmesh_t
end

"""
    t8_cmesh_new_tet_orientation_test(comm)

### Prototype
```c
t8_cmesh_t t8_cmesh_new_tet_orientation_test (sc_MPI_Comm comm);
```
"""
function t8_cmesh_new_tet_orientation_test(comm)
    @ccall libt8.t8_cmesh_new_tet_orientation_test(comm::MPI_Comm)::t8_cmesh_t
end

"""
    t8_cmesh_new_hybrid_gate(comm)

### Prototype
```c
t8_cmesh_t t8_cmesh_new_hybrid_gate (sc_MPI_Comm comm);
```
"""
function t8_cmesh_new_hybrid_gate(comm)
    @ccall libt8.t8_cmesh_new_hybrid_gate(comm::MPI_Comm)::t8_cmesh_t
end

"""
    t8_cmesh_new_hybrid_gate_deformed(comm)

### Prototype
```c
t8_cmesh_t t8_cmesh_new_hybrid_gate_deformed (sc_MPI_Comm comm);
```
"""
function t8_cmesh_new_hybrid_gate_deformed(comm)
    @ccall libt8.t8_cmesh_new_hybrid_gate_deformed(comm::MPI_Comm)::t8_cmesh_t
end

"""
    t8_cmesh_new_full_hybrid(comm)

### Prototype
```c
t8_cmesh_t t8_cmesh_new_full_hybrid (sc_MPI_Comm comm);
```
"""
function t8_cmesh_new_full_hybrid(comm)
    @ccall libt8.t8_cmesh_new_full_hybrid(comm::MPI_Comm)::t8_cmesh_t
end

"""
    t8_cmesh_new_pyramid_cake(comm, num_of_pyra)

### Prototype
```c
t8_cmesh_t t8_cmesh_new_pyramid_cake (sc_MPI_Comm comm, int num_of_pyra);
```
"""
function t8_cmesh_new_pyramid_cake(comm, num_of_pyra)
    @ccall libt8.t8_cmesh_new_pyramid_cake(comm::MPI_Comm, num_of_pyra::Cint)::t8_cmesh_t
end

"""
    t8_cmesh_new_long_brick_pyramid(comm, num_cubes)

### Prototype
```c
t8_cmesh_t t8_cmesh_new_long_brick_pyramid (sc_MPI_Comm comm, int num_cubes);
```
"""
function t8_cmesh_new_long_brick_pyramid(comm, num_cubes)
    @ccall libt8.t8_cmesh_new_long_brick_pyramid(comm::MPI_Comm, num_cubes::Cint)::t8_cmesh_t
end

"""
    t8_cmesh_new_row_of_cubes(num_trees, set_attributes, comm)

### Prototype
```c
t8_cmesh_t t8_cmesh_new_row_of_cubes (t8_locidx_t num_trees, const int set_attributes, sc_MPI_Comm comm);
```
"""
function t8_cmesh_new_row_of_cubes(num_trees, set_attributes, comm)
    @ccall libt8.t8_cmesh_new_row_of_cubes(num_trees::t8_locidx_t, set_attributes::Cint, comm::MPI_Comm)::t8_cmesh_t
end

"""
    t8_cmesh_get_tree_geom_name(cmesh, gtreeid)

Get the name of the geometry stored for a tree in a cmesh.

### Parameters
* `cmesh`:\\[in\\] A committed cmesh.
* `gtreeid`:\\[in\\] A global tree in *cmesh*.
### Returns
The name of the tree's geometry or NULL if no geometry is set for this tree.
### Prototype
```c
const char *t8_cmesh_get_tree_geom_name (t8_cmesh_t cmesh, t8_gloidx_t gtreeid);
```
"""
function t8_cmesh_get_tree_geom_name(cmesh, gtreeid)
    @ccall libt8.t8_cmesh_get_tree_geom_name(cmesh::t8_cmesh_t, gtreeid::t8_gloidx_t)::Cstring
end

# no prototype is found for this function at t8_cmesh_testcases.h:40:21, please use with caution
"""
    t8_get_number_of_comm_only_cmesh_testcases()

The functions t8\\_get\\_*\\_cmesh\\_testcases

### Returns
the number of testcases for a given cmesh type.  To get all possible inputs, we multiply  the number of different inputs of all variables. The function t8\\_get\\_comm\\_only\\_cmesh\\_testcases() returns the number of testcases for all cmeshes that only take a comm as input all added together.
### Prototype
```c
int t8_get_number_of_comm_only_cmesh_testcases ();
```
"""
function t8_get_number_of_comm_only_cmesh_testcases()
    @ccall libt8.t8_get_number_of_comm_only_cmesh_testcases()::Cint
end

# no prototype is found for this function at t8_cmesh_testcases.h:44:21, please use with caution
"""
    t8_get_number_of_new_hypercube_cmesh_testcases()

The function t8\\_get\\_new\\_hypercube\\_cmesh\\_testcases()

### Returns
the number of testcases for the hypercube cmesh.
### Prototype
```c
int t8_get_number_of_new_hypercube_cmesh_testcases ();
```
"""
function t8_get_number_of_new_hypercube_cmesh_testcases()
    @ccall libt8.t8_get_number_of_new_hypercube_cmesh_testcases()::Cint
end

# no prototype is found for this function at t8_cmesh_testcases.h:48:21, please use with caution
"""
    t8_get_number_of_new_empty_cmesh_testcases()

The function t8\\_get\\_new\\_empty\\_cmesh\\_testcases()

### Returns
the number of testcases for the empty cmesh.
### Prototype
```c
int t8_get_number_of_new_empty_cmesh_testcases ();
```
"""
function t8_get_number_of_new_empty_cmesh_testcases()
    @ccall libt8.t8_get_number_of_new_empty_cmesh_testcases()::Cint
end

# no prototype is found for this function at t8_cmesh_testcases.h:52:21, please use with caution
"""
    t8_get_number_of_new_from_class_cmesh_testcases()

The function t8\\_get\\_new\\_from\\_class\\_cmesh\\_testcases()

### Returns
the number of testcases for the new\\_from\\_class cmesh.
### Prototype
```c
int t8_get_number_of_new_from_class_cmesh_testcases ();
```
"""
function t8_get_number_of_new_from_class_cmesh_testcases()
    @ccall libt8.t8_get_number_of_new_from_class_cmesh_testcases()::Cint
end

# no prototype is found for this function at t8_cmesh_testcases.h:56:21, please use with caution
"""
    t8_get_number_of_new_hypercube_hybrid_cmesh_testcases()

The function t8\\_get\\_new\\_hypercube\\_hybrid\\_cmesh\\_testcases()

### Returns
the number of testcases for the new\\_hypercube\\_hybrid cmesh.
### Prototype
```c
int t8_get_number_of_new_hypercube_hybrid_cmesh_testcases ();
```
"""
function t8_get_number_of_new_hypercube_hybrid_cmesh_testcases()
    @ccall libt8.t8_get_number_of_new_hypercube_hybrid_cmesh_testcases()::Cint
end

# no prototype is found for this function at t8_cmesh_testcases.h:60:21, please use with caution
"""
    t8_get_number_of_new_periodic_cmesh_testcases()

The function t8\\_get\\_new\\_periodic\\_cmesh\\_testcases()

### Returns
the number of testcases for the new\\_periodic cmesh.
### Prototype
```c
int t8_get_number_of_new_periodic_cmesh_testcases ();
```
"""
function t8_get_number_of_new_periodic_cmesh_testcases()
    @ccall libt8.t8_get_number_of_new_periodic_cmesh_testcases()::Cint
end

# no prototype is found for this function at t8_cmesh_testcases.h:64:21, please use with caution
"""
    t8_get_number_of_new_bigmesh_cmesh_testcases()

The function t8\\_get\\_new\\_bigmesh\\_cmesh\\_testcases()

### Returns
the number of testcases for the new\\_bigmesh cmesh.
### Prototype
```c
int t8_get_number_of_new_bigmesh_cmesh_testcases ();
```
"""
function t8_get_number_of_new_bigmesh_cmesh_testcases()
    @ccall libt8.t8_get_number_of_new_bigmesh_cmesh_testcases()::Cint
end

# no prototype is found for this function at t8_cmesh_testcases.h:68:21, please use with caution
"""
    t8_get_number_of_new_prism_cake_cmesh_testcases()

The function t8\\_get\\_new\\_prism\\_cake\\_cmesh\\_testcases()

### Returns
the number of testcases for the new\\_prism\\_cake cmesh.
### Prototype
```c
int t8_get_number_of_new_prism_cake_cmesh_testcases ();
```
"""
function t8_get_number_of_new_prism_cake_cmesh_testcases()
    @ccall libt8.t8_get_number_of_new_prism_cake_cmesh_testcases()::Cint
end

# no prototype is found for this function at t8_cmesh_testcases.h:72:21, please use with caution
"""
    t8_get_number_of_new_disjoint_bricks_cmesh_testcases()

The function t8\\_get\\_new\\_disjoint\\_bricks\\_cmesh\\_testcases()

### Returns
the number of testcases for the new\\_disjoint\\_bricks cmesh.
### Prototype
```c
int t8_get_number_of_new_disjoint_bricks_cmesh_testcases ();
```
"""
function t8_get_number_of_new_disjoint_bricks_cmesh_testcases()
    @ccall libt8.t8_get_number_of_new_disjoint_bricks_cmesh_testcases()::Cint
end

# no prototype is found for this function at t8_cmesh_testcases.h:78:21, please use with caution
"""
    t8_get_number_of_all_testcases()

The function t8\\_get\\_all\\_testcases()

### Returns
the number of testcases for all cmesh types.  We need to know this, because test\\_cmesh\\_copy\\_all needs to know how  many ids to check.
### Prototype
```c
int t8_get_number_of_all_testcases ();
```
"""
function t8_get_number_of_all_testcases()
    @ccall libt8.t8_get_number_of_all_testcases()::Cint
end

"""
    t8_test_create_comm_only_cmesh(cmesh_id)

The function [`t8_test_create_comm_only_cmesh`](@ref)(int cmesh\\_id): The comm is taken from the t8\\_comm\\_list. The switch inside [`t8_test_create_comm_only_cmesh`](@ref)(int cmesh\\_id) chooses the cmesh-type.

### Parameters
* `cmesh_id`:\\[in\\] The cmesh\\_id is used to create a unique cmesh which only takes comm as input.
### Returns
the wanted cmesh with the wanted comm for the given id.
### Prototype
```c
t8_cmesh_t t8_test_create_comm_only_cmesh (int cmesh_id);
```
"""
function t8_test_create_comm_only_cmesh(cmesh_id)
    @ccall libt8.t8_test_create_comm_only_cmesh(cmesh_id::Cint)::t8_cmesh_t
end

"""
    t8_test_create_new_hypercube_cmesh(cmesh_id)

The function [`t8_test_create_new_hypercube_cmesh`](@ref)(int cmesh\\_id): The comm is taken from the t8\\_comm\\_list. It avoids the case (eclass = pyramid & periodic=1) since this is not allowed.

### Parameters
* `cmesh_id`:\\[in\\] The cmesh\\_id is used to create a unique new\\_hypercube cmesh.
### Returns
a new hypercube cmesh with a unique input for every given id.
### Prototype
```c
t8_cmesh_t t8_test_create_new_hypercube_cmesh (int cmesh_id);
```
"""
function t8_test_create_new_hypercube_cmesh(cmesh_id)
    @ccall libt8.t8_test_create_new_hypercube_cmesh(cmesh_id::Cint)::t8_cmesh_t
end

"""
    t8_test_create_new_empty_cmesh(cmesh_id)

The function [`t8_test_create_new_empty_cmesh`](@ref)(int cmesh\\_id): The comm is taken from the t8\\_comm\\_list.

### Parameters
* `cmesh_id`:\\[in\\] The cmesh\\_id is used to create a unique new\\_empty cmesh.
### Returns
a new empty cmesh with a unique input for every given id.
### Prototype
```c
t8_cmesh_t t8_test_create_new_empty_cmesh (int cmesh_id);
```
"""
function t8_test_create_new_empty_cmesh(cmesh_id)
    @ccall libt8.t8_test_create_new_empty_cmesh(cmesh_id::Cint)::t8_cmesh_t
end

"""
    t8_test_create_new_from_class_cmesh(cmesh_id)

The function [`t8_test_create_new_from_class_cmesh`](@ref)(int cmesh\\_id):  The comm is taken from the t8\\_comm\\_list.

### Parameters
* `cmesh_id`:\\[in\\] The cmesh\\_id is used to create a unique new\\_from\\_class cmesh.
### Returns
a new create\\_new\\_from\\_class cmesh with a unique input for every given id.
### Prototype
```c
t8_cmesh_t t8_test_create_new_from_class_cmesh (int cmesh_id);
```
"""
function t8_test_create_new_from_class_cmesh(cmesh_id)
    @ccall libt8.t8_test_create_new_from_class_cmesh(cmesh_id::Cint)::t8_cmesh_t
end

"""
    t8_test_create_new_hypercube_hybrid_cmesh(cmesh_id)

The function [`t8_test_create_new_hypercube_hybrid_cmesh`](@ref)(int cmesh\\_id): The comm is taken from the t8\\_comm\\_list.

### Parameters
* `cmesh_id`:\\[in\\] The cmesh\\_id is used to create a unique new\\_hypercube\\_hybrid cmesh.
### Returns
a new\\_hypercube\\_hybrid cmesh with a unique input for every given id.
### Prototype
```c
t8_cmesh_t t8_test_create_new_hypercube_hybrid_cmesh (int cmesh_id);
```
"""
function t8_test_create_new_hypercube_hybrid_cmesh(cmesh_id)
    @ccall libt8.t8_test_create_new_hypercube_hybrid_cmesh(cmesh_id::Cint)::t8_cmesh_t
end

"""
    t8_test_create_new_periodic_cmesh(cmesh_id)

The function [`t8_test_create_new_periodic_cmesh`](@ref)(int cmesh\\_id): The comm is taken from the t8\\_comm\\_list. The minimal dimension is 1.

### Parameters
* `cmesh_id`:\\[in\\] The cmesh\\_id is used to create a unique new\\_periodic cmesh.
### Returns
a new\\_periodic cmesh with a unique input for every given id.
### Prototype
```c
t8_cmesh_t t8_test_create_new_periodic_cmesh (int cmesh_id);
```
"""
function t8_test_create_new_periodic_cmesh(cmesh_id)
    @ccall libt8.t8_test_create_new_periodic_cmesh(cmesh_id::Cint)::t8_cmesh_t
end

"""
    t8_test_create_new_bigmesh_cmesh(cmesh_id)

The function [`t8_test_create_new_bigmesh_cmesh`](@ref)(int cmesh\\_id):  The comm is taken from the t8\\_comm\\_list. The minimal number of trees is 1.

### Parameters
* `cmesh_id`:\\[in\\] The cmesh\\_id is used to create a unique new\\_bigmesh cmesh.
### Returns
a new\\_bigmesh cmesh with a unique input for every given id.
### Prototype
```c
t8_cmesh_t t8_test_create_new_bigmesh_cmesh (int cmesh_id);
```
"""
function t8_test_create_new_bigmesh_cmesh(cmesh_id)
    @ccall libt8.t8_test_create_new_bigmesh_cmesh(cmesh_id::Cint)::t8_cmesh_t
end

"""
    t8_test_create_new_prism_cake_cmesh(cmesh_id)

The function [`t8_test_create_new_prism_cake_cmesh`](@ref) (int cmesh\\_id): The comm is taken from the t8\\_comm\\_list. The minimal number of trees is 3.

### Parameters
* `cmesh_id`:\\[in\\] The cmesh\\_id is used to create a unique new\\_prism\\_cake cmesh.
### Returns
a new\\_prism\\_cake cmesh with a unique input for every given id.
### Prototype
```c
t8_cmesh_t t8_test_create_new_prism_cake_cmesh (int cmesh_id);
```
"""
function t8_test_create_new_prism_cake_cmesh(cmesh_id)
    @ccall libt8.t8_test_create_new_prism_cake_cmesh(cmesh_id::Cint)::t8_cmesh_t
end

"""
    t8_test_create_cmesh(cmesh_id)

The function [`t8_test_create_cmesh`](@ref) (int cmesh\\_id) combines all t8\\_test\\_create\\_*\\_cmesh functions  so that depending on the range the id is in, we get another cmesh type by calling its  t8\\_test\\_create\\_*\\_cmesh function.

### Parameters
* `cmesh_id`:\\[in\\] The cmesh\\_id is used to create a unique cmesh.
### Returns
A cmesh specified by its cmesh\\_id.
### Prototype
```c
t8_cmesh_t t8_test_create_cmesh (int cmesh_id);
```
"""
function t8_test_create_cmesh(cmesh_id)
    @ccall libt8.t8_test_create_cmesh(cmesh_id::Cint)::t8_cmesh_t
end

"""
    t8_element_array_t

The [`t8_element_array_t`](@ref) is an array to store [`t8_element_t`](@ref) * of a given eclass\\_scheme implementation. It is a wrapper around sc_array_t. Each time, a new element is created by the functions for t8_element_array_t, the eclass function either t8_element_new or t8_element_init is called for the element. Thus, each element in a t8_element_array_t is automatically initialized properly.

| Field  | Note                                                 |
| :----- | :--------------------------------------------------- |
| scheme | An eclass scheme of which elements should be stored  |
| array  | The array in which the elements are stored           |
"""
struct t8_element_array_t
    scheme::Ptr{t8_eclass_scheme_c}
    array::sc_array_t
end

"""
    t8_element_array_new(scheme)

Creates a new array structure with 0 elements.

### Parameters
* `scheme`:\\[in\\] The eclass scheme of which elements should be stored.
### Returns
Return an allocated array of zero length.
### Prototype
```c
t8_element_array_t *t8_element_array_new (t8_eclass_scheme_c *scheme);
```
"""
function t8_element_array_new(scheme)
    @ccall libt8.t8_element_array_new(scheme::Ptr{t8_eclass_scheme_c})::Ptr{t8_element_array_t}
end

"""
    t8_element_array_new_count(scheme, num_elements)

Creates a new array structure with a given length (number of elements) and calls t8_element_new for those elements.

### Parameters
* `scheme`:\\[in\\] The eclass scheme of which elements should be stored.
* `num_elements`:\\[in\\] Initial number of array elements.
### Returns
Return an allocated array with allocated and initialized elements for which t8_element_new was called.
### Prototype
```c
t8_element_array_t *t8_element_array_new_count (t8_eclass_scheme_c *scheme, size_t num_elements);
```
"""
function t8_element_array_new_count(scheme, num_elements)
    @ccall libt8.t8_element_array_new_count(scheme::Ptr{t8_eclass_scheme_c}, num_elements::Csize_t)::Ptr{t8_element_array_t}
end

"""
    t8_element_array_init(element_array, scheme)

Initializes an already allocated (or static) array structure.

### Parameters
* `element_array`:\\[in,out\\] Array structure to be initialized.
* `scheme`:\\[in\\] The eclass scheme of which elements should be stored.
### Prototype
```c
void t8_element_array_init (t8_element_array_t *element_array, t8_eclass_scheme_c *scheme);
```
"""
function t8_element_array_init(element_array, scheme)
    @ccall libt8.t8_element_array_init(element_array::Ptr{t8_element_array_t}, scheme::Ptr{t8_eclass_scheme_c})::Cvoid
end

"""
    t8_element_array_init_size(element_array, scheme, num_elements)

Initializes an already allocated (or static) array structure and allocates a given number of elements and initializes them with t8_element_init.

### Parameters
* `element_array`:\\[in,out\\] Array structure to be initialized.
* `scheme`:\\[in\\] The eclass scheme of which elements should be stored.
* `num_elements`:\\[in\\] Number of initial array elements.
### Prototype
```c
void t8_element_array_init_size (t8_element_array_t *element_array, t8_eclass_scheme_c *scheme, size_t num_elements);
```
"""
function t8_element_array_init_size(element_array, scheme, num_elements)
    @ccall libt8.t8_element_array_init_size(element_array::Ptr{t8_element_array_t}, scheme::Ptr{t8_eclass_scheme_c}, num_elements::Csize_t)::Cvoid
end

"""
    t8_element_array_init_view(view, array, offset, length)

Initializes an already allocated (or static) view from existing t8\\_element\\_array. The array view returned does not require [`t8_element_array_reset`](@ref) (doesn't hurt though).

### Parameters
* `view`:\\[in,out\\] Array structure to be initialized.
* `array`:\\[in\\] The array must not be resized while view is alive.
* `offset`:\\[in\\] The offset of the viewed section in element units. This offset cannot be changed until the view is reset.
* `length`:\\[in\\] The length of the view in element units. The view cannot be resized to exceed this length. It is not necessary to call [`sc_array_reset`](@ref) later.
### Prototype
```c
void t8_element_array_init_view (t8_element_array_t *view, t8_element_array_t *array, size_t offset, size_t length);
```
"""
function t8_element_array_init_view(view, array, offset, length)
    @ccall libt8.t8_element_array_init_view(view::Ptr{t8_element_array_t}, array::Ptr{t8_element_array_t}, offset::Csize_t, length::Csize_t)::Cvoid
end

"""
    t8_element_array_init_data(view, base, scheme, elem_count)

Initializes an already allocated (or static) view from given plain C data (array of [`t8_element_t`](@ref)). The array view returned does not require [`t8_element_array_reset`](@ref) (doesn't hurt though).

### Parameters
* `view`:\\[in,out\\] Array structure to be initialized.
* `base`:\\[in\\] The data must not be moved while view is alive. Must be an array of [`t8_element_t`](@ref) corresponding to *scheme*.
* `scheme`:\\[in\\] The eclass scheme of the elements stored in *base*.
* `elem_count`:\\[in\\] The length of the view in element units. The view cannot be resized to exceed this length. It is not necessary to call [`t8_element_array_reset`](@ref) later.
### Prototype
```c
void t8_element_array_init_data (t8_element_array_t *view, t8_element_t *base, t8_eclass_scheme_c *scheme, size_t elem_count);
```
"""
function t8_element_array_init_data(view, base, scheme, elem_count)
    @ccall libt8.t8_element_array_init_data(view::Ptr{t8_element_array_t}, base::Ptr{t8_element_t}, scheme::Ptr{t8_eclass_scheme_c}, elem_count::Csize_t)::Cvoid
end

"""
    t8_element_array_init_copy(element_array, scheme, data, num_elements)

Initializes an already allocated (or static) array structure and copy an existing array of [`t8_element_t`](@ref) into it.

### Parameters
* `element_array`:\\[in,out\\] Array structure to be initialized.
* `scheme`:\\[in\\] The eclass scheme of which elements should be stored.
* `data`:\\[in\\] An array of [`t8_element_t`](@ref) which will be copied into *element_array*. The elements in *data* must belong to *scheme* and must be properly initialized with either t8_element_new or t8_element_init.
* `num_elements`:\\[in\\] Number of elements in *data* to be copied.
### Prototype
```c
void t8_element_array_init_copy (t8_element_array_t *element_array, t8_eclass_scheme_c *scheme, t8_element_t *data, size_t num_elements);
```
"""
function t8_element_array_init_copy(element_array, scheme, data, num_elements)
    @ccall libt8.t8_element_array_init_copy(element_array::Ptr{t8_element_array_t}, scheme::Ptr{t8_eclass_scheme_c}, data::Ptr{t8_element_t}, num_elements::Csize_t)::Cvoid
end

"""
    t8_element_array_resize(element_array, new_count)

Change the number of elements stored in an element array.

!!! note

    If *new_count* is larger than the number of current elements on *element_array*, then t8_element_init is called for the new elements.

### Parameters
* `element_array`:\\[in,out\\] The element array to be modified.
* `new_count`:\\[in\\] The new element count of the array. If it is zero the effect equals t8_element_array_reset.
### Prototype
```c
void t8_element_array_resize (t8_element_array_t *element_array, size_t new_count);
```
"""
function t8_element_array_resize(element_array, new_count)
    @ccall libt8.t8_element_array_resize(element_array::Ptr{t8_element_array_t}, new_count::Csize_t)::Cvoid
end

"""
    t8_element_array_copy(dest, src)

Copy the contents of an array into another. Both arrays must have the same eclass\\_scheme.

### Parameters
* `dest`:\\[in\\] Array will be resized and get new data.
* `src`:\\[in\\] Array used as source of new data, will not be changed.
### Prototype
```c
void t8_element_array_copy (t8_element_array_t *dest, t8_element_array_t *src);
```
"""
function t8_element_array_copy(dest, src)
    @ccall libt8.t8_element_array_copy(dest::Ptr{t8_element_array_t}, src::Ptr{t8_element_array_t})::Cvoid
end

"""
    t8_element_array_push(element_array)

Enlarge an array by one element.

### Parameters
* `element_array`:\\[in\\] Array structure to be modified.
### Returns
Returns a pointer to a newly added element for which t8_element_init was called.
### Prototype
```c
t8_element_t *t8_element_array_push (t8_element_array_t *element_array);
```
"""
function t8_element_array_push(element_array)
    @ccall libt8.t8_element_array_push(element_array::Ptr{t8_element_array_t})::Ptr{t8_element_t}
end

"""
    t8_element_array_push_count(element_array, count)

Enlarge an array by a number of elements.

### Parameters
* `element_array`:\\[in\\] Array structure to be modified.
* `count`:\\[in\\] The number of elements to add.
### Returns
Returns a pointer to the newly added elements for which t8_element_init was called.
### Prototype
```c
t8_element_t *t8_element_array_push_count (t8_element_array_t *element_array, size_t count);
```
"""
function t8_element_array_push_count(element_array, count)
    @ccall libt8.t8_element_array_push_count(element_array::Ptr{t8_element_array_t}, count::Csize_t)::Ptr{t8_element_t}
end

"""
    t8_element_array_index_locidx(element_array, index)

Return a given element in an array.

### Parameters
* `element_array`:\\[in\\] Array of elements.
* `index`:\\[in\\] The index of an element whithin the array.
### Returns
A pointer to the element stored at position *index* in *element_array*.
### Prototype
```c
t8_element_t *t8_element_array_index_locidx (t8_element_array_t *element_array, t8_locidx_t index);
```
"""
function t8_element_array_index_locidx(element_array, index)
    @ccall libt8.t8_element_array_index_locidx(element_array::Ptr{t8_element_array_t}, index::t8_locidx_t)::Ptr{t8_element_t}
end

"""
    t8_element_array_index_int(element_array, index)

Return a given element in an array.

### Parameters
* `element_array`:\\[in\\] Array of elements.
* `index`:\\[in\\] The index of an element whithin the array.
### Returns
A pointer to the element stored at position *index* in *element_array*.
### Prototype
```c
t8_element_t *t8_element_array_index_int (t8_element_array_t *element_array, int index);
```
"""
function t8_element_array_index_int(element_array, index)
    @ccall libt8.t8_element_array_index_int(element_array::Ptr{t8_element_array_t}, index::Cint)::Ptr{t8_element_t}
end

"""
    t8_element_array_get_scheme(element_array)

Return the eclass scheme associated to a t8\\_element\\_array.

### Parameters
* `element_array`:\\[in\\] Array of elements.
### Returns
The eclass scheme stored at *element_array*.
### Prototype
```c
t8_eclass_scheme_c *t8_element_array_get_scheme (t8_element_array_t *element_array);
```
"""
function t8_element_array_get_scheme(element_array)
    @ccall libt8.t8_element_array_get_scheme(element_array::Ptr{t8_element_array_t})::Ptr{t8_eclass_scheme_c}
end

"""
    t8_element_array_get_count(element_array)

Return the number of elements stored in a [`t8_element_array_t`](@ref).

### Parameters
* `element_array`:\\[in\\] Array structure.
### Returns
The number of elements stored in *element_array*.
### Prototype
```c
size_t t8_element_array_get_count (t8_element_array_t *element_array);
```
"""
function t8_element_array_get_count(element_array)
    @ccall libt8.t8_element_array_get_count(element_array::Ptr{t8_element_array_t})::Csize_t
end

"""
    t8_element_array_get_size(element_array)

Return the data size of elements stored in a [`t8_element_array_t`](@ref).

### Parameters
* `element_array`:\\[in\\] Array structure.
### Returns
The size (in bytes) of a single element in *element_array*.
### Prototype
```c
size_t t8_element_array_get_size (t8_element_array_t *element_array);
```
"""
function t8_element_array_get_size(element_array)
    @ccall libt8.t8_element_array_get_size(element_array::Ptr{t8_element_array_t})::Csize_t
end

"""
    t8_element_array_get_data(element_array)

Return a pointer to the real data array stored in a t8\\_element\\_array.

### Parameters
* `element_array`:\\[in\\] Array structure.
### Returns
A pointer to the stored data. If the number of stored elements is 0, then NULL is returned.
### Prototype
```c
t8_element_t *t8_element_array_get_data (t8_element_array_t *element_array);
```
"""
function t8_element_array_get_data(element_array)
    @ccall libt8.t8_element_array_get_data(element_array::Ptr{t8_element_array_t})::Ptr{t8_element_t}
end

"""
    t8_element_array_get_array(element_array)

Return a pointer to the [`sc_array`](@ref) stored in a t8\\_element\\_array.

### Parameters
* `element_array`:\\[in\\] Array structure.
### Returns
A pointer to the [`sc_array`](@ref) storing the data.
### Prototype
```c
sc_array_t *t8_element_array_get_array (t8_element_array_t *element_array);
```
"""
function t8_element_array_get_array(element_array)
    @ccall libt8.t8_element_array_get_array(element_array::Ptr{t8_element_array_t})::Ptr{sc_array_t}
end

"""
    t8_element_array_reset(element_array)

Sets the array count to zero and frees all elements.

!!! note

    Calling [`t8_element_array_init`](@ref), then any array operations, then [`t8_element_array_reset`](@ref) is memory neutral.

### Parameters
* `element_array`:\\[in,out\\] Array structure to be reset.
### Prototype
```c
void t8_element_array_reset (t8_element_array_t *element_array);
```
"""
function t8_element_array_reset(element_array)
    @ccall libt8.t8_element_array_reset(element_array::Ptr{t8_element_array_t})::Cvoid
end

"""
    t8_element_array_truncate(element_array)

Sets the array count to zero, but does not free elements.

!!! note

    This is intended to allow an t8\\_element\\_array to be used as a reusable buffer, where the "high water mark" of the buffer is preserved, so that O(log (max n)) reallocs occur over the life of the buffer.

### Parameters
* `element_array`:\\[in,out\\] Element array structure to be truncated.
### Prototype
```c
void t8_element_array_truncate (t8_element_array_t *element_array);
```
"""
function t8_element_array_truncate(element_array)
    @ccall libt8.t8_element_array_truncate(element_array::Ptr{t8_element_array_t})::Cvoid
end

"""
    t8_shmem_init(comm)

### Prototype
```c
void t8_shmem_init (sc_MPI_Comm comm);
```
"""
function t8_shmem_init(comm)
    @ccall libt8.t8_shmem_init(comm::MPI_Comm)::Cvoid
end

"""
    t8_shmem_finalize(comm)

### Prototype
```c
void t8_shmem_finalize (sc_MPI_Comm comm);
```
"""
function t8_shmem_finalize(comm)
    @ccall libt8.t8_shmem_finalize(comm::MPI_Comm)::Cvoid
end

"""
    t8_shmem_set_type(comm, type)

### Prototype
```c
void t8_shmem_set_type (sc_MPI_Comm comm, sc_shmem_type_t type);
```
"""
function t8_shmem_set_type(comm, type)
    @ccall libt8.t8_shmem_set_type(comm::MPI_Comm, type::sc_shmem_type_t)::Cvoid
end

"""
    t8_shmem_array_init(parray, elem_size, elem_count, comm)

### Prototype
```c
void t8_shmem_array_init (t8_shmem_array_t *parray, size_t elem_size, size_t elem_count, sc_MPI_Comm comm);
```
"""
function t8_shmem_array_init(parray, elem_size, elem_count, comm)
    @ccall libt8.t8_shmem_array_init(parray::Ptr{t8_shmem_array_t}, elem_size::Csize_t, elem_count::Csize_t, comm::MPI_Comm)::Cvoid
end

"""
    t8_shmem_array_start_writing(array)

Enable writing mode for a shmem array. Only some processes may be allowed to write into the array, which is indicated by the return value being non-zero.

!!! note

    This function is MPI collective.

### Parameters
* `array`:\\[in,out\\] Initialized array. Writing will be enabled on certain processes.
### Returns
True if the calling process can write into the array.
### Prototype
```c
int t8_shmem_array_start_writing (t8_shmem_array_t array);
```
"""
function t8_shmem_array_start_writing(array)
    @ccall libt8.t8_shmem_array_start_writing(array::t8_shmem_array_t)::Cint
end

"""
    t8_shmem_array_end_writing(array)

Disable writing mode for a shmem array.

!!! note

    This function is MPI collective.

### Parameters
* `array`:\\[in,out\\] Initialized with writing mode enabled.
### See also
[`t8_shmem_array_start_writing`](@ref).

### Prototype
```c
void t8_shmem_array_end_writing (t8_shmem_array_t array);
```
"""
function t8_shmem_array_end_writing(array)
    @ccall libt8.t8_shmem_array_end_writing(array::t8_shmem_array_t)::Cvoid
end

"""
    t8_shmem_array_set_gloidx(array, index, value)

Set an entry of a t8\\_shmem array that is used to store [`t8_gloidx_t`](@ref). The array must have writing mode enabled t8_shmem_array_start_writing.

### Parameters
* `array`:\\[in,out\\] The array to be mofified.
* `index`:\\[in\\] The array entry to be modified.
* `value`:\\[in\\] The new value to be set.
### Prototype
```c
void t8_shmem_array_set_gloidx (t8_shmem_array_t array, int index, t8_gloidx_t value);
```
"""
function t8_shmem_array_set_gloidx(array, index, value)
    @ccall libt8.t8_shmem_array_set_gloidx(array::t8_shmem_array_t, index::Cint, value::t8_gloidx_t)::Cvoid
end

"""
    t8_shmem_array_copy(dest, source)

Copy the contents of one t8\\_shmem array into another.

!!! note

    *dest* must be initialized and match in element size and element count to *source*.

!!! note

    *dest* must have writing mode disabled.

### Parameters
* `dest`:\\[in,out\\] The array in which *source* should be copied.
* `source`:\\[in\\] The array to copy.
### Prototype
```c
void t8_shmem_array_copy (t8_shmem_array_t dest, t8_shmem_array_t source);
```
"""
function t8_shmem_array_copy(dest, source)
    @ccall libt8.t8_shmem_array_copy(dest::t8_shmem_array_t, source::t8_shmem_array_t)::Cvoid
end

"""
    t8_shmem_array_allgather(sendbuf, sendcount, sendtype, recvarray, recvcount, recvtype)

### Prototype
```c
void t8_shmem_array_allgather (const void *sendbuf, int sendcount, sc_MPI_Datatype sendtype, t8_shmem_array_t recvarray, int recvcount, sc_MPI_Datatype recvtype);
```
"""
function t8_shmem_array_allgather(sendbuf, sendcount, sendtype, recvarray, recvcount, recvtype)
    @ccall libt8.t8_shmem_array_allgather(sendbuf::Ptr{Cvoid}, sendcount::Cint, sendtype::Cint, recvarray::t8_shmem_array_t, recvcount::Cint, recvtype::Cint)::Cvoid
end

"""
    t8_shmem_array_get_comm(array)

### Prototype
```c
sc_MPI_Comm t8_shmem_array_get_comm (t8_shmem_array_t array);
```
"""
function t8_shmem_array_get_comm(array)
    @ccall libt8.t8_shmem_array_get_comm(array::t8_shmem_array_t)::Cint
end

"""
    t8_shmem_array_get_elem_size(array)

Get the element size of a [`t8_shmem_array`](@ref)

### Parameters
* `array`:\\[in\\] The array.
### Returns
The element size of *array*'s elements.
### Prototype
```c
size_t t8_shmem_array_get_elem_size (t8_shmem_array_t array);
```
"""
function t8_shmem_array_get_elem_size(array)
    @ccall libt8.t8_shmem_array_get_elem_size(array::t8_shmem_array_t)::Csize_t
end

"""
    t8_shmem_array_get_elem_count(array)

Get the number of elements of a [`t8_shmem_array`](@ref)

### Parameters
* `array`:\\[in\\] The array.
### Returns
The number of elements in *array*.
### Prototype
```c
size_t t8_shmem_array_get_elem_count (t8_shmem_array_t array);
```
"""
function t8_shmem_array_get_elem_count(array)
    @ccall libt8.t8_shmem_array_get_elem_count(array::t8_shmem_array_t)::Csize_t
end

"""
    t8_shmem_array_get_gloidx_array(array)

Return a read-only pointer to the data of a shared memory array interpreted as an [`t8_gloidx_t`](@ref) array.

!!! note

    Writing mode must be disabled for *array*.

### Parameters
* `array`:\\[in\\] The [`t8_shmem_array`](@ref)
### Returns
The data of *array* as [`t8_gloidx_t`](@ref) pointer.
### Prototype
```c
const t8_gloidx_t *t8_shmem_array_get_gloidx_array (t8_shmem_array_t array);
```
"""
function t8_shmem_array_get_gloidx_array(array)
    @ccall libt8.t8_shmem_array_get_gloidx_array(array::t8_shmem_array_t)::Ptr{t8_gloidx_t}
end

"""
    t8_shmem_array_get_gloidx_array_for_writing(array)

Return a pointer to the data of a shared memory array interpreted as an [`t8_gloidx_t`](@ref) array. The array must have writing enabled t8_shmem_array_start_writing and you should not write into the memory after t8_shmem_array_end_writing was called.

### Parameters
* `array`:\\[in\\] The [`t8_shmem_array`](@ref)
### Returns
The data of *array* as [`t8_gloidx_t`](@ref) pointer.
### Prototype
```c
t8_gloidx_t *t8_shmem_array_get_gloidx_array_for_writing (t8_shmem_array_t array);
```
"""
function t8_shmem_array_get_gloidx_array_for_writing(array)
    @ccall libt8.t8_shmem_array_get_gloidx_array_for_writing(array::t8_shmem_array_t)::Ptr{t8_gloidx_t}
end

"""
    t8_shmem_array_get_gloidx(array, index)

Return an entry of a shared memory array that stores [`t8_gloidx_t`](@ref).

!!! note

    Writing mode must be disabled for *array*.

### Parameters
* `array`:\\[in\\] The [`t8_shmem_array`](@ref)
* `index`:\\[in\\] The index of the entry to be queried.
### Returns
The *index*-th entry of *array* as [`t8_gloidx_t`](@ref).
### Prototype
```c
t8_gloidx_t t8_shmem_array_get_gloidx (t8_shmem_array_t array, int index);
```
"""
function t8_shmem_array_get_gloidx(array, index)
    @ccall libt8.t8_shmem_array_get_gloidx(array::t8_shmem_array_t, index::Cint)::t8_gloidx_t
end

"""
    t8_shmem_array_get_array(array)

Return a pointer to the data array of a [`t8_shmem_array`](@ref).

!!! note

    Writing mode must be disabled for *array*.

### Parameters
* `array`:\\[in\\] The [`t8_shmem_array`](@ref).
### Returns
A pointer to the data array of *array*.
### Prototype
```c
const void *t8_shmem_array_get_array (t8_shmem_array_t array);
```
"""
function t8_shmem_array_get_array(array)
    @ccall libt8.t8_shmem_array_get_array(array::t8_shmem_array_t)::Ptr{Cvoid}
end

"""
    t8_shmem_array_index(array, index)

Return a read-only pointer to an element in a [`t8_shmem_array`](@ref).

!!! note

    You should not modify the value.

!!! note

    Writing mode must be disabled for *array*.

### Parameters
* `array`:\\[in\\] The [`t8_shmem_array`](@ref).
* `index`:\\[in\\] The index of an element.
### Returns
A pointer to the element at *index* in *array*.
### Prototype
```c
const void *t8_shmem_array_index (t8_shmem_array_t array, size_t index);
```
"""
function t8_shmem_array_index(array, index)
    @ccall libt8.t8_shmem_array_index(array::t8_shmem_array_t, index::Csize_t)::Ptr{Cvoid}
end

"""
    t8_shmem_array_index_for_writing(array, index)

Return a pointer to an element in a [`t8_shmem_array`](@ref) in writing mode.

!!! note

    You can modify the value before the next call to t8_shmem_array_end_writing.

!!! note

    Writing mode must be enabled for *array*.

### Parameters
* `array`:\\[in\\] The [`t8_shmem_array`](@ref).
* `index`:\\[in\\] The index of an element.
### Returns
A pointer to the element at *index* in *array*.
### Prototype
```c
void *t8_shmem_array_index_for_writing (t8_shmem_array_t array, size_t index);
```
"""
function t8_shmem_array_index_for_writing(array, index)
    @ccall libt8.t8_shmem_array_index_for_writing(array::t8_shmem_array_t, index::Csize_t)::Ptr{Cvoid}
end

"""
    t8_shmem_array_is_equal(array_a, array_b)

### Prototype
```c
int t8_shmem_array_is_equal (t8_shmem_array_t array_a, t8_shmem_array_t array_b);
```
"""
function t8_shmem_array_is_equal(array_a, array_b)
    @ccall libt8.t8_shmem_array_is_equal(array_a::t8_shmem_array_t, array_b::t8_shmem_array_t)::Cint
end

"""
    t8_shmem_array_destroy(parray)

Free all memory associated with a [`t8_shmem_array`](@ref).

### Parameters
* `parray`:\\[in,out\\] On input a pointer to a valid [`t8_shmem_array`](@ref). This array is freed and *parray* is set to NULL on return.
### Prototype
```c
void t8_shmem_array_destroy (t8_shmem_array_t *parray);
```
"""
function t8_shmem_array_destroy(parray)
    @ccall libt8.t8_shmem_array_destroy(parray::Ptr{t8_shmem_array_t})::Cvoid
end

"""
    t8_forest_adapt(forest)

### Prototype
```c
void t8_forest_adapt (t8_forest_t forest);
```
"""
function t8_forest_adapt(forest)
    @ccall libt8.t8_forest_adapt(forest::t8_forest_t)::Cvoid
end

mutable struct t8_tree end

const t8_tree_t = Ptr{t8_tree}

"""
    t8_ghost_type_t

This type controls, which neighbors count as ghost elements. Currently, we support face-neighbors. Vertex and edge neighbors will eventually be added.

| Enumerator         | Note                                                   |
| :----------------- | :----------------------------------------------------- |
| T8\\_GHOST\\_NONE  | Do not create ghost layer.                             |
| T8\\_GHOST\\_FACES | Consider all face (codimension 1) neighbors.           |
| T8\\_GHOST\\_EDGES | Consider all edge (codimension 2) and face neighbors.  |
"""
@cenum t8_ghost_type_t::UInt32 begin
    T8_GHOST_NONE = 0
    T8_GHOST_FACES = 1
    T8_GHOST_EDGES = 2
    T8_GHOST_VERTICES = 3
end

# typedef void ( * t8_generic_function_pointer ) ( void )
"""
This typedef is needed as a helper construct to  properly be able to define a function that returns a pointer to a void fun(void) function.

### See also
[`t8_forest_get_user_function`](@ref).
"""
const t8_generic_function_pointer = Ptr{Cvoid}

# typedef void ( * t8_forest_replace_t ) ( t8_forest_t forest_old , t8_forest_t forest_new , t8_locidx_t which_tree , t8_eclass_scheme_c * ts , int refine , int num_outgoing , t8_locidx_t first_outgoing , int num_incoming , t8_locidx_t first_incoming )
"""
Callback function prototype to replace one set of elements with another.

This is used by the replace routine which can be called after adapt, when the elements of an existing, valid forest are changed. The callback allows the user to make changes to the elements of the new forest that are either refined, coarsened or the same as elements in the old forest.

If an element is being refined, *refine* and *num_outgoing* will be 1 and  *num_incoming* will be the number of children. If a family is being coarsened, *refine* will be -1, *num_outgoing* will be  the number of family members and *num_incoming* will be 1. Else *refine* will  be 0 and *num_outgoing* and *num_incoming* will both be 1.

### Parameters
* `forest_old`:\\[in\\] The forest that is adapted
* `forest_new`:\\[in\\] The forest that is newly constructed from *forest_old*
* `which_tree`:\\[in\\] The local tree containing *outgoing* and *incoming*
* `ts`:\\[in\\] The eclass scheme of the tree
* `refine`:\\[in\\] -1 if family in *forest_old* got coarsened, 0 if element has not been touched, 1 if element got refined.  See return of [`t8_forest_adapt_t`](@ref).
* `num_outgoing`:\\[in\\] The number of outgoing elements.
* `first_outgoing`:\\[in\\] The tree local index of the first outgoing element. 0 <= first\\_outgoing < which\\_tree->num\\_elements
* `num_incoming`:\\[in\\] The number of incoming elements.
* `first_incoming`:\\[in\\] The tree local index of the first incoming element. 0 <= first\\_incom < new\\_which\\_tree->num\\_elements
### See also
[`t8_forest_iterate_replace`](@ref)
"""
const t8_forest_replace_t = Ptr{Cvoid}

# typedef int ( * t8_forest_adapt_t ) ( t8_forest_t forest , t8_forest_t forest_from , t8_locidx_t which_tree , t8_locidx_t lelement_id , t8_eclass_scheme_c * ts , const int is_family , const int num_elements , t8_element_t * elements [ ] )
"""
Callback function prototype to decide for refining and coarsening. If *is_family* equals 1, the first *num_elements* in *elements* form a family and we decide whether this family should be coarsened or only the first element should be refined. Otherwise *is_family* must equal zero and we consider the first entry of the element array for refinement.  Entries of the element array beyond the first *num_elements* are undefined.

### Parameters
* `forest`:\\[in\\] the forest to which the new elements belong
* `forest_from`:\\[in\\] the forest that is adapted.
* `which_tree`:\\[in\\] the local tree containing *elements*
* `lelement_id`:\\[in\\] the local element id in *forest_old* in the tree of the current element
* `ts`:\\[in\\] the eclass scheme of the tree
* `is_family`:\\[in\\] if 1, the first *num_elements* entries in *elements* form a family. If 0, they do not.
* `num_elements`:\\[in\\] the number of entries in *elements* that are defined
* `elements`:\\[in\\] Pointers to a family or, if *is_family* is zero, pointer to one element.
### Returns
greater zero if the first entry in *elements* should be refined, smaller zero if the family *elements* shall be coarsened, zero else.
"""
const t8_forest_adapt_t = Ptr{Cvoid}

"""
    t8_forest_init(pforest)

Create a new forest with reference count one. This forest needs to be specialized with the t8\\_forest\\_set\\_* calls. Currently it is manatory to either call the functions t8_forest_set_mpicomm, t8_forest_set_cmesh, and t8_forest_set_scheme, or to call one of t8_forest_set_copy, t8_forest_set_adapt, or t8_forest_set_partition. It is illegal to mix these calls, or to call more than one of the three latter functions Then it needs to be set up with t8_forest_commit.

### Parameters
* `pforest`:\\[in,out\\] On input, this pointer must be non-NULL. On return, this pointer set to the new forest.
### Prototype
```c
void t8_forest_init (t8_forest_t *pforest);
```
"""
function t8_forest_init(pforest)
    @ccall libt8.t8_forest_init(pforest::Ptr{t8_forest_t})::Cvoid
end

"""
    t8_forest_is_initialized(forest)

Check whether a forest is not NULL, initialized and not committed. In addition, it asserts that the forest is consistent as much as possible.

### Parameters
* `forest`:\\[in\\] This forest is examined. May be NULL.
### Returns
True if forest is not NULL, t8_forest_init has been called on it, but not t8_forest_commit. False otherwise.
### Prototype
```c
int t8_forest_is_initialized (t8_forest_t forest);
```
"""
function t8_forest_is_initialized(forest)
    @ccall libt8.t8_forest_is_initialized(forest::t8_forest_t)::Cint
end

"""
    t8_forest_is_committed(forest)

Check whether a forest is not NULL, initialized and committed. In addition, it asserts that the forest is consistent as much as possible.

### Parameters
* `forest`:\\[in\\] This forest is examined. May be NULL.
### Returns
True if forest is not NULL and t8_forest_init has been called on it as well as t8_forest_commit. False otherwise.
### Prototype
```c
int t8_forest_is_committed (t8_forest_t forest);
```
"""
function t8_forest_is_committed(forest)
    @ccall libt8.t8_forest_is_committed(forest::t8_forest_t)::Cint
end

"""
    t8_forest_is_equal(forest_a, forest_b)

Check whether two committed forests have the same local elements.

!!! note

    This function is not collective. It only returns the state on the current rank.

### Parameters
* `forest_a`:\\[in\\] The first forest.
* `forest_b`:\\[in\\] The second forest.
### Returns
True if *forest_a* and *forest_b* do have the same number of local trees and each local tree has the same elements, that is t8_element_compare returns false for each pair of elements of *forest_a* and *forest_b*.
### Prototype
```c
int t8_forest_is_equal (t8_forest_t forest_a, t8_forest_t forest_b);
```
"""
function t8_forest_is_equal(forest_a, forest_b)
    @ccall libt8.t8_forest_is_equal(forest_a::t8_forest_t, forest_b::t8_forest_t)::Cint
end

"""
    t8_forest_set_cmesh(forest, cmesh, comm)

### Prototype
```c
void t8_forest_set_cmesh (t8_forest_t forest, t8_cmesh_t cmesh, sc_MPI_Comm comm);
```
"""
function t8_forest_set_cmesh(forest, cmesh, comm)
    @ccall libt8.t8_forest_set_cmesh(forest::t8_forest_t, cmesh::t8_cmesh_t, comm::MPI_Comm)::Cvoid
end

"""
    t8_forest_set_scheme(forest, scheme)

Set the element scheme associated to a forest. By default, the forest takes ownership of the scheme such that it will be destroyed when the forest is destroyed. To keep ownership of the scheme, call t8_scheme_ref before passing it to t8_forest_set_scheme. This means that it is ILLEGAL to continue using scheme or dereferencing it UNLESS it is referenced directly before passing it into this function.

### Parameters
* `forest`:\\[in,out\\] The forest whose scheme variable will be set.
* `scheme`:\\[in\\] The scheme to be set. We take ownership. This can be prevented by referencing **scheme**.
### Prototype
```c
void t8_forest_set_scheme (t8_forest_t forest, t8_scheme_cxx_t *scheme);
```
"""
function t8_forest_set_scheme(forest, scheme)
    @ccall libt8.t8_forest_set_scheme(forest::t8_forest_t, scheme::Ptr{t8_scheme_cxx_t})::Cvoid
end

"""
    t8_forest_set_level(forest, level)

Set the initial refinement level to be used when **forest** is commited.

!!! note

    This setting cannot be combined with any of the derived forest methods (t8_forest_set_copy, t8_forest_set_adapt, t8_forest_set_partition, and t8_forest_set_balance) and overwrites any of these settings. If this function is used, then the forest is created from scratch as a uniform refinement of the specified cmesh (t8_forest_set_cmesh, t8_forest_set_scheme).

### Parameters
* `forest`:\\[in,out\\] The forest whose level will be set.
* `level`:\\[in\\] The initial refinement level of **forest**, when it is commited.
### Prototype
```c
void t8_forest_set_level (t8_forest_t forest, int level);
```
"""
function t8_forest_set_level(forest, level)
    @ccall libt8.t8_forest_set_level(forest::t8_forest_t, level::Cint)::Cvoid
end

"""
    t8_forest_set_copy(forest, from)

Set a forest as source for copying on commiting. By default, the forest takes ownership of the source **from** such that it will be destroyed on calling t8_forest_commit. To keep ownership of **from**, call t8_forest_ref before passing it into this function. This means that it is ILLEGAL to continue using **from** or dereferencing it UNLESS it is referenced directly before passing it into this function.

!!! note

    This setting cannot be combined with t8_forest_set_adapt, t8_forest_set_partition, or t8_forest_set_balance and overwrites these settings.

### Parameters
* `forest`:\\[in,out\\] The forest.
* `from`:\\[in\\] A second forest from which *forest* will be copied in t8_forest_commit.
### Prototype
```c
void t8_forest_set_copy (t8_forest_t forest, const t8_forest_t from);
```
"""
function t8_forest_set_copy(forest, from)
    @ccall libt8.t8_forest_set_copy(forest::t8_forest_t, from::t8_forest_t)::Cvoid
end

"""
    t8_forest_set_adapt(forest, set_from, adapt_fn, recursive)

Set a source forest with an adapt function to be adapted on commiting. By default, the forest takes ownership of the source **set_from** such that it will be destroyed on calling t8_forest_commit. To keep ownership of **set_from**, call t8_forest_ref before passing it into this function. This means that it is ILLEGAL to continue using **set_from** or dereferencing it UNLESS it is referenced directly before passing it into this function.

!!! note

    This setting can be combined with t8_forest_set_partition and t8_forest_set_balance. The order in which these operations are executed is always 1) Adapt 2) Balance 3) Partition

!!! note

    This setting may not be combined with t8_forest_set_copy and overwrites this setting.

### Parameters
* `forest`:\\[in,out\\] The forest
* `set_from`:\\[in\\] The source forest from which **forest** will be adapted. We take ownership. This can be prevented by referencing **set_from**. If NULL, a previously (or later) set forest will be taken (t8_forest_set_partition, t8_forest_set_balance).
* `adapt_fn`:\\[in\\] The adapt function used on commiting.
* `recursive`:\\[in\\] A flag specifying whether adaptation is to be done recursively or not. If the value is zero, adaptation is not recursive and it is recursive otherwise.
### Prototype
```c
void t8_forest_set_adapt (t8_forest_t forest, const t8_forest_t set_from, t8_forest_adapt_t adapt_fn, int recursive);
```
"""
function t8_forest_set_adapt(forest, set_from, adapt_fn, recursive)
    @ccall libt8.t8_forest_set_adapt(forest::t8_forest_t, set_from::t8_forest_t, adapt_fn::t8_forest_adapt_t, recursive::Cint)::Cvoid
end

"""
    t8_forest_set_user_data(forest, data)

Set the user data of a forest. This can i.e. be used to pass user defined arguments to the adapt routine.

### Parameters
* `forest`:\\[in,out\\] The forest
* `data`:\\[in\\] A pointer to user data. t8code will never touch the data. The forest does not need be committed before calling this function.
### See also
[`t8_forest_get_user_data`](@ref)

### Prototype
```c
void t8_forest_set_user_data (t8_forest_t forest, void *data);
```
"""
function t8_forest_set_user_data(forest, data)
    @ccall libt8.t8_forest_set_user_data(forest::t8_forest_t, data::Ptr{Cvoid})::Cvoid
end

"""
    t8_forest_get_user_data(forest)

Return the user data pointer associated with a forest.

### Parameters
* `forest`:\\[in\\] The forest.
### Returns
The user data pointer of *forest*. The forest does not need be committed before calling this function.
### See also
[`t8_forest_set_user_data`](@ref)

### Prototype
```c
void *t8_forest_get_user_data (t8_forest_t forest);
```
"""
function t8_forest_get_user_data(forest)
    @ccall libt8.t8_forest_get_user_data(forest::t8_forest_t)::Ptr{Cvoid}
end

"""
    t8_forest_set_user_function(forest, functrion)

Set the user function pointer of a forest. This can i.e. be used to pass user defined functions to the adapt routine.

!!! note

    *function* can be an arbitrary function with return value and parameters of your choice. When accessing it with t8_forest_get_user_function you should cast it into the proper type.

### Parameters
* `forest`:\\[in,out\\] The forest
* `function`:\\[in\\] A pointer to a user defined function. t8code will never touch the function. The forest does not need be committed before calling this function.
### See also
[`t8_forest_get_user_function`](@ref)

### Prototype
```c
void t8_forest_set_user_function (t8_forest_t forest, t8_generic_function_pointer functrion);
```
"""
function t8_forest_set_user_function(forest, functrion)
    @ccall libt8.t8_forest_set_user_function(forest::t8_forest_t, functrion::t8_generic_function_pointer)::Cvoid
end

"""
    t8_forest_get_user_function(forest)

Return the user function pointer associated with a forest.

### Parameters
* `forest`:\\[in\\] The forest.
### Returns
The user function pointer of *forest*. The forest does not need be committed before calling this function.
### See also
[`t8_forest_set_user_function`](@ref)

### Prototype
```c
t8_generic_function_pointer t8_forest_get_user_function (t8_forest_t forest);
```
"""
function t8_forest_get_user_function(forest)
    @ccall libt8.t8_forest_get_user_function(forest::t8_forest_t)::t8_generic_function_pointer
end

"""
    t8_forest_set_partition(forest, set_from, set_for_coarsening)

Set a source forest to be partitioned during commit. The partitioning is done according to the SFC and each rank is assinged the same (maybe +1) number of elements.

!!! note

    This setting can be combined with t8_forest_set_adapt and t8_forest_set_balance. The order in which these operations are executed is always 1) Adapt 2) Balance 3) Partition If t8_forest_set_balance is called with the *no_repartition* parameter set as false, it is not neccessary to call t8_forest_set_partition additionally.

!!! note

    This setting may not be combined with t8_forest_set_copy and overwrites this setting.

### Parameters
* `forest`:\\[in,out\\] The forest.
* `set_from`:\\[in\\] A second forest that should be partitioned. We take ownership. This can be prevented by referencing **set_from**. If NULL, a previously (or later) set forest will be taken (t8_forest_set_adapt, t8_forest_set_balance).
* `set_for_coarsening`:\\[in\\] CURRENTLY DISABLED. If true, then the partitions are choose such that coarsening an element once is a process local operation.
### Prototype
```c
void t8_forest_set_partition (t8_forest_t forest, const t8_forest_t set_from, int set_for_coarsening);
```
"""
function t8_forest_set_partition(forest, set_from, set_for_coarsening)
    @ccall libt8.t8_forest_set_partition(forest::t8_forest_t, set_from::t8_forest_t, set_for_coarsening::Cint)::Cvoid
end

"""
    t8_forest_set_balance(forest, set_from, no_repartition)

Set a source forest to be balanced during commit. A forest is said to be balanced if each element has face neighbors of level at most +1 or -1 of the element's level.

!!! note

    This setting can be combined with t8_forest_set_adapt and t8_forest_set_balance. The order in which these operations are executed is always 1) Adapt 2) Balance 3) Partition.

!!! note

    This setting may not be combined with t8_forest_set_copy and overwrites this setting.

### Parameters
* `forest`:\\[in,out\\] The forest.
* `set_from`:\\[in\\] A second forest that should be balanced. We take ownership. This can be prevented by referencing **set_from**. If NULL, a previously (or later) set forest will be taken (t8_forest_set_adapt, t8_forest_set_partition)
* `no_repartition`:\\[in\\] Balance constructs several intermediate forest that are refined from each other. In order to maintain a balanced load these forest are repartitioned in each round and the resulting forest is load-balanced per default. If this behaviour is not desired, *no_repartition* should be set to true. If *no_repartition* is false, an additional call of t8_forest_set_partition is not neccessary.
### Prototype
```c
void t8_forest_set_balance (t8_forest_t forest, const t8_forest_t set_from, int no_repartition);
```
"""
function t8_forest_set_balance(forest, set_from, no_repartition)
    @ccall libt8.t8_forest_set_balance(forest::t8_forest_t, set_from::t8_forest_t, no_repartition::Cint)::Cvoid
end

"""
    t8_forest_set_ghost(forest, do_ghost, ghost_type)

Enable or disable the creation of a layer of ghost elements. On default no ghosts are created.

### Parameters
* `forest`:\\[in\\] The forest.
* `do_ghost`:\\[in\\] If non-zero a ghost layer will be created.
* `ghost_type`:\\[in\\] Controls which neighbors count as ghost elements, currently only T8\\_GHOST\\_FACES is supported. This value is ignored if *do_ghost* = 0.
### Prototype
```c
void t8_forest_set_ghost (t8_forest_t forest, int do_ghost, t8_ghost_type_t ghost_type);
```
"""
function t8_forest_set_ghost(forest, do_ghost, ghost_type)
    @ccall libt8.t8_forest_set_ghost(forest::t8_forest_t, do_ghost::Cint, ghost_type::t8_ghost_type_t)::Cvoid
end

"""
    t8_forest_set_ghost_ext(forest, do_ghost, ghost_type, ghost_version)

Like t8_forest_set_ghost but with the additional options to change the ghost algorithm. This is used for debugging and timing the algorithm. An application should almost always use t8_forest_set_ghost.

### Parameters
* `ghost_version`:\\[in\\] If 1, the iterative ghost algorithm for balanced forests is used. If 2, the iterativ algorithm for unbalanced forests. If 3, the top-down search algorithm for unbalanced forests.
### See also
[`t8_forest_set_ghost`](@ref)

### Prototype
```c
void t8_forest_set_ghost_ext (t8_forest_t forest, int do_ghost, t8_ghost_type_t ghost_type, int ghost_version);
```
"""
function t8_forest_set_ghost_ext(forest, do_ghost, ghost_type, ghost_version)
    @ccall libt8.t8_forest_set_ghost_ext(forest::t8_forest_t, do_ghost::Cint, ghost_type::t8_ghost_type_t, ghost_version::Cint)::Cvoid
end

"""
    t8_forest_set_load(forest, filename)

### Prototype
```c
void t8_forest_set_load (t8_forest_t forest, const char *filename);
```
"""
function t8_forest_set_load(forest, filename)
    @ccall libt8.t8_forest_set_load(forest::t8_forest_t, filename::Cstring)::Cvoid
end

"""
    t8_forest_comm_global_num_elements(forest)

Compute the global number of elements in a forest as the sum of the local element counts.

### Parameters
* `forest`:\\[in\\] The forest.
### Prototype
```c
void t8_forest_comm_global_num_elements (t8_forest_t forest);
```
"""
function t8_forest_comm_global_num_elements(forest)
    @ccall libt8.t8_forest_comm_global_num_elements(forest::t8_forest_t)::Cvoid
end

"""
    t8_forest_commit(forest)

After allocating and adding properties to a forest, commit the changes. This call sets up the internal state of the forest.

### Parameters
* `forest`:\\[in,out\\] Must be created with t8_forest_init and specialized with t8\\_forest\\_set\\_* calls first.
### Prototype
```c
void t8_forest_commit (t8_forest_t forest);
```
"""
function t8_forest_commit(forest)
    @ccall libt8.t8_forest_commit(forest::t8_forest_t)::Cvoid
end

"""
    t8_forest_get_maxlevel(forest)

Return the maximum allowed refinement level for any element in a forest.

### Parameters
* `forest`:\\[in\\] A forest.
### Returns
The maximum level of refinement that is allowed for an element in this forest. It is guarenteed that any tree in *forest* can be refined this many times and it is not allowed to refine further. *forest* must be committed before calling this function. For forest with a single element class (non-hybrid) maxlevel is the maximum refinement level of this element class, whilst for hybrid forests the maxlevel is the minimum of all maxlevels of the element classes in this forest.
### Prototype
```c
int t8_forest_get_maxlevel (t8_forest_t forest);
```
"""
function t8_forest_get_maxlevel(forest)
    @ccall libt8.t8_forest_get_maxlevel(forest::t8_forest_t)::Cint
end

"""
    t8_forest_get_local_num_elements(forest)

Return the number of process local elements in the forest.

### Parameters
* `forest`:\\[in\\] A forest.
### Returns
The number of elements on this process in *forest*. *forest* must be committed before calling this function.
### Prototype
```c
t8_locidx_t t8_forest_get_local_num_elements (t8_forest_t forest);
```
"""
function t8_forest_get_local_num_elements(forest)
    @ccall libt8.t8_forest_get_local_num_elements(forest::t8_forest_t)::t8_locidx_t
end

"""
    t8_forest_get_global_num_elements(forest)

Return the number of global elements in the forest.

### Parameters
* `forest`:\\[in\\] A forest.
### Returns
The number of elements (summed over all processes) in *forest*. *forest* must be committed before calling this function.
### Prototype
```c
t8_gloidx_t t8_forest_get_global_num_elements (t8_forest_t forest);
```
"""
function t8_forest_get_global_num_elements(forest)
    @ccall libt8.t8_forest_get_global_num_elements(forest::t8_forest_t)::t8_gloidx_t
end

"""
    t8_forest_get_num_ghosts(forest)

Return the number of ghost elements of a forest.

### Parameters
* `forest`:\\[in\\] The forest.
### Returns
The number of ghost elements stored in the ghost structure of *forest*. 0 if no ghosts were constructed.
### See also
[`t8_forest_set_ghost`](@ref) *forest* must be committed before calling this function.

### Prototype
```c
t8_locidx_t t8_forest_get_num_ghosts (t8_forest_t forest);
```
"""
function t8_forest_get_num_ghosts(forest)
    @ccall libt8.t8_forest_get_num_ghosts(forest::t8_forest_t)::t8_locidx_t
end

"""
    t8_forest_get_eclass(forest, ltreeid)

Return the element class of a forest local tree.

### Parameters
* `forest`:\\[in\\] The forest.
* `ltreeid`:\\[in\\] The local id of a tree in *forest*.
### Returns
The element class of the tree *ltreeid*. *forest* must be committed before calling this function.
### Prototype
```c
t8_eclass_t t8_forest_get_eclass (t8_forest_t forest, t8_locidx_t ltreeid);
```
"""
function t8_forest_get_eclass(forest, ltreeid)
    @ccall libt8.t8_forest_get_eclass(forest::t8_forest_t, ltreeid::t8_locidx_t)::t8_eclass_t
end

"""
    t8_forest_get_local_id(forest, gtreeid)

Given a global tree id compute the forest local id of this tree. If the tree is a local tree, then the local id is between 0 and the number of local trees. If the tree is not a local tree, a negative number is returned.

### Parameters
* `forest`:\\[in\\] The forest.
* `gtreeid`:\\[in\\] The global id of a tree.
### Returns
The tree's local id in *forest*, if it is a local tree. A negative number if not.
### See also
https://github.com/DLR-AMR/t8code/wiki/Tree-indexing for more details about tree indexing.

### Prototype
```c
t8_locidx_t t8_forest_get_local_id (t8_forest_t forest, t8_gloidx_t gtreeid);
```
"""
function t8_forest_get_local_id(forest, gtreeid)
    @ccall libt8.t8_forest_get_local_id(forest::t8_forest_t, gtreeid::t8_gloidx_t)::t8_locidx_t
end

"""
    t8_forest_ltreeid_to_cmesh_ltreeid(forest, ltreeid)

Given the local id of a tree in a forest, compute the tree's local id in the associated cmesh.

!!! note

    For forest local trees, this is the inverse function of t8_forest_cmesh_ltreeid_to_ltreeid.

### Parameters
* `forest`:\\[in\\] The forest.
* `ltreeid`:\\[in\\] The local id of a tree or ghost in the forest.
### Returns
The local id of the tree in the cmesh associated with the forest. *forest* must be committed before calling this function.
### See also
https://github.com/DLR-AMR/t8code/wiki/Tree-indexing for more details about tree indexing.

### Prototype
```c
t8_locidx_t t8_forest_ltreeid_to_cmesh_ltreeid (t8_forest_t forest, t8_locidx_t ltreeid);
```
"""
function t8_forest_ltreeid_to_cmesh_ltreeid(forest, ltreeid)
    @ccall libt8.t8_forest_ltreeid_to_cmesh_ltreeid(forest::t8_forest_t, ltreeid::t8_locidx_t)::t8_locidx_t
end

"""
    t8_forest_cmesh_ltreeid_to_ltreeid(forest, lctreeid)

Given the local id of a tree in the coarse mesh of a forest, compute the tree's local id in the forest.

!!! note

    For forest local trees, this is the inverse function of t8_forest_ltreeid_to_cmesh_ltreeid.

### Parameters
* `forest`:\\[in\\] The forest.
* `ltreeid`:\\[in\\] The local id of a tree in the coarse mesh of *forest*.
### Returns
The local id of the tree in the forest. -1 if the tree is not forest local. *forest* must be committed before calling this function.
### See also
https://github.com/DLR-AMR/t8code/wiki/Tree-indexing for more details about tree indexing.

### Prototype
```c
t8_locidx_t t8_forest_cmesh_ltreeid_to_ltreeid (t8_forest_t forest, t8_locidx_t lctreeid);
```
"""
function t8_forest_cmesh_ltreeid_to_ltreeid(forest, lctreeid)
    @ccall libt8.t8_forest_cmesh_ltreeid_to_ltreeid(forest::t8_forest_t, lctreeid::t8_locidx_t)::t8_locidx_t
end

"""
    t8_forest_get_coarse_tree(forest, ltreeid)

Given the local id of a tree in a forest, return the coarse tree of the cmesh that corresponds to this tree.

### Parameters
* `forest`:\\[in\\] The forest.
* `ltreeid`:\\[in\\] The local id of a tree in the forest.
### Returns
The coarse tree that matches the forest tree with local id *ltreeid*.
### Prototype
```c
t8_ctree_t t8_forest_get_coarse_tree (t8_forest_t forest, t8_locidx_t ltreeid);
```
"""
function t8_forest_get_coarse_tree(forest, ltreeid)
    @ccall libt8.t8_forest_get_coarse_tree(forest::t8_forest_t, ltreeid::t8_locidx_t)::t8_ctree_t
end

"""
    t8_forest_leaf_face_neighbors(forest, ltreeid, leaf, pneighbor_leafs, face, dual_faces, num_neighbors, pelement_indices, pneigh_scheme, forest_is_balanced)

Compute the leaf face neighbors of a forest.

!!! note

    If there are no face neighbors, then *neighbor\\_leafs = NULL, num\\_neighbors = 0, and *pelement\\_indices = NULL on output.

!!! note

    Currently *forest* must be balanced.

!!! note

    *forest* must be committed before calling this function.

### Parameters
* `forest`:\\[in\\] The forest. Must have a valid ghost layer.
* `ltreeid`:\\[in\\] A local tree id.
* `leaf`:\\[in\\] A leaf in tree *ltreeid* of *forest*.
* `neighbor_leafs`:\\[out\\] Unallocated on input. On output the neighbor leafs are stored here.
* `face`:\\[in\\] The index of the face across which the face neighbors are searched.
* `dual_face`:\\[out\\] On output the face id's of the neighboring elements' faces.
* `num_neighbors`:\\[out\\] On output the number of neighbor leafs.
* `pelement_indices`:\\[out\\] Unallocated on input. On output the element indices of the neighbor leafs are stored here. 0, 1, ... num\\_local\\_el - 1 for local leafs and num\\_local\\_el , ... , num\\_local\\_el + num\\_ghosts - 1 for ghosts.
* `pneigh_scheme`:\\[out\\] On output the eclass scheme of the neighbor elements.
* `forest_is_balanced`:\\[in\\] True if we know that *forest* is balanced, false otherwise.
### Prototype
```c
void t8_forest_leaf_face_neighbors (t8_forest_t forest, t8_locidx_t ltreeid, const t8_element_t *leaf, t8_element_t **pneighbor_leafs[], int face, int *dual_faces[], int *num_neighbors, t8_locidx_t **pelement_indices, t8_eclass_scheme_c **pneigh_scheme, int forest_is_balanced);
```
"""
function t8_forest_leaf_face_neighbors(forest, ltreeid, leaf, pneighbor_leafs, face, dual_faces, num_neighbors, pelement_indices, pneigh_scheme, forest_is_balanced)
    @ccall libt8.t8_forest_leaf_face_neighbors(forest::t8_forest_t, ltreeid::t8_locidx_t, leaf::Ptr{t8_element_t}, pneighbor_leafs::Ptr{Ptr{Ptr{t8_element_t}}}, face::Cint, dual_faces::Ptr{Ptr{Cint}}, num_neighbors::Ptr{Cint}, pelement_indices::Ptr{Ptr{t8_locidx_t}}, pneigh_scheme::Ptr{Ptr{t8_eclass_scheme_c}}, forest_is_balanced::Cint)::Cvoid
end

"""
    t8_forest_ghost_exchange_data(forest, element_data)

Exchange ghost information of user defined element data.

!!! note

    This function is collective and hence must be called by all processes in the forest's MPI Communicator.

### Parameters
* `forest`:\\[in\\] The forest. Must be committed.
* `element_data`:\\[in\\] An array of length num\\_local\\_elements + num\\_ghosts storing one value for each local element and ghost in *forest*. After calling this function the entries for the ghost elements are update with the entries in the *element_data* array of the corresponding owning process.
### Prototype
```c
void t8_forest_ghost_exchange_data (t8_forest_t forest, sc_array_t *element_data);
```
"""
function t8_forest_ghost_exchange_data(forest, element_data)
    @ccall libt8.t8_forest_ghost_exchange_data(forest::t8_forest_t, element_data::Ptr{sc_array_t})::Cvoid
end

"""
    t8_forest_ghost_print(forest)

Print the ghost structure of a forest. Only used for debugging.

### Prototype
```c
void t8_forest_ghost_print (t8_forest_t forest);
```
"""
function t8_forest_ghost_print(forest)
    @ccall libt8.t8_forest_ghost_print(forest::t8_forest_t)::Cvoid
end

"""
    t8_forest_partition_cmesh(forest, comm, set_profiling)

### Prototype
```c
void t8_forest_partition_cmesh (t8_forest_t forest, sc_MPI_Comm comm, int set_profiling);
```
"""
function t8_forest_partition_cmesh(forest, comm, set_profiling)
    @ccall libt8.t8_forest_partition_cmesh(forest::t8_forest_t, comm::MPI_Comm, set_profiling::Cint)::Cvoid
end

"""
    t8_forest_get_mpicomm(forest)

### Prototype
```c
sc_MPI_Comm t8_forest_get_mpicomm (t8_forest_t forest);
```
"""
function t8_forest_get_mpicomm(forest)
    @ccall libt8.t8_forest_get_mpicomm(forest::t8_forest_t)::Cint
end

"""
    t8_forest_get_first_local_tree_id(forest)

Return the global id of the first local tree of a forest.

### Parameters
* `forest`:\\[in\\] The forest.
### Returns
The global id of the first local tree in *forest*.
### Prototype
```c
t8_gloidx_t t8_forest_get_first_local_tree_id (t8_forest_t forest);
```
"""
function t8_forest_get_first_local_tree_id(forest)
    @ccall libt8.t8_forest_get_first_local_tree_id(forest::t8_forest_t)::t8_gloidx_t
end

"""
    t8_forest_get_num_local_trees(forest)

Return the number of local trees of a given forest.

### Parameters
* `forest`:\\[in\\] The forest.
### Returns
The number of local trees of that forest.
### Prototype
```c
t8_locidx_t t8_forest_get_num_local_trees (t8_forest_t forest);
```
"""
function t8_forest_get_num_local_trees(forest)
    @ccall libt8.t8_forest_get_num_local_trees(forest::t8_forest_t)::t8_locidx_t
end

"""
    t8_forest_get_num_ghost_trees(forest)

Return the number of ghost trees of a given forest.

### Parameters
* `forest`:\\[in\\] The forest.
### Returns
The number of ghost trees of that forest.
### Prototype
```c
t8_locidx_t t8_forest_get_num_ghost_trees (t8_forest_t forest);
```
"""
function t8_forest_get_num_ghost_trees(forest)
    @ccall libt8.t8_forest_get_num_ghost_trees(forest::t8_forest_t)::t8_locidx_t
end

"""
    t8_forest_get_num_global_trees(forest)

Return the number of global trees of a given forest.

### Parameters
* `forest`:\\[in\\] The forest.
### Returns
The number of global trees of that forest.
### Prototype
```c
t8_gloidx_t t8_forest_get_num_global_trees (t8_forest_t forest);
```
"""
function t8_forest_get_num_global_trees(forest)
    @ccall libt8.t8_forest_get_num_global_trees(forest::t8_forest_t)::t8_gloidx_t
end

"""
    t8_forest_global_tree_id(forest, ltreeid)

Return the global id of a local tree or a ghost tree.

### Parameters
* `forest`:\\[in\\] The forest.
* `ltreeid`:\\[in\\] An id 0 <= *ltreeid* < num\\_local\\_trees + num\\_ghosts specifying a local tree or ghost tree.
### Returns
The global id corresponding to the tree with local id *ltreeid*. *forest* must be committed before calling this function.
### See also
https://github.com/DLR-AMR/t8code/wiki/Tree-indexing for more details about tree indexing.

### Prototype
```c
t8_gloidx_t t8_forest_global_tree_id (t8_forest_t forest, t8_locidx_t ltreeid);
```
"""
function t8_forest_global_tree_id(forest, ltreeid)
    @ccall libt8.t8_forest_global_tree_id(forest::t8_forest_t, ltreeid::t8_locidx_t)::t8_gloidx_t
end

"""
    t8_forest_get_tree(forest, ltree_id)

Return a pointer to a tree in a forest.

### Parameters
* `forest`:\\[in\\] The forest.
* `ltree_id`:\\[in\\] The local id of the tree.
### Returns
A pointer to the tree with local id *ltree_id*. *forest* must be committed before calling this function.
### Prototype
```c
t8_tree_t t8_forest_get_tree (t8_forest_t forest, t8_locidx_t ltree_id);
```
"""
function t8_forest_get_tree(forest, ltree_id)
    @ccall libt8.t8_forest_get_tree(forest::t8_forest_t, ltree_id::t8_locidx_t)::t8_tree_t
end

"""
    t8_forest_get_tree_vertices(forest, ltreeid)

Return a pointer to the vertex coordinates of a tree.

### Parameters
* `forest`:\\[in\\] The forest.
* `ltreeid`:\\[in\\] The id of a local tree.
### Returns
If stored, a pointer to the vertex coordinates of *tree*. If no coordinates for this tree are found, NULL.
### Prototype
```c
double *t8_forest_get_tree_vertices (t8_forest_t forest, t8_locidx_t ltreeid);
```
"""
function t8_forest_get_tree_vertices(forest, ltreeid)
    @ccall libt8.t8_forest_get_tree_vertices(forest::t8_forest_t, ltreeid::t8_locidx_t)::Ptr{Cdouble}
end

"""
    t8_forest_tree_get_leafs(forest, ltree_id)

Return the array of leaf elements of a local tree in a forest.

### Parameters
* `forest`:\\[in\\] The forest.
* `ltree_id`:\\[in\\] The local id of a local tree of *forest*.
### Returns
An array of [`t8_element_t`](@ref) * storing all leaf elements of this tree.
### Prototype
```c
t8_element_array_t *t8_forest_tree_get_leafs (t8_forest_t forest, t8_locidx_t ltree_id);
```
"""
function t8_forest_tree_get_leafs(forest, ltree_id)
    @ccall libt8.t8_forest_tree_get_leafs(forest::t8_forest_t, ltree_id::t8_locidx_t)::Ptr{t8_element_array_t}
end

"""
    t8_forest_get_cmesh(forest)

Return a cmesh associated to a forest.

### Parameters
* `forest`:\\[in\\] The forest.
### Returns
The cmesh associated to the forest.
### Prototype
```c
t8_cmesh_t t8_forest_get_cmesh (t8_forest_t forest);
```
"""
function t8_forest_get_cmesh(forest)
    @ccall libt8.t8_forest_get_cmesh(forest::t8_forest_t)::t8_cmesh_t
end

"""
    t8_forest_get_element(forest, lelement_id, ltreeid)

Return an element of the forest.

!!! note

    This function performs a binary search. For constant access, use t8_forest_get_element_in_tree *forest* must be committed before calling this function.

### Parameters
* `forest`:\\[in\\] The forest.
* `lelement_id`:\\[in\\] The local id of an element in *forest*.
* `ltreeid`:\\[out\\] If not NULL, on output the local tree id of the tree in which the element lies in.
### Returns
A pointer to the element. NULL if this element does not exist.
### Prototype
```c
t8_element_t *t8_forest_get_element (t8_forest_t forest, t8_locidx_t lelement_id, t8_locidx_t *ltreeid);
```
"""
function t8_forest_get_element(forest, lelement_id, ltreeid)
    @ccall libt8.t8_forest_get_element(forest::t8_forest_t, lelement_id::t8_locidx_t, ltreeid::Ptr{t8_locidx_t})::Ptr{t8_element_t}
end

"""
    t8_forest_get_element_in_tree(forest, ltreeid, leid_in_tree)

Return an element of a local tree in a forest.

!!! note

    If the tree id is know, this function should be preferred over t8_forest_get_element. *forest* must be committed before calling this function.

### Parameters
* `forest`:\\[in\\] The forest.
* `ltreeid`:\\[in\\] An id of a local tree in the forest.
* `leid_in_tree`:\\[in\\] The index of an element in the tree.
### Returns
A pointer to the element.
### Prototype
```c
t8_element_t *t8_forest_get_element_in_tree (t8_forest_t forest, t8_locidx_t ltreeid, t8_locidx_t leid_in_tree);
```
"""
function t8_forest_get_element_in_tree(forest, ltreeid, leid_in_tree)
    @ccall libt8.t8_forest_get_element_in_tree(forest::t8_forest_t, ltreeid::t8_locidx_t, leid_in_tree::t8_locidx_t)::Ptr{t8_element_t}
end

"""
    t8_forest_get_tree_num_elements(forest, ltreeid)

Return the number of elements of a tree.

### Parameters
* `forest`:\\[in\\] The forest.
* `ltreeid`:\\[in\\] A local id of a tree.
### Returns
The number of elements in the local tree *ltreeid*.
### Prototype
```c
t8_locidx_t t8_forest_get_tree_num_elements (t8_forest_t forest, t8_locidx_t ltreeid);
```
"""
function t8_forest_get_tree_num_elements(forest, ltreeid)
    @ccall libt8.t8_forest_get_tree_num_elements(forest::t8_forest_t, ltreeid::t8_locidx_t)::t8_locidx_t
end

"""
    t8_forest_get_tree_element_offset(forest, ltreeid)

Return the element offset of a local tree, that is the number of elements in all trees with smaller local treeid.

!!! note

    *forest* must be committed before calling this function.

### Parameters
* `forest`:\\[in\\] The forest.
* `ltreeid`:\\[in\\] A local id of a tree.
### Returns
The number of leaf elements on all local tree with id < *ltreeid*.
### Prototype
```c
t8_locidx_t t8_forest_get_tree_element_offset (t8_forest_t forest, t8_locidx_t ltreeid);
```
"""
function t8_forest_get_tree_element_offset(forest, ltreeid)
    @ccall libt8.t8_forest_get_tree_element_offset(forest::t8_forest_t, ltreeid::t8_locidx_t)::t8_locidx_t
end

"""
    t8_forest_get_tree_element_count(tree)

Return the number of elements of a tree.

### Parameters
* `tree`:\\[in\\] A tree in a forest.
### Returns
The number of elements of that tree.
### Prototype
```c
t8_locidx_t t8_forest_get_tree_element_count (t8_tree_t tree);
```
"""
function t8_forest_get_tree_element_count(tree)
    @ccall libt8.t8_forest_get_tree_element_count(tree::t8_tree_t)::t8_locidx_t
end

"""
    t8_forest_get_tree_class(forest, ltreeid)

Return the eclass of a tree in a forest.

### Parameters
* `forest`:\\[in\\] The forest.
* `ltreeid`:\\[in\\] The local id of a tree (local or ghost) in *forest*.
### Returns
The element class of the tree with local id *ltreeid*.
### Prototype
```c
t8_eclass_t t8_forest_get_tree_class (t8_forest_t forest, t8_locidx_t ltreeid);
```
"""
function t8_forest_get_tree_class(forest, ltreeid)
    @ccall libt8.t8_forest_get_tree_class(forest::t8_forest_t, ltreeid::t8_locidx_t)::t8_eclass_t
end

"""
    t8_forest_get_first_local_element_id(forest)

Compute the global index of the first local element of a forest. This function is collective.

### Parameters
* `forest`:\\[in\\] A committed forest, whose first element's index is computed.
### Returns
The global index of *forest*'s first local element. Forest must be committed when calling this function. This function is collective and must be called on each process.
### Prototype
```c
t8_gloidx_t t8_forest_get_first_local_element_id (t8_forest_t forest);
```
"""
function t8_forest_get_first_local_element_id(forest)
    @ccall libt8.t8_forest_get_first_local_element_id(forest::t8_forest_t)::t8_gloidx_t
end

"""
    t8_forest_get_scheme(forest)

Return the element scheme associated to a forest.

### Parameters
* `forest.`:\\[in\\] A committed forest.
### Returns
The element scheme of the forest.
### See also
[`t8_forest_set_scheme`](@ref)

### Prototype
```c
t8_scheme_cxx_t *t8_forest_get_scheme (t8_forest_t forest);
```
"""
function t8_forest_get_scheme(forest)
    @ccall libt8.t8_forest_get_scheme(forest::t8_forest_t)::Ptr{t8_scheme_cxx_t}
end

"""
    t8_forest_get_eclass_scheme(forest, eclass)

Return the eclass scheme of a given element class associated to a forest.

!!! note

    The forest is not required to have trees of class *eclass*.

### Parameters
* `forest.`:\\[in\\] A committed forest.
* `eclass.`:\\[in\\] An element class.
### Returns
The eclass scheme of *eclass* associated to forest.
### See also
[`t8_forest_set_scheme`](@ref)

### Prototype
```c
t8_eclass_scheme_c *t8_forest_get_eclass_scheme (t8_forest_t forest, t8_eclass_t eclass);
```
"""
function t8_forest_get_eclass_scheme(forest, eclass)
    @ccall libt8.t8_forest_get_eclass_scheme(forest::t8_forest_t, eclass::t8_eclass_t)::Ptr{t8_eclass_scheme_c}
end

"""
    t8_forest_element_neighbor_eclass(forest, ltreeid, elem, face)

Return the eclass of the tree in which a face neighbor of a given element lies.

### Parameters
* `forest.`:\\[in\\] A committed forest.
* `ltreeid.`:\\[in\\] The local tree in which the element lies.
* `elem.`:\\[in\\] An element in the tree *ltreeid*.
* `face.`:\\[in\\] A face number of *elem*.
### Returns
The local tree id of the tree in which the face neighbor of *elem* across *face* lies.
### Prototype
```c
t8_eclass_t t8_forest_element_neighbor_eclass (t8_forest_t forest, t8_locidx_t ltreeid, const t8_element_t *elem, int face);
```
"""
function t8_forest_element_neighbor_eclass(forest, ltreeid, elem, face)
    @ccall libt8.t8_forest_element_neighbor_eclass(forest::t8_forest_t, ltreeid::t8_locidx_t, elem::Ptr{t8_element_t}, face::Cint)::t8_eclass_t
end

"""
    t8_forest_element_face_neighbor(forest, ltreeid, elem, neigh, neigh_scheme, face, neigh_face)

Construct the face neighbor of an element, possibly across tree boundaries. Returns the global tree-id of the tree in which the neighbor element lies in.

### Parameters
* `elem`:\\[in\\] The element to be considered.
* `neigh`:\\[in,out\\] On input an allocated element of the scheme of the face\\_neighbors eclass. On output, this element's data is filled with the data of the face neighbor. If the neighbor does not exist the data could be modified arbitrarily.
* `neigh_scheme`:\\[in\\] The eclass scheme of *neigh*.
* `face`:\\[in\\] The number of the face along which the neighbor should be constructed.
* `neigh_face`:\\[out\\] The number of the face viewed from perspective of *neigh*.
### Returns
The global tree-id of the tree in which *neigh* is in. -1 if there exists no neighbor across that face.
### Prototype
```c
t8_gloidx_t t8_forest_element_face_neighbor (t8_forest_t forest, t8_locidx_t ltreeid, const t8_element_t *elem, t8_element_t *neigh, t8_eclass_scheme_c *neigh_scheme, int face, int *neigh_face);
```
"""
function t8_forest_element_face_neighbor(forest, ltreeid, elem, neigh, neigh_scheme, face, neigh_face)
    @ccall libt8.t8_forest_element_face_neighbor(forest::t8_forest_t, ltreeid::t8_locidx_t, elem::Ptr{t8_element_t}, neigh::Ptr{t8_element_t}, neigh_scheme::Ptr{t8_eclass_scheme_c}, face::Cint, neigh_face::Ptr{Cint})::t8_gloidx_t
end

"""
    t8_forest_iterate(forest)

### Prototype
```c
void t8_forest_iterate (t8_forest_t forest);
```
"""
function t8_forest_iterate(forest)
    @ccall libt8.t8_forest_iterate(forest::t8_forest_t)::Cvoid
end

"""
    t8_forest_element_point_inside(forest, ltreeid, element, point, tolerance)

Query whether a given point lies inside an element or not. For bilinearly interpolated elements.

!!! note

    For 2D quadrilateral elements this function is only an approximation. It is correct if the four vertices lie in the same plane, but it may produce only approximate results if  the vertices do not lie in the same plane.

### Parameters
* `forest`:\\[in\\] The forest.
* `ltree_id`:\\[in\\] The forest local id of the tree in which the element is.
* `element`:\\[in\\] The element.
* `point`:\\[in\\] 3-dimensional coordinates of the point to check
* `tolerance`:\\[in\\] tolerance that we allow the point to not exactly match the element. If this value is larger we detect more points. If it is zero we probably do not detect points even if they are inside due to rounding errors.
### Returns
True (non-zero) if *point* lies within *element*, false otherwise. The return value is also true if the point lies on the element boundary. Thus, this function may return true for different leaf elements, if they are neighbors and the point lies on the common boundary.
### Prototype
```c
int t8_forest_element_point_inside (t8_forest_t forest, t8_locidx_t ltreeid, const t8_element_t *element, const double point[3], const double tolerance);
```
"""
function t8_forest_element_point_inside(forest, ltreeid, element, point, tolerance)
    @ccall libt8.t8_forest_element_point_inside(forest::t8_forest_t, ltreeid::t8_locidx_t, element::Ptr{t8_element_t}, point::Ptr{Cdouble}, tolerance::Cdouble)::Cint
end

"""
    t8_forest_new_uniform(cmesh, scheme, level, do_face_ghost, comm)

### Prototype
```c
t8_forest_t t8_forest_new_uniform (t8_cmesh_t cmesh, t8_scheme_cxx_t *scheme, int level, int do_face_ghost, sc_MPI_Comm comm);
```
"""
function t8_forest_new_uniform(cmesh, scheme, level, do_face_ghost, comm)
    @ccall libt8.t8_forest_new_uniform(cmesh::t8_cmesh_t, scheme::Ptr{t8_scheme_cxx_t}, level::Cint, do_face_ghost::Cint, comm::MPI_Comm)::t8_forest_t
end

"""
    t8_forest_new_adapt(forest_from, adapt_fn, recursive, do_face_ghost, user_data)

Build a adapted forest from another forest.

!!! note

    This is equivalent to calling t8_forest_init, t8_forest_set_adapt, t8_forest_set_ghost, and t8_forest_commit

### Parameters
* `forest_from`:\\[in\\] The forest to refine
* `adapt_fn`:\\[in\\] Adapt function to use
* `replace_fn`:\\[in\\] Replace function to use
* `recursive`:\\[in\\] If true adptation is recursive
* `do_face_ghost`:\\[in\\] If true, a layer of ghost elements is created for the forest.
* `user_data`:\\[in\\] If not NULL, the user data pointer of the forest is set to this value.
### Returns
A new forest that is adapted from *forest_from*.
### Prototype
```c
t8_forest_t t8_forest_new_adapt (t8_forest_t forest_from, t8_forest_adapt_t adapt_fn, int recursive, int do_face_ghost, void *user_data);
```
"""
function t8_forest_new_adapt(forest_from, adapt_fn, recursive, do_face_ghost, user_data)
    @ccall libt8.t8_forest_new_adapt(forest_from::t8_forest_t, adapt_fn::t8_forest_adapt_t, recursive::Cint, do_face_ghost::Cint, user_data::Ptr{Cvoid})::t8_forest_t
end

"""
    t8_forest_ref(forest)

Increase the reference counter of a forest.

### Parameters
* `forest`:\\[in,out\\] On input, this forest must exist with positive reference count. It may be in any state.
### Prototype
```c
void t8_forest_ref (t8_forest_t forest);
```
"""
function t8_forest_ref(forest)
    @ccall libt8.t8_forest_ref(forest::t8_forest_t)::Cvoid
end

"""
    t8_forest_unref(pforest)

Decrease the reference counter of a forest. If the counter reaches zero, this forest is destroyed. In this case, the forest dereferences its cmesh and scheme members.

### Parameters
* `pforest`:\\[in,out\\] On input, the forest pointed to must exist with positive reference count. It may be in any state. If the reference count reaches zero, the forest is destroyed and this pointer set to NULL. Otherwise, the pointer is not changed and the forest is not modified in other ways.
### Prototype
```c
void t8_forest_unref (t8_forest_t *pforest);
```
"""
function t8_forest_unref(pforest)
    @ccall libt8.t8_forest_unref(pforest::Ptr{t8_forest_t})::Cvoid
end

"""
    t8_forest_element_coordinate(forest, ltree_id, element, corner_number, coordinates)

### Prototype
```c
void t8_forest_element_coordinate (t8_forest_t forest, t8_locidx_t ltree_id, const t8_element_t *element, int corner_number, double *coordinates);
```
"""
function t8_forest_element_coordinate(forest, ltree_id, element, corner_number, coordinates)
    @ccall libt8.t8_forest_element_coordinate(forest::t8_forest_t, ltree_id::t8_locidx_t, element::Ptr{t8_element_t}, corner_number::Cint, coordinates::Ptr{Cdouble})::Cvoid
end

"""
    t8_forest_element_centroid(forest, ltreeid, element, coordinates)

### Prototype
```c
void t8_forest_element_centroid (t8_forest_t forest, t8_locidx_t ltreeid, const t8_element_t *element, double *coordinates);
```
"""
function t8_forest_element_centroid(forest, ltreeid, element, coordinates)
    @ccall libt8.t8_forest_element_centroid(forest::t8_forest_t, ltreeid::t8_locidx_t, element::Ptr{t8_element_t}, coordinates::Ptr{Cdouble})::Cvoid
end

"""
    t8_forest_element_diam(forest, ltreeid, element)

### Prototype
```c
double t8_forest_element_diam (t8_forest_t forest, t8_locidx_t ltreeid, const t8_element_t *element);
```
"""
function t8_forest_element_diam(forest, ltreeid, element)
    @ccall libt8.t8_forest_element_diam(forest::t8_forest_t, ltreeid::t8_locidx_t, element::Ptr{t8_element_t})::Cdouble
end

"""
    t8_forest_element_volume(forest, ltreeid, element)

### Prototype
```c
double t8_forest_element_volume (t8_forest_t forest, t8_locidx_t ltreeid, const t8_element_t *element);
```
"""
function t8_forest_element_volume(forest, ltreeid, element)
    @ccall libt8.t8_forest_element_volume(forest::t8_forest_t, ltreeid::t8_locidx_t, element::Ptr{t8_element_t})::Cdouble
end

"""
    t8_forest_element_face_area(forest, ltreeid, element, face)

### Prototype
```c
double t8_forest_element_face_area (t8_forest_t forest, t8_locidx_t ltreeid, const t8_element_t *element, int face);
```
"""
function t8_forest_element_face_area(forest, ltreeid, element, face)
    @ccall libt8.t8_forest_element_face_area(forest::t8_forest_t, ltreeid::t8_locidx_t, element::Ptr{t8_element_t}, face::Cint)::Cdouble
end

"""
    t8_forest_element_face_centroid(forest, ltreeid, element, face, centroid)

### Prototype
```c
void t8_forest_element_face_centroid (t8_forest_t forest, t8_locidx_t ltreeid, const t8_element_t *element, int face, double centroid[3]);
```
"""
function t8_forest_element_face_centroid(forest, ltreeid, element, face, centroid)
    @ccall libt8.t8_forest_element_face_centroid(forest::t8_forest_t, ltreeid::t8_locidx_t, element::Ptr{t8_element_t}, face::Cint, centroid::Ptr{Cdouble})::Cvoid
end

"""
    t8_forest_element_face_normal(forest, ltreeid, element, face, normal)

### Prototype
```c
void t8_forest_element_face_normal (t8_forest_t forest, t8_locidx_t ltreeid, const t8_element_t *element, int face, double normal[3]);
```
"""
function t8_forest_element_face_normal(forest, ltreeid, element, face, normal)
    @ccall libt8.t8_forest_element_face_normal(forest::t8_forest_t, ltreeid::t8_locidx_t, element::Ptr{t8_element_t}, face::Cint, normal::Ptr{Cdouble})::Cvoid
end

"""
    t8_forest_save(forest)

### Prototype
```c
void t8_forest_save (t8_forest_t forest);
```
"""
function t8_forest_save(forest)
    @ccall libt8.t8_forest_save(forest::t8_forest_t)::Cvoid
end

"""
    t8_forest_write_vtk_ext(forest, fileprefix, write_treeid, write_mpirank, write_level, write_element_id, write_ghosts, write_curved, do_not_use_API, num_data, data)

### Prototype
```c
int t8_forest_write_vtk_ext (t8_forest_t forest, const char *fileprefix, int write_treeid, int write_mpirank, int write_level, int write_element_id, int write_ghosts, int write_curved, int do_not_use_API, int num_data, t8_vtk_data_field_t *data);
```
"""
function t8_forest_write_vtk_ext(forest, fileprefix, write_treeid, write_mpirank, write_level, write_element_id, write_ghosts, write_curved, do_not_use_API, num_data, data)
    @ccall libt8.t8_forest_write_vtk_ext(forest::t8_forest_t, fileprefix::Cstring, write_treeid::Cint, write_mpirank::Cint, write_level::Cint, write_element_id::Cint, write_ghosts::Cint, write_curved::Cint, do_not_use_API::Cint, num_data::Cint, data::Ptr{t8_vtk_data_field_t})::Cint
end

"""
    t8_forest_write_vtk(forest, fileprefix)

### Prototype
```c
int t8_forest_write_vtk (t8_forest_t forest, const char *fileprefix);
```
"""
function t8_forest_write_vtk(forest, fileprefix)
    @ccall libt8.t8_forest_write_vtk(forest::t8_forest_t, fileprefix::Cstring)::Cint
end

# typedef int ( * t8_forest_iterate_face_fn ) ( t8_forest_t forest , t8_locidx_t ltreeid , const t8_element_t * element , int face , void * user_data , t8_locidx_t tree_leaf_index )
const t8_forest_iterate_face_fn = Ptr{Cvoid}

# typedef int ( * t8_forest_search_query_fn ) ( t8_forest_t forest , t8_locidx_t ltreeid , const t8_element_t * element , const int is_leaf , t8_element_array_t * leaf_elements , t8_locidx_t tree_leaf_index , void * query , size_t query_index )
const t8_forest_search_query_fn = Ptr{Cvoid}

"""
    t8_forest_split_array(element, leaf_elements, offsets)

### Prototype
```c
void t8_forest_split_array (const t8_element_t *element, t8_element_array_t *leaf_elements, size_t *offsets);
```
"""
function t8_forest_split_array(element, leaf_elements, offsets)
    @ccall libt8.t8_forest_split_array(element::Ptr{t8_element_t}, leaf_elements::Ptr{t8_element_array_t}, offsets::Ptr{Csize_t})::Cvoid
end

"""
    t8_forest_iterate_faces(forest, ltreeid, element, face, leaf_elements, user_data, tree_lindex_of_first_leaf, callback)

### Prototype
```c
void t8_forest_iterate_faces (t8_forest_t forest, t8_locidx_t ltreeid, const t8_element_t *element, int face, t8_element_array_t *leaf_elements, void *user_data, t8_locidx_t tree_lindex_of_first_leaf, t8_forest_iterate_face_fn callback);
```
"""
function t8_forest_iterate_faces(forest, ltreeid, element, face, leaf_elements, user_data, tree_lindex_of_first_leaf, callback)
    @ccall libt8.t8_forest_iterate_faces(forest::t8_forest_t, ltreeid::t8_locidx_t, element::Ptr{t8_element_t}, face::Cint, leaf_elements::Ptr{t8_element_array_t}, user_data::Ptr{Cvoid}, tree_lindex_of_first_leaf::t8_locidx_t, callback::t8_forest_iterate_face_fn)::Cvoid
end

"""
    t8_forest_search(forest, search_fn, query_fn, queries)

### Prototype
```c
void t8_forest_search (t8_forest_t forest, t8_forest_search_query_fn search_fn, t8_forest_search_query_fn query_fn, sc_array_t *queries);
```
"""
function t8_forest_search(forest, search_fn, query_fn, queries)
    @ccall libt8.t8_forest_search(forest::t8_forest_t, search_fn::t8_forest_search_query_fn, query_fn::t8_forest_search_query_fn, queries::Ptr{sc_array_t})::Cvoid
end

"""
    t8_forest_iterate_replace(forest_new, forest_old, replace_fn)

Given two forest where the elemnts in one forest are either direct children or parents of the elements in the other forest compare the two forests and for each refined element or coarsened family in the old one, call a callback function providing the local indices of the old and new elements.

!!! note

    To pass a user pointer to *replace_fn* use t8_forest_set_user_data and t8_forest_get_user_data.

### Parameters
* `forest_new`:\\[in\\] A forest, each element is a parent or child of an element in *forest_old*.
* `forest_old`:\\[in\\] The initial forest.
* `replace_fn`:\\[in\\] A replace callback function.
### Prototype
```c
void t8_forest_iterate_replace (t8_forest_t forest_new, t8_forest_t forest_old, t8_forest_replace_t replace_fn);
```
"""
function t8_forest_iterate_replace(forest_new, forest_old, replace_fn)
    @ccall libt8.t8_forest_iterate_replace(forest_new::t8_forest_t, forest_old::t8_forest_t, replace_fn::t8_forest_replace_t)::Cvoid
end

"""
    t8_forest_partition(forest)

### Prototype
```c
void t8_forest_partition (t8_forest_t forest);
```
"""
function t8_forest_partition(forest)
    @ccall libt8.t8_forest_partition(forest::t8_forest_t)::Cvoid
end

"""
    t8_forest_partition_create_offsets(forest)

Create the element\\_offset array of a partitioned forest.

### Parameters
* `forest`:\\[in,out\\] The forest. *forest* must be committed before calling this function.
### Prototype
```c
void t8_forest_partition_create_offsets (t8_forest_t forest);
```
"""
function t8_forest_partition_create_offsets(forest)
    @ccall libt8.t8_forest_partition_create_offsets(forest::t8_forest_t)::Cvoid
end

"""
    t8_forest_partition_next_nonempty_rank(forest, rank)

If t8_forest_partition_create_offsets was already called, compute for a given rank the next greater rank that is not empty.

### Parameters
* `forest`:\\[in\\] The forest.
* `rank`:\\[in\\] An MPI rank.
### Returns
A rank q > *rank* such that the forest has elements on *q*. If such a *q* does not exist, returns mpisize.
### Prototype
```c
int t8_forest_partition_next_nonempty_rank (t8_forest_t forest, int rank);
```
"""
function t8_forest_partition_next_nonempty_rank(forest, rank)
    @ccall libt8.t8_forest_partition_next_nonempty_rank(forest::t8_forest_t, rank::Cint)::Cint
end

"""
    t8_forest_partition_create_first_desc(forest)

Create the array of global\\_first\\_descendant ids of a partitioned forest.

### Parameters
* `forest`:\\[in,out\\] The forest. *forest* must be committed before calling this function.
### Prototype
```c
void t8_forest_partition_create_first_desc (t8_forest_t forest);
```
"""
function t8_forest_partition_create_first_desc(forest)
    @ccall libt8.t8_forest_partition_create_first_desc(forest::t8_forest_t)::Cvoid
end

"""
    t8_forest_partition_create_tree_offsets(forest)

Create the array tree offsets of a partitioned forest. This arrays stores at position p the global id of the first tree of this process. Or if this tree is shared, it stores -(global\\_id) - 1.

### Parameters
* `forest`:\\[in,out\\] The forest. *forest* must be committed before calling this function.
### Prototype
```c
void t8_forest_partition_create_tree_offsets (t8_forest_t forest);
```
"""
function t8_forest_partition_create_tree_offsets(forest)
    @ccall libt8.t8_forest_partition_create_tree_offsets(forest::t8_forest_t)::Cvoid
end

"""
    t8_forest_partition_data(forest_from, forest_to, data_in, data_out)

### Prototype
```c
void t8_forest_partition_data (t8_forest_t forest_from, t8_forest_t forest_to, const sc_array_t *data_in, sc_array_t *data_out);
```
"""
function t8_forest_partition_data(forest_from, forest_to, data_in, data_out)
    @ccall libt8.t8_forest_partition_data(forest_from::t8_forest_t, forest_to::t8_forest_t, data_in::Ptr{sc_array_t}, data_out::Ptr{sc_array_t})::Cvoid
end

"""
    t8_forest_set_profiling(forest, set_profiling)

### Prototype
```c
void t8_forest_set_profiling (t8_forest_t forest, int set_profiling);
```
"""
function t8_forest_set_profiling(forest, set_profiling)
    @ccall libt8.t8_forest_set_profiling(forest::t8_forest_t, set_profiling::Cint)::Cvoid
end

"""
    t8_forest_compute_profile(forest)

### Prototype
```c
void t8_forest_compute_profile (t8_forest_t forest);
```
"""
function t8_forest_compute_profile(forest)
    @ccall libt8.t8_forest_compute_profile(forest::t8_forest_t)::Cvoid
end

"""
    t8_forest_profile_get_adapt_stats(forest)

### Prototype
```c
const sc_statinfo_t *t8_forest_profile_get_adapt_stats (t8_forest_t forest);
```
"""
function t8_forest_profile_get_adapt_stats(forest)
    @ccall libt8.t8_forest_profile_get_adapt_stats(forest::t8_forest_t)::Ptr{sc_statinfo_t}
end

"""
    t8_forest_profile_get_ghost_stats(forest)

### Prototype
```c
const sc_statinfo_t *t8_forest_profile_get_ghost_stats (t8_forest_t forest);
```
"""
function t8_forest_profile_get_ghost_stats(forest)
    @ccall libt8.t8_forest_profile_get_ghost_stats(forest::t8_forest_t)::Ptr{sc_statinfo_t}
end

"""
    t8_forest_profile_get_partition_stats(forest)

### Prototype
```c
const sc_statinfo_t *t8_forest_profile_get_partition_stats (t8_forest_t forest);
```
"""
function t8_forest_profile_get_partition_stats(forest)
    @ccall libt8.t8_forest_profile_get_partition_stats(forest::t8_forest_t)::Ptr{sc_statinfo_t}
end

"""
    t8_forest_profile_get_commit_stats(forest)

### Prototype
```c
const sc_statinfo_t *t8_forest_profile_get_commit_stats (t8_forest_t forest);
```
"""
function t8_forest_profile_get_commit_stats(forest)
    @ccall libt8.t8_forest_profile_get_commit_stats(forest::t8_forest_t)::Ptr{sc_statinfo_t}
end

"""
    t8_forest_profile_get_balance_stats(forest)

### Prototype
```c
const sc_statinfo_t *t8_forest_profile_get_balance_stats (t8_forest_t forest);
```
"""
function t8_forest_profile_get_balance_stats(forest)
    @ccall libt8.t8_forest_profile_get_balance_stats(forest::t8_forest_t)::Ptr{sc_statinfo_t}
end

"""
    t8_forest_profile_get_balance_rounds_stats(forest)

### Prototype
```c
const sc_statinfo_t * t8_forest_profile_get_balance_rounds_stats (t8_forest_t forest);
```
"""
function t8_forest_profile_get_balance_rounds_stats(forest)
    @ccall libt8.t8_forest_profile_get_balance_rounds_stats(forest::t8_forest_t)::Ptr{sc_statinfo_t}
end

"""
    t8_forest_print_profile(forest)

### Prototype
```c
void t8_forest_print_profile (t8_forest_t forest);
```
"""
function t8_forest_print_profile(forest)
    @ccall libt8.t8_forest_print_profile(forest::t8_forest_t)::Cvoid
end

"""
    t8_forest_profile_get_adapt_time(forest)

### Prototype
```c
double t8_forest_profile_get_adapt_time (t8_forest_t forest);
```
"""
function t8_forest_profile_get_adapt_time(forest)
    @ccall libt8.t8_forest_profile_get_adapt_time(forest::t8_forest_t)::Cdouble
end

"""
    t8_forest_profile_get_partition_time(forest, procs_sent)

### Prototype
```c
double t8_forest_profile_get_partition_time (t8_forest_t forest, int *procs_sent);
```
"""
function t8_forest_profile_get_partition_time(forest, procs_sent)
    @ccall libt8.t8_forest_profile_get_partition_time(forest::t8_forest_t, procs_sent::Ptr{Cint})::Cdouble
end

"""
    t8_forest_profile_get_balance_time(forest, balance_rounds)

### Prototype
```c
double t8_forest_profile_get_balance_time (t8_forest_t forest, int *balance_rounds);
```
"""
function t8_forest_profile_get_balance_time(forest, balance_rounds)
    @ccall libt8.t8_forest_profile_get_balance_time(forest::t8_forest_t, balance_rounds::Ptr{Cint})::Cdouble
end

"""
    t8_forest_profile_get_ghost_time(forest, ghosts_sent)

### Prototype
```c
double t8_forest_profile_get_ghost_time (t8_forest_t forest, t8_locidx_t *ghosts_sent);
```
"""
function t8_forest_profile_get_ghost_time(forest, ghosts_sent)
    @ccall libt8.t8_forest_profile_get_ghost_time(forest::t8_forest_t, ghosts_sent::Ptr{t8_locidx_t})::Cdouble
end

"""
    t8_forest_profile_get_ghostexchange_waittime(forest)

### Prototype
```c
double t8_forest_profile_get_ghostexchange_waittime (t8_forest_t forest);
```
"""
function t8_forest_profile_get_ghostexchange_waittime(forest)
    @ccall libt8.t8_forest_profile_get_ghostexchange_waittime(forest::t8_forest_t)::Cdouble
end

"""
    t8_forest_vtk_write_file_via_API(forest, fileprefix, write_treeid, write_mpirank, write_level, write_element_id, curved_flag, num_data, data)

Write the forest in .pvtu file format. Writes one .vtu file per process and a meta .pvtu file. This function uses the vtk library. t8code must be configured with "--with-vtk" in order to use it. Currently does not support pyramid elements.

!!! note

    If t8code was not configured with vtk, use t8_forest_vtk_write_file

### Parameters
* `forest`:\\[in\\] The forest.
* `fileprefix`:\\[in\\] The prefix of the output files. The meta file will be named *fileprefix*.pvtu .
* `write_treeid`:\\[in\\] If true, the global tree id is written for each element.
* `write_mpirank`:\\[in\\] If true, the mpirank is written for each element.
* `write_level`:\\[in\\] If true, the refinement level is written for each element.
* `write_element_id`:\\[in\\] If true, the global element id is written for each element.
* `curved_flag`:\\[in\\] If true, write the elements as curved element types from vtk.
* `num_data`:\\[in\\] Number of user defined double valued data fields to write.
* `data`:\\[in\\] Array of [`t8_vtk_data_field_t`](@ref) of length *num_data* providing the user defined per element data. If scalar and vector fields are used, all scalar fields must come first in the array.
### Returns
True if successful, false if not (process local).
### Prototype
```c
int t8_forest_vtk_write_file_via_API (t8_forest_t forest, const char *fileprefix, int write_treeid, int write_mpirank, int write_level, int write_element_id, int curved_flag, int num_data, t8_vtk_data_field_t *data);
```
"""
function t8_forest_vtk_write_file_via_API(forest, fileprefix, write_treeid, write_mpirank, write_level, write_element_id, curved_flag, num_data, data)
    @ccall libt8.t8_forest_vtk_write_file_via_API(forest::t8_forest_t, fileprefix::Cstring, write_treeid::Cint, write_mpirank::Cint, write_level::Cint, write_element_id::Cint, curved_flag::Cint, num_data::Cint, data::Ptr{t8_vtk_data_field_t})::Cint
end

"""
    t8_forest_vtk_write_file(forest, fileprefix, write_treeid, write_mpirank, write_level, write_element_id, write_ghosts, num_data, data)

Write the forest in .pvtu file format. Writes one .vtu file per process and a meta .pvtu file. This function writes ASCII files and can be used when t8code is not configure with "--with-vtk" and t8_forest_vtk_write_file_via_API is not available.

### Parameters
* `forest`:\\[in\\] The forest.
* `fileprefix`:\\[in\\] The prefix of the output files.
* `write_treeid`:\\[in\\] If true, the global tree id is written for each element.
* `write_mpirank`:\\[in\\] If true, the mpirank is written for each element.
* `write_level`:\\[in\\] If true, the refinement level is written for each element.
* `write_element_id`:\\[in\\] If true, the global element id is written for each element.
* `write_ghosts`:\\[in\\] If true, each process additionally writes its ghost elements. For ghost element the treeid is -1.
* `num_data`:\\[in\\] Number of user defined double valued data fields to write.
* `data`:\\[in\\] Array of [`t8_vtk_data_field_t`](@ref) of length *num_data* providing the used defined per element data. If scalar and vector fields are used, all scalar fields must come first in the array.
### Returns
True if succesful, false if not (process local).
### Prototype
```c
int t8_forest_vtk_write_file (t8_forest_t forest, const char *fileprefix, int write_treeid, int write_mpirank, int write_level, int write_element_id, int write_ghosts, int num_data, t8_vtk_data_field_t *data);
```
"""
function t8_forest_vtk_write_file(forest, fileprefix, write_treeid, write_mpirank, write_level, write_element_id, write_ghosts, num_data, data)
    @ccall libt8.t8_forest_vtk_write_file(forest::t8_forest_t, fileprefix::Cstring, write_treeid::Cint, write_mpirank::Cint, write_level::Cint, write_element_id::Cint, write_ghosts::Cint, num_data::Cint, data::Ptr{t8_vtk_data_field_t})::Cint
end

struct t8_geometry_handler
    registered_geometries::sc_array_t
    active_geometry::Ptr{t8_geometry_c}
    active_tree::t8_gloidx_t
    is_committed::Cint
    rc::t8_refcount_t
end

const t8_geometry_handler_t = t8_geometry_handler

"""
    t8_geom_handler_init(pgeom_handler)

Initialize a geometry handler. This will allocate memory.

### Parameters
* `pgeom_handler`:\\[in,out\\] On input a pointer to unallocated memory. On output this will point to an initialized geometry handler.
### Prototype
```c
void t8_geom_handler_init (t8_geometry_handler_t **pgeom_handler);
```
"""
function t8_geom_handler_init(pgeom_handler)
    @ccall libt8.t8_geom_handler_init(pgeom_handler::Ptr{Ptr{t8_geometry_handler_t}})::Cvoid
end

"""
    t8_geom_handler_ref(geom_handler)

Increase the reference counter of a geometry handler.

### Parameters
* `geom_handler`:\\[in\\] An initialized geometry handler.
### Prototype
```c
void t8_geom_handler_ref (t8_geometry_handler_t *geom_handler);
```
"""
function t8_geom_handler_ref(geom_handler)
    @ccall libt8.t8_geom_handler_ref(geom_handler::Ptr{t8_geometry_handler_t})::Cvoid
end

"""
    t8_geom_handler_unref(pgeom_handler)

Decrease the reference count of a geometry handler, if the refcount reaches 0, the handler will get destroyed.

### Parameters
* `pgeom_handler`:\\[in,out\\] Pointer to an initialized geometry handler. If the refcount reaches 0, will point to NULL afterwards.
### Prototype
```c
void t8_geom_handler_unref (t8_geometry_handler_t **pgeom_handler);
```
"""
function t8_geom_handler_unref(pgeom_handler)
    @ccall libt8.t8_geom_handler_unref(pgeom_handler::Ptr{Ptr{t8_geometry_handler_t}})::Cvoid
end

"""
    t8_geom_handler_destroy(pgeom_handler)

Destroy a geometry handler and free its memory.  This is only valid if its reference count is 1. If you are unsure, call t8_geom_handler_unref instead.

### Parameters
* `pgeom_handler`:\\[in,out\\] Pointer to an initialized geometry handler. Will point to NULL afterwards.
### Prototype
```c
void t8_geom_handler_destroy (t8_geometry_handler_t **pgeom_handler);
```
"""
function t8_geom_handler_destroy(pgeom_handler)
    @ccall libt8.t8_geom_handler_destroy(pgeom_handler::Ptr{Ptr{t8_geometry_handler_t}})::Cvoid
end

"""
    t8_geom_handler_register_geometry(geom_handler, geometry)

Add a geometry to the geometry handler.

### Parameters
* `geom_handler`:\\[in,out\\] An initialized but not committed geometry handler.
* `geometry`:\\[in\\] The geometry to add.
### Prototype
```c
void t8_geom_handler_register_geometry (t8_geometry_handler_t *geom_handler, const t8_geometry_c *geometry);
```
"""
function t8_geom_handler_register_geometry(geom_handler, geometry)
    @ccall libt8.t8_geom_handler_register_geometry(geom_handler::Ptr{t8_geometry_handler_t}, geometry::Ptr{t8_geometry_c})::Cvoid
end

"""
    t8_geom_handler_commit(geom_handler)

Commit a geometry handler. This specifies that no geometries will be added to it and makes it ready to be used.

### Parameters
* `geom_handler`:\\[in,out\\] An initialized but not committed geometry handler.
### Prototype
```c
void t8_geom_handler_commit (t8_geometry_handler_t *geom_handler);
```
"""
function t8_geom_handler_commit(geom_handler)
    @ccall libt8.t8_geom_handler_commit(geom_handler::Ptr{t8_geometry_handler_t})::Cvoid
end

"""
    t8_geom_handler_is_committed(geom_handler)

### Prototype
```c
int t8_geom_handler_is_committed (const t8_geometry_handler_t *geom_handler);
```
"""
function t8_geom_handler_is_committed(geom_handler)
    @ccall libt8.t8_geom_handler_is_committed(geom_handler::Ptr{t8_geometry_handler_t})::Cint
end

"""
    t8_geom_handler_get_num_geometries(geom_handler)

Return the number of registered geometries.

### Parameters
* `geom_handler`:\\[in\\] A geometry handler (must be initialized and may or may not be committed).
### Returns
The number of registered geometries in *geom_handler*.
### Prototype
```c
size_t t8_geom_handler_get_num_geometries (const t8_geometry_handler_t *geom_handler);
```
"""
function t8_geom_handler_get_num_geometries(geom_handler)
    @ccall libt8.t8_geom_handler_get_num_geometries(geom_handler::Ptr{t8_geometry_handler_t})::Csize_t
end

"""
    t8_geom_handler_get_unique_geometry(geom_handler)

If a geometry handler only has one registered geometry, get a pointer to this geometry.

!!! note

    Most cmeshes will have only one geometry and this function is an optimization for that special case. It is used for example in t8_cmesh_get_tree_geometry.

### Parameters
* `geom_handler`:\\[in\\] Must be committed and have exactly one geometry registered.
### Returns
The only registered geometry of *geom_handler*.
### Prototype
```c
const t8_geometry_c *t8_geom_handler_get_unique_geometry (const t8_geometry_handler_t *geom_handler);
```
"""
function t8_geom_handler_get_unique_geometry(geom_handler)
    @ccall libt8.t8_geom_handler_get_unique_geometry(geom_handler::Ptr{t8_geometry_handler_t})::Ptr{t8_geometry_c}
end

"""
    t8_geom_handler_find_geometry(geom_handler, name)

Given a geometry's name find that geometry in the geometry handler and return it.

### Parameters
* `geom_handler`:\\[in\\] A committed geometry handler.
* `name`:\\[in\\] The name of a geometry.
### Returns
A pointer to the geomery or NULL if it was not found.
### Prototype
```c
t8_geometry_c *t8_geom_handler_find_geometry (const t8_geometry_handler_t *geom_handler, const char *name);
```
"""
function t8_geom_handler_find_geometry(geom_handler, name)
    @ccall libt8.t8_geom_handler_find_geometry(geom_handler::Ptr{t8_geometry_handler_t}, name::Cstring)::Ptr{t8_geometry_c}
end

"""
    t8_geometry_evaluate(cmesh, gtreeid, ref_coords, out_coords)

### Prototype
```c
void t8_geometry_evaluate (t8_cmesh_t cmesh, t8_gloidx_t gtreeid, const double *ref_coords, double *out_coords);
```
"""
function t8_geometry_evaluate(cmesh, gtreeid, ref_coords, out_coords)
    @ccall libt8.t8_geometry_evaluate(cmesh::t8_cmesh_t, gtreeid::t8_gloidx_t, ref_coords::Ptr{Cdouble}, out_coords::Ptr{Cdouble})::Cvoid
end

"""
    t8_geometry_jacobian(cmesh, gtreeid, ref_coords, jacobian)

### Prototype
```c
void t8_geometry_jacobian (t8_cmesh_t cmesh, t8_gloidx_t gtreeid, const double *ref_coords, double *jacobian);
```
"""
function t8_geometry_jacobian(cmesh, gtreeid, ref_coords, jacobian)
    @ccall libt8.t8_geometry_jacobian(cmesh::t8_cmesh_t, gtreeid::t8_gloidx_t, ref_coords::Ptr{Cdouble}, jacobian::Ptr{Cdouble})::Cvoid
end

"""
    t8_geom_get_dimension(geom)

Get the dimension of a geometry.

### Parameters
* `geom`:\\[in\\] A geometry.
### Returns
The dimension of *geom*.
### Prototype
```c
int t8_geom_get_dimension (const t8_geometry_c *geom);
```
"""
function t8_geom_get_dimension(geom)
    @ccall libt8.t8_geom_get_dimension(geom::Ptr{t8_geometry_c})::Cint
end

"""
    t8_geom_get_name(geom)

Get the name of a geometry.

### Parameters
* `geom`:\\[in\\] A geometry.
### Returns
The name of *geom*.
### Prototype
```c
const char *t8_geom_get_name (const t8_geometry_c *geom);
```
"""
function t8_geom_get_name(geom)
    @ccall libt8.t8_geom_get_name(geom::Ptr{t8_geometry_c})::Cstring
end

"""
    t8_geom_compute_linear_geometry(tree_class, tree_vertices, ref_coords, out_coords)

### Prototype
```c
void t8_geom_compute_linear_geometry (t8_eclass_t tree_class, const double *tree_vertices, const double *ref_coords, double out_coords[3]);
```
"""
function t8_geom_compute_linear_geometry(tree_class, tree_vertices, ref_coords, out_coords)
    @ccall libt8.t8_geom_compute_linear_geometry(tree_class::Cint, tree_vertices::Ptr{Cdouble}, ref_coords::Ptr{Cdouble}, out_coords::Ptr{Cdouble})::Cvoid
end

"""
    t8_geom_linear_interpolation(coefficients, corner_values, corner_value_dim, interpolation_dim, evaluated_function)

Interpolates linearly between 2, bilinearly between 4 or trilineraly between 8 points.

### Parameters
* `coefficients`:\\[in\\] An array of size at least dim giving the coefficients used for the interpolation
* `corner_values`:\\[in\\] An array of size 2^dim * 3, giving for each corner (in zorder) of the unit square/cube its function values in space.
* `corner_value_dim`:\\[in\\] The dimension of the *corner_values*.
* `interpolation_dim`:\\[in\\] The dimension of the interpolation (1 for linear, 2 for bilinear, 3 for trilinear)
* `evaluated_function`:\\[out\\] An array of size *corner_value_dim*, on output the result of the interpolation.
### Prototype
```c
void t8_geom_linear_interpolation (const double *coefficients, const double *corner_values, int corner_value_dim, int interpolation_dim, double *evaluated_function);
```
"""
function t8_geom_linear_interpolation(coefficients, corner_values, corner_value_dim, interpolation_dim, evaluated_function)
    @ccall libt8.t8_geom_linear_interpolation(coefficients::Ptr{Cdouble}, corner_values::Ptr{Cdouble}, corner_value_dim::Cint, interpolation_dim::Cint, evaluated_function::Ptr{Cdouble})::Cvoid
end

"""
    t8_geom_get_face_vertices(tree_class, tree_vertices, face_index, dim, face_vertices)

### Prototype
```c
void t8_geom_get_face_vertices (t8_eclass_t tree_class, const double *tree_vertices, int face_index, int dim, double *face_vertices);
```
"""
function t8_geom_get_face_vertices(tree_class, tree_vertices, face_index, dim, face_vertices)
    @ccall libt8.t8_geom_get_face_vertices(tree_class::Cint, tree_vertices::Ptr{Cdouble}, face_index::Cint, dim::Cint, face_vertices::Ptr{Cdouble})::Cvoid
end

"""
    t8_geom_get_edge_vertices(tree_class, tree_vertices, edge_index, dim, edge_vertices)

### Prototype
```c
void t8_geom_get_edge_vertices (t8_eclass_t tree_class, const double *tree_vertices, int edge_index, int dim, double *edge_vertices);
```
"""
function t8_geom_get_edge_vertices(tree_class, tree_vertices, edge_index, dim, edge_vertices)
    @ccall libt8.t8_geom_get_edge_vertices(tree_class::Cint, tree_vertices::Ptr{Cdouble}, edge_index::Cint, dim::Cint, edge_vertices::Ptr{Cdouble})::Cvoid
end

"""
    t8_geometry_linear_new(dimension)

Create a new linear geometry of a given dimension.

### Parameters
* `dimension`:\\[in\\] 0 <= *dimension* <= 3. The dimension.
### Returns
A pointer to an allocated t8\\_geometry\\_linear struct, as if the t8\\_geometry\\_linear (int dimension) constructor was called.
### Prototype
```c
t8_geometry_c *t8_geometry_linear_new (int dimension);
```
"""
function t8_geometry_linear_new(dimension)
    @ccall libt8.t8_geometry_linear_new(dimension::Cint)::Ptr{t8_geometry_c}
end

"""
    t8_geometry_linear_destroy(geom)

Destroy a linear geometry that was created with t8_geometry_linear_new.

### Parameters
* `geom`:\\[in,out\\] A linear geometry. Set to NULL on output.
### Prototype
```c
void t8_geometry_linear_destroy (t8_geometry_c **geom);
```
"""
function t8_geometry_linear_destroy(geom)
    @ccall libt8.t8_geometry_linear_destroy(geom::Ptr{Ptr{t8_geometry_c}})::Cvoid
end

mutable struct t8_geometry_occ end

"""This typedef holds virtual functions for a particular geometry. We need it so that we can use [`t8_geometry_occ_c`](@ref) pointers in .c files without them seeing the actual C++ code (and then not compiling)"""
const t8_geometry_occ_c = t8_geometry_occ

"""
    t8_geometry_occ_new(dimension, fileprefix, name_in)

Create a new occ geometry of a given dimension.

### Parameters
* `dimension`:\\[in\\] 0 <= *dimension* <= 3. The dimension.
* `fileprefix`:\\[in\\] Prefix of a .brep file from which to extract an occ geometry.
* `name`:\\[in\\] The name to give this geometry.
### Returns
A pointer to an allocated [`t8_geometry_occ`](@ref) struct, as if the [`t8_geometry_occ`](@ref) (int dimension, const char *fileprefix, const char *name)  constructor was called.
### Prototype
```c
t8_geometry_occ_c *t8_geometry_occ_new (int dimension, const char *fileprefix, const char *name_in);
```
"""
function t8_geometry_occ_new(dimension, fileprefix, name_in)
    @ccall libt8.t8_geometry_occ_new(dimension::Cint, fileprefix::Cstring, name_in::Cstring)::Ptr{t8_geometry_occ_c}
end

"""
    t8_geometry_occ_destroy(geom)

Destroy a occ geometry that was created with t8_geometry_occ_new.

### Parameters
* `geom`:\\[in,out\\] A occ geometry. Set to NULL on output.
### Prototype
```c
void t8_geometry_occ_destroy (t8_geometry_occ_c ** geom);
```
"""
function t8_geometry_occ_destroy(geom)
    @ccall libt8.t8_geometry_occ_destroy(geom::Ptr{Ptr{t8_geometry_occ_c}})::Cvoid
end

"""
    t8_scheme_new_default_cxx()

Return the default element implementation of t8code.

### Prototype
```c
t8_scheme_cxx_t *t8_scheme_new_default_cxx (void);
```
"""
function t8_scheme_new_default_cxx()
    @ccall libt8.t8_scheme_new_default_cxx()::Ptr{t8_scheme_cxx_t}
end

"""
    t8_eclass_scheme_is_default(ts)

Check whether a given eclass\\_scheme is on of the default schemes.

### Parameters
* `ts`:\\[in\\] A (pointer to a) scheme
### Returns
True (non-zero) if *ts* is one of the default schemes, false (zero) otherwise.
### Prototype
```c
int t8_eclass_scheme_is_default (t8_eclass_scheme_c *ts);
```
"""
function t8_eclass_scheme_is_default(ts)
    @ccall libt8.t8_eclass_scheme_is_default(ts::Ptr{t8_eclass_scheme_c})::Cint
end

const SC_CC = "mpicc"

const SC_CFLAGS = "-O3"

const SC_CPP = "mpicc -E"

const SC_CPPFLAGS = "-I/workspace/destdir/include"

const SC_ENABLE_MEMALIGN = 1

const SC_ENABLE_MPI = 1

const SC_ENABLE_MPICOMMSHARED = 1

const SC_ENABLE_MPIIO = 1

const SC_ENABLE_MPISHARED = 1

const SC_ENABLE_MPITHREAD = 1

const SC_ENABLE_MPIWINSHARED = 1

const SC_ENABLE_USE_COUNTERS = 1

const SC_ENABLE_USE_REALLOC = 1

const SC_ENABLE_V4L2 = 1

const SC_HAVE_BACKTRACE = 1

const SC_HAVE_BACKTRACE_SYMBOLS = 1

const SC_HAVE_BASENAME = 1

const SC_HAVE_DIRNAME = 1

const SC_HAVE_FSYNC = 1

const SC_HAVE_GNU_QSORT_R = 1

const SC_HAVE_MATH = 1

const SC_HAVE_POSIX_MEMALIGN = 1

const SC_HAVE_QSORT_R = 1

const SC_HAVE_STRTOK_R = 1

const SC_HAVE_STRTOL = 1

const SC_HAVE_STRTOLL = 1

const SC_HAVE_ZLIB = 1

const SC_LDFLAGS = "-L/workspace/destdir/lib"

const SC_LIBS = "-lz -lm "

const SC_LT_OBJDIR = ".libs/"

const SC_MEMALIGN = 1

const SC_SIZEOF_VOID_P = 8

const SC_MEMALIGN_BYTES = SC_SIZEOF_VOID_P

const SC_MPI = 1

const SC_MPIIO = 1

const SC_PACKAGE = "libsc"

const SC_PACKAGE_BUGREPORT = "p4est@ins.uni-bonn.de"

const SC_PACKAGE_NAME = "libsc"

const SC_PACKAGE_STRING = "libsc 2.8.5.53-d4e5"

const SC_PACKAGE_TARNAME = "libsc"

const SC_PACKAGE_URL = ""

const SC_PACKAGE_VERSION = "2.8.5.53-d4e5"

const SC_SIZEOF_INT = 4

const SC_SIZEOF_LONG = 8

const SC_SIZEOF_LONG_LONG = 8

const SC_SIZEOF_UNSIGNED_INT = 4

const SC_SIZEOF_UNSIGNED_LONG = 8

const SC_SIZEOF_UNSIGNED_LONG_LONG = 8

const SC_STDC_HEADERS = 1

const SC_USE_COUNTERS = 1

const SC_USE_REALLOC = 1

const SC_USING_AUTOCONF = 1

const SC_VERSION = "2.8.5.53-d4e5"

const SC_VERSION_MAJOR = 2

const SC_VERSION_MINOR = 8
























const sc_MPI_COMM_WORLD = MPI.COMM_WORLD

const sc_MPI_COMM_SELF = MPI.COMM_SELF

const sc_MPI_CHAR = MPI.CHAR

const sc_MPI_SIGNED_CHAR = MPI.SIGNED_CHAR

const sc_MPI_UNSIGNED_CHAR = MPI.UNSIGNED_CHAR

const sc_MPI_BYTE = MPI.BYTE

const sc_MPI_SHORT = MPI.SHORT

const sc_MPI_UNSIGNED_SHORT = MPI.UNSIGNED_SHORT

const sc_MPI_INT = MPI.INT

const sc_MPI_UNSIGNED = MPI.UNSIGNED

const sc_MPI_LONG = MPI.LONG

const sc_MPI_UNSIGNED_LONG = MPI.UNSIGNED_LONG

const sc_MPI_LONG_LONG_INT = MPI.LONG_LONG_INT

const sc_MPI_UNSIGNED_LONG_LONG = MPI.UNSIGNED_LONG_LONG

const sc_MPI_FLOAT = MPI.FLOAT

const sc_MPI_DOUBLE = MPI.DOUBLE

const sc_MPI_Comm = MPI.Comm

const sc_MPI_Group = MPI.Group

const sc_MPI_Datatype = MPI.Datatype

const sc_MPI_Info = MPI.Info















const sc_MPI_File = MPI.File

const sc_MPI_FILE_NULL = MPI.FILE_NULL



const SC_EPS = 2.220446049250313e-16

const SC_1000_EPS = 1000.0 * 2.220446049250313e-16

const SC_LC_GLOBAL = 1

const SC_LC_NORMAL = 2

const SC_LP_DEFAULT = -1

const SC_LP_ALWAYS = 0

const SC_LP_TRACE = 1

const SC_LP_DEBUG = 2

const SC_LP_VERBOSE = 3

const SC_LP_INFO = 4

const SC_LP_STATISTICS = 5

const SC_LP_PRODUCTION = 6

const SC_LP_ESSENTIAL = 7

const SC_LP_ERROR = 8

const SC_LP_SILENT = 9

const SC_LP_THRESHOLD = SC_LP_INFO



const T8_MPI_LOCIDX = sc_MPI_INT

const T8_LOCIDX_MAX = INT32_MAX

const T8_MPI_GLOIDX = sc_MPI_LONG_LONG_INT

const T8_MPI_LINEARIDX = sc_MPI_UNSIGNED_LONG_LONG

# Skipping MacroDefinition: T8_PADDING_SIZE ( sizeof ( void * ) )

const T8_PRECISION_EPS = SC_EPS

const T8_CMESH_N_SUPPORTED_MSH_FILE_VERSIONS = 2

const T8_CC = "mpicc"

const T8_CFLAGS = "-O3"

const T8_CPP = "mpicc -E"

const T8_CPPFLAGS = "-I/workspace/destdir/include"

const T8_CPPSTD = 1

const T8_ENABLE_CPPSTD = 1

const T8_ENABLE_MEMALIGN = 1

const T8_ENABLE_MPI = 1

const T8_ENABLE_MPICOMMSHARED = 1

const T8_ENABLE_MPIIO = 1

const T8_ENABLE_MPISHARED = 1

const T8_ENABLE_MPITHREAD = 1

const T8_ENABLE_MPIWINSHARED = 1

const T8_HAVE_GNU_QSORT_R = 1

const T8_HAVE_MATH = 1

const T8_HAVE_POSIX_MEMALIGN = 1

const T8_HAVE_ZLIB = 1

const T8_LDFLAGS = "-L/workspace/destdir/lib"

const T8_LIBS = "-lz -lm  -lstdc++"

const T8_LT_OBJDIR = ".libs/"

const T8_MEMALIGN = 1

const T8_SIZEOF_VOID_P = 8

const T8_MEMALIGN_BYTES = T8_SIZEOF_VOID_P

const T8_MPI = 1

const T8_MPIIO = 1

const T8_PACKAGE = "t8"

const T8_PACKAGE_BUGREPORT = "johannes.holke@dlr.de, burstedde@ins.uni-bonn.de"

const T8_PACKAGE_NAME = "t8"

const T8_PACKAGE_STRING = "t8 1.2.0.37-a5c5-dirty"

const T8_PACKAGE_TARNAME = "t8"

const T8_PACKAGE_URL = ""

const T8_PACKAGE_VERSION = "1.2.0.37-a5c5-dirty"

const T8_STDC_HEADERS = 1

const T8_USING_AUTOCONF = 1

const T8_VERSION = "1.2.0.37-a5c5-dirty"

const T8_VERSION_MAJOR = 1

const T8_VERSION_MINOR = 2


const T8_WITH_NETCDF_PAR = 0

# Skipping MacroDefinition: T8_MPI_ECLASS_TYPE ( T8_ASSERT ( sizeof ( int ) == sizeof ( t8_eclass_t ) ) , sc_MPI_INT )

const T8_ECLASS_MAX_FACES = 6

const T8_ECLASS_MAX_EDGES = 12

const T8_ECLASS_MAX_EDGES_2D = 4

const T8_ECLASS_MAX_CORNERS_2D = 4

const T8_ECLASS_MAX_CORNERS = 8

const T8_ECLASS_MAX_DIM = 3

# Skipping MacroDefinition: T8_MPI_ELEMENT_SHAPE_TYPE ( T8_ASSERT ( sizeof ( int ) == sizeof ( t8_element_shape_t ) ) , sc_MPI_INT )

const T8_ELEMENT_SHAPE_MAX_FACES = 6

const T8_ELEMENT_SHAPE_MAX_CORNERS = 8


const T8_VTK_LOCIDX = "Int32"

const T8_VTK_GLOIDX = "Int32"

const T8_VTK_FLOAT_NAME = "Float32"

const T8_VTK_FLOAT_TYPE = Float32

const T8_VTK_ASCII = 1

const T8_VTK_FORMAT_STRING = "ascii"

const sc_mpi_read = sc_io_read

const sc_mpi_write = sc_io_write

const P4EST_BUILD_2D = 1

const P4EST_BUILD_3D = 1

const P4EST_BUILD_P6EST = 1

const P4EST_CC = "mpicc"

const P4EST_CFLAGS = "-O3"

const P4EST_CPP = "mpicc -E"

const P4EST_CPPFLAGS = "-I/workspace/destdir/include"

const P4EST_ENABLE_BUILD_2D = 1

const P4EST_ENABLE_BUILD_3D = 1

const P4EST_ENABLE_BUILD_P6EST = 1

const P4EST_ENABLE_MEMALIGN = 1

const P4EST_ENABLE_MPI = 1

const P4EST_ENABLE_MPICOMMSHARED = 1

const P4EST_ENABLE_MPIIO = 1

const P4EST_ENABLE_MPISHARED = 1

const P4EST_ENABLE_MPITHREAD = 1

const P4EST_ENABLE_MPIWINSHARED = 1

const P4EST_ENABLE_VTK_BINARY = 1

const P4EST_ENABLE_VTK_COMPRESSION = 1

const P4EST_HAVE_GNU_QSORT_R = 1

const P4EST_HAVE_MATH = 1

const P4EST_HAVE_POSIX_MEMALIGN = 1

const P4EST_HAVE_ZLIB = 1

const P4EST_LDFLAGS = "-L/workspace/destdir/lib"

const P4EST_LIBS = "-lz -lm "

const P4EST_LT_OBJDIR = ".libs/"

const P4EST_MEMALIGN = 1

const P4EST_SIZEOF_VOID_P = 8

const P4EST_MEMALIGN_BYTES = P4EST_SIZEOF_VOID_P

const P4EST_MPI = 1

const P4EST_MPIIO = 1

const P4EST_PACKAGE = "p4est"

const P4EST_PACKAGE_BUGREPORT = "p4est@ins.uni-bonn.de"

const P4EST_PACKAGE_NAME = "p4est"

const P4EST_PACKAGE_STRING = "p4est 2.8.5.58-35fd"

const P4EST_PACKAGE_TARNAME = "p4est"

const P4EST_PACKAGE_URL = ""

const P4EST_PACKAGE_VERSION = "2.8.5.58-35fd"

const P4EST_STDC_HEADERS = 1

const P4EST_USING_AUTOCONF = 1

const P4EST_VERSION = "2.8.5.58-35fd"

const P4EST_VERSION_MAJOR = 2

const P4EST_VERSION_MINOR = 8


const P4EST_VTK_BINARY = 1

const P4EST_VTK_COMPRESSION = 1

const p4est_qcoord_compare = sc_int32_compare

const P4EST_QCOORD_BITS = 32

const P4EST_MPI_QCOORD = sc_MPI_INT

const P4EST_VTK_QCOORD = "Int32"


const P4EST_QCOORD_MIN = INT32_MIN

const P4EST_QCOORD_MAX = INT32_MAX

const P4EST_QCOORD_1 = p4est_qcoord_t(1)

const p4est_topidx_compare = sc_int32_compare

const P4EST_TOPIDX_BITS = 32

const P4EST_MPI_TOPIDX = sc_MPI_INT

const P4EST_VTK_TOPIDX = "Int32"


const P4EST_TOPIDX_MIN = INT32_MIN

const P4EST_TOPIDX_MAX = INT32_MAX

const P4EST_TOPIDX_FITS_32 = 1

const P4EST_TOPIDX_1 = p4est_topidx_t(1)

const p4est_locidx_compare = sc_int32_compare

const P4EST_LOCIDX_BITS = 32

const P4EST_MPI_LOCIDX = sc_MPI_INT

const P4EST_VTK_LOCIDX = "Int32"


const P4EST_LOCIDX_MIN = INT32_MIN

const P4EST_LOCIDX_MAX = INT32_MAX

const P4EST_LOCIDX_1 = p4est_locidx_t(1)

const p4est_gloidx_compare = sc_int64_compare

const P4EST_GLOIDX_BITS = 64

const P4EST_MPI_GLOIDX = sc_MPI_LONG_LONG_INT

const P4EST_VTK_GLOIDX = "Int64"


const P4EST_GLOIDX_MIN = INT64_MIN

const P4EST_GLOIDX_MAX = INT64_MAX

const P4EST_GLOIDX_1 = p4est_gloidx_t(1)





const P4EST_DIM = 2

const P4EST_FACES = 2P4EST_DIM

const P4EST_CHILDREN = 4

const P4EST_HALF = P4EST_CHILDREN ÷ 2

const P4EST_INSUL = 9

const P4EST_FTRANSFORM = 9

const P4EST_STRING = "p4est"

const P4EST_ONDISK_FORMAT = 0x02000009

const P8EST_DIM = 3

const P8EST_FACES = 2P8EST_DIM

const P8EST_CHILDREN = 8

const P8EST_HALF = P8EST_CHILDREN ÷ 2

const P8EST_EDGES = 12

const P8EST_INSUL = 27

const P8EST_FTRANSFORM = 9

const P8EST_STRING = "p8est"

const P8EST_ONDISK_FORMAT = 0x03000009

const T8_CMESH_FORMAT = 0x0002

const T8_SHMEM_BEST_TYPE = SC_SHMEM_WINDOW



# exports
const PREFIXES = ["t8_", "T8_"]
for name in names(@__MODULE__; all=true), prefix in PREFIXES
    if startswith(string(name), prefix)
        @eval export $name
    end
end

end # module
