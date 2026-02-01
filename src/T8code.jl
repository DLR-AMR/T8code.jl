module T8code

using MPI

using Reexport: @reexport
using Libdl: Libdl

using MPIPreferences: MPIPreferences
# We need to load the preference setting from here and not from `Libt8.jl`
# since `@load_preference` looks into the module it is running from. Thus, we
# load all preferences here and access them from the `module Libt8`.
using Preferences: @load_preference, set_preferences!, delete_preferences!
using UUIDs: UUID
const _PREFERENCE_LIBT8 = @load_preference("libt8", "t8code_jll")
const _PREFERENCE_LIBP4EST = @load_preference("libp4est", "t8code_jll")
const _PREFERENCE_LIBSC = @load_preference("libsc", "t8code_jll")

# Include t8code bindings
include("Libt8.jl")
@reexport using .Libt8

export @t8_adapt_callback
export @t8_replace_callback
export @t8_load_tree_data
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
this always returns `true`.
"""
uses_mpi() = true

"""
    T8code.version()

Returns the version of the underlying `t8code` library (*not* of T8code.jl).
"""
version() = VersionNumber(T8_VERSION_MAJOR, T8_VERSION_MINOR)

const T8CODE_UUID = UUID("d0cc0030-9a40-4274-8435-baadcfd54fa1")

"""
    T8Code.set_libraries_path!(path = nothing; force = true)

Set the paths of all three libraries `libt8`, `libp4est` and `libsc` by
specifying the directory `path`, where all of these libraries are located.
It is assumed that the libraries are called `libt8.so`, `libp4est.so` and
`libsc.so` (or with the file endings `.dll`, `.dylib` depending on the system).
"""
function set_libraries_path!(path = nothing; force = true)
    if isnothing(path)
        set_library_t8code!(force = force)
        set_library_p4est!(force = force)
        set_library_sc!(force = force)
    else
        set_library_t8code!(joinpath(path, "libt8." * Libdl.dlext), force = force)
        set_library_p4est!(joinpath(path, "libp4est." * Libdl.dlext), force = force)
        set_library_sc!(joinpath(path, "libsc." * Libdl.dlext), force = force)
    end
end

"""
    T8code.set_library_t8code!(path; force = true)

Set the `path` to a system-provided `t8code` installation. Restart the Julia session
after executing this function so that the changes take effect. Calling this
function is necessary when you want to use a system-provided `t8code`
installation.
"""
function set_library_t8code!(path = nothing; force = true)
    if isnothing(path)
        delete_preferences!(T8CODE_UUID, "libt8"; force = force)
    else
        isfile(path) || throw(ArgumentError("$path is not a file that exists."))
        set_preferences!(T8CODE_UUID, "libt8" => path, force = force)
    end
    @info "Please restart Julia and reload T8code.jl for the library changes to take effect"
end

"""
    T8code.path_t8code_library()

Return the path of the `t8code` library that is used, when a system-provided library
is configured via the preferences. Otherwise `t8code_jll` is returned, which means
that the default p4est version from t8code_jll.jl is used.
"""
path_t8code_library() = _PREFERENCE_LIBT8

"""
    T8code.set_library_p4est!(path; force = true)

Set the `path` to a system-provided `p4est` installation. Restart the Julia session
after executing this function so that the changes take effect. Calling this
function is necessary when you want to use a system-provided `t8code`
installation.
"""
function set_library_p4est!(path = nothing; force = true)
    if isnothing(path)
        delete_preferences!(T8CODE_UUID, "libp4est"; force = force)
    else
        isfile(path) || throw(ArgumentError("$path is not a file that exists."))
        set_preferences!(T8CODE_UUID, "libp4est" => path, force = force)
    end
    @info "Please restart Julia and reload T8code.jl for the library changes to take effect"
end

"""
    T8code.path_p4est_library()

Return the path of the `p4est` library that is used, when a system-provided library
is configured via the preferences. Otherwise `t8code_jll` is returned, which means
that the default p4est version from t8code_jll.jl is used.
"""
path_p4est_library() = _PREFERENCE_LIBP4EST

"""
    T8code.set_library_sc!(path; force = true)

Set the `path` to a system-provided `sc` installation. Restart the Julia session
after executing this function so that the changes take effect. Calling this
function is necessary, when you want to use a system-provided `t8code`
installation.
"""
function set_library_sc!(path = nothing; force = true)
    if isnothing(path)
        delete_preferences!(T8CODE_UUID, "libsc"; force = force)
    else
        isfile(path) || throw(ArgumentError("$path is not a file that exists."))
        set_preferences!(T8CODE_UUID, "libsc" => path, force = force)
    end
    @info "Please restart Julia and reload T8code.jl for the library changes to take effect"
end

"""
    T8code.path_sc_library()

