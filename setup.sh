# Source this script to set up a spack repository for STAR
#
# Parts of the scripts are borrowed from the original spack repository.
# See spack/share/spack/setup-env.sh

# prevent infinite recursion when spack shells out (e.g., on cray for modules)
if [ -n "${_st_sp_initializing:-}" ]; then
    exit 0
fi
export _st_sp_initializing=true


# Determine which shell is being used
_spack_determine_shell() {
    if [ -f "/proc/$$/exe" ]; then
        # If procfs is present this seems a more reliable
        # way to detect the current shell
        _sp_exe=$(readlink /proc/$$/exe)
        # Shell may contain number, like zsh5 instead of zsh
        basename ${_sp_exe} | tr -d '0123456789'
    elif [ -n "${BASH:-}" ]; then
        echo bash
    elif [ -n "${ZSH_NAME:-}" ]; then
        echo zsh
    else
        PS_FORMAT= ps -p $$ | tail -n 1 | awk '{print $4}' | sed 's/^-//' | xargs basename
    fi
}
_sp_shell=$(_spack_determine_shell)

#
# Figure out where this file is.
#
if [ "$_sp_shell" = bash ]; then
    _sp_source_file="${BASH_SOURCE[0]:-}"
elif [ "$_sp_shell" = zsh ]; then
    _sp_source_file="${(%):-%N}"
else
    # Try to read the /proc filesystem (works on linux without lsof)
    # In dash, the sourced file is the last one opened (and it's kept open)
    _sp_source_file_fd="$(\ls /proc/$$/fd 2>/dev/null | sort -n | tail -1)"
    if ! _sp_source_file="$(readlink /proc/$$/fd/$_sp_source_file_fd)"; then
        # Last resort: try lsof. This works in dash on macos -- same reason.
        # macos has lsof installed by default; some linux containers don't.
        _sp_lsof_output="$(lsof -p $$ -Fn0 | tail -1)"
        _sp_source_file="${_sp_lsof_output#*n}"
    fi

    # If we can't find this script's path after all that, bail out with
    # plain old $0, which WILL NOT work if this is sourced indirectly.
    if [ ! -f "$_sp_source_file" ]; then
        _sp_source_file="$0"
    fi
fi

#
# Find root directory
#
# We send cd output to /dev/null to avoid because a lot of users set up
# their shell so that cd prints things out to the tty.
_STAR_SPACK_ROOT="$(cd "$(dirname $_sp_source_file)" > /dev/null && pwd)"

source "$_STAR_SPACK_ROOT/spack/share/spack/setup-env.sh"

_st_sp_repo_found=false
_st_sp_repo_pattern='^star(.*)'$_STAR_SPACK_ROOT'$'

while read -r myeee ; do
    if [[ "$myeee" =~ $_st_sp_repo_pattern ]]; 
    then 
        _st_sp_repo_found=true
    fi
done < <(spack repo list)

if [ "$_st_sp_repo_found" = false ]; then spack repo add "$_STAR_SPACK_ROOT"; fi

# done: unset sentinel variable as we're no longer initializing
unset _st_sp_initializing
export _st_sp_initializing
