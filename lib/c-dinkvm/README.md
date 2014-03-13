# `dinkvm`

Provides a lightweight command line interface for creating
reproducible virtual environments with enough functionality and
connectivity to be more than ready for casual experimentation, fast
testing, and reliable demonstrations.

## Installation:

To install, simply clone this repository.  Also download from
[http://www.knopper.net/](http://knopper.net/knoppix-mirrors/index-en.html)
a copy of KNOPPIX_V7.2.0DVD-2013-06-16-EN.iso and place it (or a
symbolic link to it) in a directory that is a parent of your local
copy of the repository.  All should be ready to go.  It may be
necessary to do setup of KVM, perhaps with `sudo modprobe kvm-intel`.

A statically compiled version of Qemu/KVM that is known to work with
`dinkvm` is included in the repository.  It is recommended to use
this, which `dinkvm` does by default.  If there are problems, delete
the qemu directory in the repository to use whatever KVM is installed
on the host.

## Quick Demo:

The purpose of the demo is to show booting, using, and removing a VM
from the command line, as well as host file access.

1. For convenience, just run the demo in the repository directory.

        cd {location of repository}

2. Boot a virtual machine and create a directory "myvm" that will be
used to refer to the virtual machine later.  This typically takes
about 30 seconds.  The -show parameter shows the vncviewer window,
which is not required for the demo, but give something to watch while
the VM is booting.  It can be closed anytime.

        ./dinkvm myvm -show
            
3. Put a file on the host to demonstrate host file access.

        cat >HelloWorld.java <<EOF
        public class HelloWorld {
            public static void main(String[] args) {
                System.out.println("Hello, World");
            }
        }
        EOF

4. Compile and run the java file from inside the VM. The directory "onhost" points to the directory one up from "myvm".

        ./dinkvm myvm ... javac onhost/HelloWorld.java
        ./dinkvm myvm ... java -cp onhost HelloWorld

5. Look for running virtual machine(s). Remove one or all.

        ./dinkvm -ls
        ./dinkvm -rm myvm  # remove one
        ## or 
        ./dinkvm -ls -rm   # remove all

## Help

Documentation is in progress.  For now, some help is currently available with:

        ./dinkvm --help
        ./dinkvm --help options