Return the path of the `sc` library that is used, when a system-provided library
is configured via the preferences. Otherwise `t8code_jll` is returned, which means
that the default sc version from t8code_jll.jl is used.
"""
path_sc_library() = _PREFERENCE_LIBSC

"""
    T8code.preferences_set_correctly()

Returns `false` if a system-provided MPI installation is set via the MPIPreferences, but
not a system-provided `t8code` installation. In this case, T8code.jl is not usable.
"""
preferences_set_correctly() = !(_PREFERENCE_LIBT8 == "t8code_jll" &&
                                MPIPreferences.binary == "system")

"""
    ForestWrapper

Lightweight `t8_forest_t` pointer wrapper which helps to free
resources allocated by t8code in an orderly fashion.

When initialized with a t8code forest pointer the wrapper
registers itself with a t8code object tracker called `T8CODE_OBJECT_TRACKER`.

In serial mode the wrapper and in consequence the t8code forest
can be finalized immediately whenever Julia's garbage collector sees fit.

In (MPI) parallel mode the wrapper (and the t8code forest) is kept till the end
of the session or when finalized explicitly. At the end of the session (resp.
when the program shuts down) the object tracker finalizes all registered t8code
objects in sync with all MPI ranks. This is necessary since t8code internally
allocates MPI shared arrays.
"""
mutable struct ForestWrapper
    pointer::Ptr{t8_forest} # cpointer to t8code forest

    function ForestWrapper(pointer::Ptr{t8_forest})
        wrapper = new(pointer)

        # Compute a unique id from the ForestWrapper object.
        unique_id = UInt64(pointer_from_objref(wrapper))

        if MPI.Comm_size(MPI.Comm(t8_forest_get_mpicomm(pointer))) > 1
            # Make sure the unique id is identical for each MPI rank.
            unique_id = MPI.bcast(unique_id, MPI.Comm(t8_forest_get_mpicomm(pointer)))
        end

        finalizer(wrapper) do wrapper
            # When finalizing, `forest`, `scheme`, `cmesh`, and `geometry` are
            # also cleaned up from within `t8code`. The cleanup code for
            # `cmesh` does some MPI calls for deallocating shared memory
            # arrays. Due to garbage collection in Julia the order of shutdown
            # is not deterministic. Hence, deterministic finalization is necessary in
            # order to avoid MPI-related error output when closing the Julia
            # program/session.
            t8_forest_unref(Ref(wrapper.pointer))

            # Deregister from the object tracker.
            delete!(T8CODE_OBJECT_TRACKER, unique_id)
        end

        # Register the T8codeForestWrapper with the object tracker.
        T8CODE_OBJECT_TRACKER[unique_id] = wrapper

        return wrapper
    end
end

Base.pointer(fw::ForestWrapper) = fw.pointer
# This dispatched conversion allows to conveniently pass a ForestWrapper object
# to `t8_forest_...` calls.  The following link leads to a lengthy discussion
# about if this is a valid way to achieve this:
# https://discourse.julialang.org/t/how-to-use-ccall-cconvert-and-unsafe-convert-in-a-convenient-and-memory-safe-way/41932/18
Base.unsafe_convert(::Type{Ptr{t8_forest}}, fw::ForestWrapper) = fw.pointer

function clean_up()
    # Finalize all registered t8code objects before MPI shuts down.
    while length(T8CODE_OBJECT_TRACKER) > 0
        unique_id = first(T8CODE_OBJECT_TRACKER).first

        forest_wrapper = T8CODE_OBJECT_TRACKER[unique_id]

        # Make sure all MPI ranks finalize the same object.
        if MPI.Comm_size(MPI.Comm(t8_forest_get_mpicomm(forest_wrapper.pointer))) > 1
            unique_id = MPI.bcast(unique_id,
                                  MPI.Comm(t8_forest_get_mpicomm(forest_wrapper.pointer)))
        end

        # Finalize the object. The object deregisters itself from the
        # object tracker automatically.
        finalize(forest_wrapper)
    end
end

# Minimal reference tracker holding active t8code related objects
# created throughout the life time of a Julia session. t8code objects
# should remove themselves from the tracker when they get finalized.
if !@isdefined(T8CODE_OBJECT_TRACKER)
    T8CODE_OBJECT_TRACKER = Dict{UInt64, ForestWrapper}()
end

const T8_QUAD_MAXLEVEL = 30
const T8_HEX_MAXLEVEL = 19

# Macros from `t8code`
const t8_quad_root_len = 1 << T8_QUAD_MAXLEVEL
const t8_hex_root_len = 1 << T8_HEX_MAXLEVEL
@inline t8_quad_len(l) = 1 << (T8_QUAD_MAXLEVEL - l)
@inline t8_hex_len(l) = 1 << (T8_HEX_MAXLEVEL - l)

macro T8_ASSERT(q)
    :($(esc(q)) ? nothing : throw(AssertionError($(string(q)))))
end

function t8_free(ptr)
    Libt8.sc_free(t8_get_package_id(), ptr)
end

# typedef int (*t8_forest_adapt_t) (t8_forest_t forest,
#                                   t8_forest_t forest_from,
#                                   t8_locidx_t which_tree,
#                                   const t8_eclass_t tree_class,
#                                   t8_locidx_t lelement_id,
#                                   const t8_scheme_c *scheme,
#                                   const int is_family,
#                                   const int num_elements,
#                                   t8_element_t *elements[]);
"""
    @t8_adapt_callback(callback)

