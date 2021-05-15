# prevent infinite recursion when spack shells out (e.g., on cray for modules)
if ($?_st_sp_initializing) then
    exit 0
endif
setenv _st_sp_initializing true

# If _STAR_SPACK_ROOT is not set, we'll try to find it ourselves.
# csh/tcsh don't have a built-in way to do this, but both keep files
# they are sourcing open. We use /proc on linux and lsof on macs to
# find this script's full path in the current process's open files.
if (! $?_STAR_SPACK_ROOT) then
    # figure out a command to list open files
    if (-d /proc/$$/fd) then
        set _sp_lsof = "ls -l /proc/$$/fd"
    else
        which lsof > /dev/null
        if ($? == 0) then
            set _sp_lsof = "lsof -p $$"
        endif
    endif

    # filter this script out of list of open files
    if ( $?_sp_lsof ) then
        set _sp_source_file = `$_sp_lsof | sed -e 's/^[^/]*//' | grep "/setup.csh"`
    endif

    # This script is in $_STAR_SPACK_ROOT/share/spack; get the root with dirname
    if ($?_sp_source_file) then
        setenv _STAR_SPACK_ROOT `dirname "$_sp_source_file"`
    endif

    if (! $?_STAR_SPACK_ROOT) then
        echo "==> Error: setup-env.csh couldn't figure out where spack lives."
        echo "    Set _STAR_SPACK_ROOT to the root of your spack installation and try again."
        exit 1
    endif
endif

source "${_STAR_SPACK_ROOT}/spack/share/spack/setup-env.csh"

# Check whether STAR repo is known to the user environment and if not, add STAR repo
set _st_sp_repo_line=`spack repo list | grep '^star.*'$_STAR_SPACK_ROOT'$' | rev | cut -d' ' -f1 | rev`

if ( "$_st_sp_repo_line" == "" ) then
    spack repo add $_STAR_SPACK_ROOT
endif

# Update MODULEPATH
foreach tcl_root ($tcl_roots:q)
    foreach systype ($compatible_sys_types:q)
        if ( $systype =~ '*x86_64*' ) then
            set systype_add = `echo $systype | sed 's/x86_64/x86/g'`
            _spack_pathadd MODULEPATH "$tcl_root/$systype_add"
        endif
    end
end

# done: unset sentinel variable as we're no longer initializing
unsetenv _st_sp_initializing
