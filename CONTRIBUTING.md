# Configuration Files

The project structure tries to follow [buildroot's project-specific customisation](http://buildroot.uclibc.org/downloads/manual/manual.html#_project_specific_customization) recommendations with the only quirk that they all live outside of buildroot in its parent directory.

When amending some configurations, to put a suitable file into `board` you should use the following methods.

 * Buildroot:

        make menuconfig
        make savedefconfig

 * uClibc, Busybox, Linux:

        make {uclibc,busybox,linux}-menuconfig
        make {uclibc,busybox,linux}-update-config 
