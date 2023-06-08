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

export @t8_adapt_callback
export @T8_ASSERT
export t8_free

export t8_quad_root_len
export t8_quad_len

export t8_hex_root_len
export t8_hex_len

"""
    T8code.uses_mpi()

Is intended to return `true`` if the `t8code` library was compiled with MPI
enabled. Since T8code.jl currently only supports `t8code` with MPI enabled,
this may always return `true`.
"""
uses_mpi() = T8_ENABLE_MPI == 1

"""
    T8code.version()

Returns the version of the underlying `t8code` library (*not* of T8code.jl).
"""
version() = VersionNumber(T8_VERSION_MAJOR, T8_VERSION_MINOR)

const T8_QUAD_MAXLEVEL = 30
const T8_HEX_MAXLEVEL = 19

# Macros from `t8code`
const t8_quad_root_len = 1 << T8_QUAD_MAXLEVEL
const t8_hex_root_len = 1 << T8_HEX_MAXLEVEL
@inline t8_quad_len(l) = 1 << (T8_QUAD_MAXLEVEL - l)
@inline t8_hex_len(l) = 1 << (T8_HEX_MAXLEVEL - l)

macro T8_ASSERT(q)
  :( $(esc(q)) ? nothing : throw(AssertionError($(string(q)))) )
end

function t8_free(ptr)
  sc_free(t8_get_package_id(), ptr)
end

# typedef int         (*t8_forest_adapt_t) (t8_forest_t forest,
#                                           t8_forest_t forest_from,
#                                           t8_locidx_t which_tree,
#                                           t8_locidx_t lelement_id,
#                                           t8_eclass_scheme_c *ts,
#                                           const int is_family,
#                                           const int num_elements,
#                                           t8_element_t *elements[]);
macro t8_adapt_callback(callback)
  :( @cfunction($callback, Cint, (Ptr{t8_forest}, Ptr{t8_forest}, t8_locidx_t, t8_locidx_t, Ptr{t8_eclass_scheme}, Cint, Cint, Ptr{Ptr{t8_element}})) )
end

# typedef void        (*t8_forest_replace_t) (t8_forest_t forest_old,
#                                             t8_forest_t forest_new,
#                                             t8_locidx_t which_tree,
#                                             t8_eclass_scheme_c *ts,
#                                             int refine, int num_outgoing,
#                                             t8_locidx_t first_outgoing,
#                                             int num_incoming,
#                                             t8_locidx_t first_incoming);
macro t8_replace_callback(callback)
  :( @cfunction($callback, Cvoid, (Ptr{Cvoid}, Ptr{Cvoid}, t8_locidx_t, Ptr{Cvoid}, Cint, Cint, t8_locidx_t, Cint, t8_locidx_t)) )
end

end
