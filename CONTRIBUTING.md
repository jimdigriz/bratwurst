# Configuration Files

The project structure tries to follow [buildroot's project-specific customization](http://buildroot.uclibc.org/downloads/manual/manual.html#_project_specific_customization) recommendations with the only quirk that all the customisations live outside of buildroot in its parent directory.

When amending some configurations, to put a suitable file into `board` you should use the following methods.

## Buildroot

    make menuconfig
    make savedefconfig

## uClibc

There is no 'savedefconfig' for uClibc, so all we can do is copy it in:

    make uclibc-menuconfig
    cp buildroot/output/build/uclibc-0.9.33.2/.config board/qemu/mipsel/uclibc.config

## Busybox

There is no 'savedefconfig' for busybox, so all we can do is copy it in:

    make busybox-menuconfig
    cp buildroot/output/build/busybox-1.22.1/.config board/qemu/mipsel/busybox.config

## Linux

    make linux-menuconfig
    make linux-savedefconfig
    cp buildroot/output/build/linux-3.16.1/defconfig board/qemu/mipsel/linux.config