Wrap the Julia function `callback` in an `@cfunction` with the appropriate
signature required for callback functions in [`t8_forest_adapt`](@ref).
"""
macro t8_adapt_callback(callback)
    :(@cfunction($callback, Cint,
                 (Ptr{t8_forest}, Ptr{t8_forest}, t8_locidx_t, t8_eclass_t, t8_locidx_t,
                  Ptr{t8_scheme}, Cint, Cint, Ptr{Ptr{t8_element}})))
end

# typedef void        (*t8_forest_replace_t) (t8_forest_t forest_old,
#                                             t8_forest_t forest_new,
#                                             t8_locidx_t which_tree,
#                                             t8_eclass_scheme_c *ts,
#                                             int refine, int num_outgoing,
#                                             t8_locidx_t first_outgoing,
#                                             int num_incoming,
#                                             t8_locidx_t first_incoming);
"""
    @t8_replace_callback(callback)

Wrap the Julia function `callback` in an `@cfunction` with the appropriate
signature required for callback functions in [`t8_forest_iterate_replace`](@ref).
"""
macro t8_replace_callback(callback)
    :(@cfunction($callback, Cvoid,
                 (Ptr{Cvoid}, Ptr{Cvoid}, t8_locidx_t, Ptr{Cvoid}, Cint, Cint, t8_locidx_t,
                  Cint, t8_locidx_t)))
end

# typedef void (*t8_geom_load_tree_data_fn) (t8_cmesh_t cmesh,
#                                            t8_gloidx_t gtreeid,
#                                            const void **tree_data);
"""
    @t8_load_tree_data(callback)

Wrap the Julia function `callback` in an `@cfunction` with the appropriate
signature required for callback functions in [`t8_geom_load_tree_data_fn`](@ref).
"""
macro t8_load_tree_data(callback)
    :(@cfunction($callback, Cvoid,
                 (t8_cmesh_t, t8_gloidx_t, Ptr{Cvoid})))
end

function __init__()
    if !preferences_set_correctly()
        @warn "System MPI version detected, but not a system t8code version. To make T8code.jl work, you need to set the preferences, see https://github.com/DLR-AMR/T8code.jl#using-a-custom-version-of-mpi-andor-t8code."
    end
end

# Following functions are not part of the official public API of t8code but are
# needed nevertheless by some application codes. This will be fixed resp. more
# streamlined in future releases of t8code.

export t8_forest_ghost_get_remotes
function t8_forest_ghost_get_remotes(forest)
    num_remotes_ref = Ref{Cint}()
    remotes_ptr = @ccall T8code.Libt8.libt8.t8_forest_ghost_get_remotes(forest::t8_forest_t,
                                                                        num_remotes_ref::Ptr{Cint})::Ptr{Cint}
    remotes = unsafe_wrap(Array, remotes_ptr, num_remotes_ref[])
end

export t8_forest_ghost_remote_first_elem
function t8_forest_ghost_remote_first_elem(forest, remote)
    @ccall T8code.Libt8.libt8.t8_forest_ghost_remote_first_elem(forest::t8_forest_t,
                                                                remote::Cint)::t8_locidx_t
end

export t8_forest_ghost_num_trees
function t8_forest_ghost_num_trees(forest)
    @ccall T8code.Libt8.libt8.t8_forest_ghost_num_trees(forest::t8_forest_t)::t8_locidx_t
end

export t8_forest_ghost_get_tree_element_offset
function t8_forest_ghost_get_tree_element_offset(forest, lghost_tree)
    @ccall T8code.Libt8.libt8.t8_forest_ghost_get_tree_element_offset(forest::t8_forest_t,
                                                                      lghost_tree::t8_locidx_t)::t8_locidx_t
end

export t8_forest_ghost_get_global_treeid
function t8_forest_ghost_get_global_treeid(forest, lghost_tree)
    @ccall T8code.Libt8.libt8.t8_forest_ghost_get_global_treeid(forest::t8_forest_t,
                                                                lghost_tree::t8_locidx_t)::t8_gloidx_t
end

end
