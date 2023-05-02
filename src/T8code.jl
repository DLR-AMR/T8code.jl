module T8code

using Reexport: @reexport


# We need to load the preference setting from here and not from `LibP4est.jl`
# since `@load_preference` looks into the module it is running from. Thus, we
# load all preferences here and access them from the `module LibP4est`.
using Preferences: @load_preference
const _PREFERENCE_LIBT8 = @load_preference("libt8", "t8code_jll")

# Include t8code bindings
include("Libt8.jl")
@reexport using .Libt8

# Include pointer wrapper
# include("pointerwrappers.jl")
# @reexport using .PointerWrappers: PointerWrapper

export @t8_adapt_callback
# export SC_ASSERT
# export P4_ASSERT
export @T8_ASSERT

# Higher-level API defined in t8code.jl
"""
    T8code.uses_mpi()

Is intended to return `true`` if the `p4est` library was compiled with MPI
enabled. Since P4est.jl currently only supports `p4est` with MPI enabled,
this may always return `true`.
"""
# uses_mpi() = isdefined(@__MODULE__, :T8_ENABLE_MPI)

"""
    P4est.version()

Returns the version of the underlying `p4est` library (*not* of P4est.jl).
"""
# version() = VersionNumber(p4est_version_major(), p4est_version_minor())

"""
    P4est.package_id()

Returns the value of the global variable `p4est_package_id` which can be used
to check whether `p4est` has been initialized.
"""
# package_id() = unsafe_load(cglobal((:p4est_package_id, LibP4est.libp4est), Cint))

"""
    P4est.init(log_handler, log_threshold)

Calls [`p4est_init`](@ref) if it has not already been called, otherwise do
nothing. Thus, `P4est.init` can safely be called multiple times.

To use the default log handler and suppress most output created by default by
`p4est`, call this function as
```julia
P4est.init(C_NULL, SC_LP_ERROR)
```
before calling other functions from `p4est`.
"""
# function init(log_handler, log_threshold)
#     if package_id() >= 0
#         return nothing
#     end
# 
#     p4est_init(log_handler, log_threshold)
# 
#     return nothing
# end
# 
# 
# function __init__()
#     version = P4est.version()
# 
#     if !(v"2.3" <= version < v"3-")
#         @warn "Detected version $(version) of `p4est`. Currently, we only support versions v2.x.y from v2.3.0 on. Not everything may work correctly."
#     end
# 
#     return nothing
# end

# typedef int         (*t8_forest_adapt_t) (t8_forest_t forest,
#                                           t8_forest_t forest_from,
#                                           t8_locidx_t which_tree,
#                                           t8_locidx_t lelement_id,
#                                           t8_eclass_scheme_c *ts,
#                                           const int is_family,
#                                           const int num_elements,
#                                           t8_element_t *elements[]);
macro t8_adapt_callback(callback)
  :( @cfunction($callback, Cint, (Ptr{Cvoid}, Ptr{Cvoid}, t8_locidx_t, t8_locidx_t, Ptr{Cvoid}, Cint, Cint, Ptr{Ptr{Cvoid}})) )
end

macro SC_ASSERT(q)
  :( $(esc(q)) ? nothing : throw(AssertionError($(string(q)))) )
end

macro P4EST_ASSERT(q)
  :( @SC_ASSERT($(esc(q)) ) )
end

macro T8_ASSERT(q)
  :( @SC_ASSERT($(esc(q)) ) )
end

end
