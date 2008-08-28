# generated by ./configure -host x86_64-apple-darwin
if [ "x$PREFIX" = "x" ]; then PREFIX="/usr/local"; fi
if [ "x$BINDIR" = "x" ]; then BINDIR="${PREFIX}/bin"; fi
if [ "x$LIBDIR" = "x" ]; then LIBDIR="${PREFIX}/lib/ocaml"; fi
if [ "x$STUBLIBDIR" = "x" ]; then STUBLIBDIR="${LIBDIR}/stublibs"; fi
if [ "x$MANDIR" = "x" ]; then MANDIR="${PREFIX}/man"; fi
if [ "x$MANEXT" = "x" ]; then MANEXT="1"; fi
if [ "x$RANLIB" = "x" ]; then RANLIB="ranlib"; fi
if [ "x$RANLIBCMD" = "x" ]; then RANLIBCMD="ranlib"; fi
if [ "x$SHARPBANGSCRIPTS" = "x" ]; then SHARPBANGSCRIPTS="true"; fi
if [ "x$BNG_ARCH" = "x" ]; then BNG_ARCH="amd64"; fi
if [ "x$BNG_ASM_LEVEL" = "x" ]; then BNG_ASM_LEVEL="1"; fi
if [ "x$PTHREAD_LINK" = "x" ]; then PTHREAD_LINK="-cclib -lpthread"; fi
if [ "x$X11_INCLUDES" = "x" ]; then X11_INCLUDES="-I/usr/X11R6/include"; fi
if [ "x$X11_LINK" = "x" ]; then X11_LINK="-L/usr/X11R6/lib -lX11"; fi
if [ "x$DBM_INCLUDES" = "x" ]; then DBM_INCLUDES=""; fi
if [ "x$DBM_LINK" = "x" ]; then DBM_LINK=""; fi
if [ "x$TK_DEFS" = "x" ]; then TK_DEFS=""; fi
if [ "x$TK_LINK" = "x" ]; then TK_LINK=""; fi
if [ "x$BYTECC" = "x" ]; then BYTECC="gcc -arch x86_64"; fi
if [ "x$BYTECCCOMPOPTS" = "x" ]; then BYTECCCOMPOPTS=" -fno-defer-pop -no-cpp-precomp -Wall -D_FILE_OFFSET_BITS=64 -D_REENTRANT"; fi
if [ "x$BYTECCLINKOPTS" = "x" ]; then BYTECCLINKOPTS=""; fi
if [ "x$BYTECCLIBS" = "x" ]; then BYTECCLIBS=" -lm  -lcurses -lpthread"; fi
if [ "x$BYTECCRPATH" = "x" ]; then BYTECCRPATH=""; fi
if [ "x$EXE" = "x" ]; then EXE=""; fi
if [ "x$SUPPORTS_SHARED_LIBRARIES" = "x" ]; then SUPPORTS_SHARED_LIBRARIES="true"; fi
if [ "x$SHAREDCCCOMPOPTS" = "x" ]; then SHAREDCCCOMPOPTS=""; fi
if [ "x$MKSHAREDLIBRPATH" = "x" ]; then MKSHAREDLIBRPATH=""; fi
# SYSLIB=-l${1}
#ml let syslib x = "-l"^x;;

# MKEXE=${BYTECC} -o ${1} ${2}
#ml let mkexe out files opts = Printf.sprintf "%s -o %s %s %s" bytecc out opts files;;

### How to build a DLL
# MKDLL=gcc -arch x86_64 -bundle -flat_namespace -undefined suppress -o ${1} ${3}
#ml let mkdll out _implib files opts = Printf.sprintf "%s %s %s %s" "gcc -arch x86_64 -bundle -flat_namespace -undefined suppress -o" out opts files;;

### How to build a static library
# MKLIB=ar rc ${1} ${2}; ranlib ${1}
#ml let mklib out files opts = Printf.sprintf "ar rc %s %s %s; ranlib %s" out opts files out;;
if [ "x$ARCH" = "x" ]; then ARCH="amd64"; fi
if [ "x$MODEL" = "x" ]; then MODEL="default"; fi
if [ "x$SYSTEM" = "x" ]; then SYSTEM="macosx"; fi
if [ "x$NATIVECC" = "x" ]; then NATIVECC="gcc -arch x86_64"; fi
if [ "x$NATIVECCCOMPOPTS" = "x" ]; then NATIVECCCOMPOPTS=" -D_FILE_OFFSET_BITS=64 -D_REENTRANT"; fi
if [ "x$NATIVECCPROFOPTS" = "x" ]; then NATIVECCPROFOPTS=" -D_FILE_OFFSET_BITS=64 -D_REENTRANT"; fi
if [ "x$NATIVECCLINKOPTS" = "x" ]; then NATIVECCLINKOPTS=""; fi
if [ "x$NATIVECCRPATH" = "x" ]; then NATIVECCRPATH=""; fi
if [ "x$NATIVECCLIBS" = "x" ]; then NATIVECCLIBS=" -lm "; fi
if [ "x$ASFLAGS" = "x" ]; then ASFLAGS=""; fi
if [ "x$ASPP" = "x" ]; then ASPP="gcc"; fi
if [ "x$ASPPFLAGS" = "x" ]; then ASPPFLAGS="-c -arch x86_64 -DSYS_${SYSTEM}"; fi
if [ "x$ASPPPROFFLAGS" = "x" ]; then ASPPPROFFLAGS="-DPROFILING"; fi
if [ "x$PROFILING" = "x" ]; then PROFILING="prof"; fi
if [ "x$DYNLINKOPTS" = "x" ]; then DYNLINKOPTS=""; fi
if [ "x$OTHERLIBRARIES" = "x" ]; then OTHERLIBRARIES="unix str num dynlink bigarray systhreads threads graph dbm"; fi
if [ "x$DEBUGGER" = "x" ]; then DEBUGGER="ocamldebugger"; fi
if [ "x$CC_PROFILE" = "x" ]; then CC_PROFILE="-pg"; fi
if [ "x$SYSTHREAD_SUPPORT" = "x" ]; then SYSTHREAD_SUPPORT="true"; fi
if [ "x$PARTIALLD" = "x" ]; then PARTIALLD="ld -r -arch x86_64"; fi
if [ "x$DLLCCCOMPOPTS" = "x" ]; then DLLCCCOMPOPTS=""; fi
if [ "x$O" = "x" ]; then O="o"; fi
if [ "x$A" = "x" ]; then A="a"; fi
if [ "x$EXT_OBJ" = "x" ]; then EXT_OBJ=".o"; fi
if [ "x$EXT_ASM" = "x" ]; then EXT_ASM=".s"; fi
if [ "x$EXT_LIB" = "x" ]; then EXT_LIB=".a"; fi
if [ "x$EXT_DLL" = "x" ]; then EXT_DLL=".so"; fi
if [ "x$EXTRALIBS" = "x" ]; then EXTRALIBS=""; fi
if [ "x$CCOMPTYPE" = "x" ]; then CCOMPTYPE="cc"; fi
if [ "x$TOOLCHAIN" = "x" ]; then TOOLCHAIN="cc"; fi