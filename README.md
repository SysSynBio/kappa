[Kappa](http://kappalanguage.org/) - The Kappa language for Systems Biology
================================

Basic information
---------------------------------------

Compiling kappa creates two biraries, simplx and complx. simplx is for simulation, complx is for static analysis. 


What you need to compile Kappa
---------------------------------------

* OCaml 3.09.2
[http://caml.inria.fr/download.en.html](OCaml download page)
* TK/lablTK (for the graphical interface)
* graphviz
[http://www.graphviz.org/](graphviz.org)


On Windows
---------------------------------------
You will also need Cygwin for make and gcc, FlexDll for linking, and ActiveTcl for the graphical interface.

[http://www.cygwin.com/](Cygwin)
* make sure you install gcc v. 3. You may need to rename c:/cygwin/bin/gcc-3.exe to c:/cygwin/bin/gcc.exe

[http://alain.frisch.fr/flexdll.html](FlexDll)

[http://www.activestate.com/activetcl/downloads](ActiveTcl)
* make sure to install version 8.4


How to compile Kappa
-----------------------------

In the main directory of the distribution (the one that this file is in), type
the following to make all versions of jQuery:

To compile the light version, which does not include the graphical interface (LablTK not required):

`make`

Or to include the graphical interface:

`make full`

Binaries are created in /bin.
To copy them into /usr/bin:

`make install`

If you do not have local root privileges, you may use the following: 
`make LOCAL_DIR="/home/bin" install_in_local`


