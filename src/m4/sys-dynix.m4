dnl Copyright (C) 1993-2002 Free Software Foundation, Inc.
dnl This file is free software, distributed under the terms of the GNU
dnl General Public License.  As a special exception to the GNU General
dnl Public License, this file may be distributed as part of a program
dnl that contains a configuration script generated by Autoconf, under
dnl the same distribution terms as the rest of that program.

dnl From Bruno Haible, Marcus Daniels.

AC_PREREQ(2.13)

AC_DEFUN([CL_DYNIX_SEQ],
[AC_CACHE_CHECK(for DYNIX/ptx libseq or libsocket, cl_cv_lib_sequent, [
AC_EGREP_CPP(yes,
[#if defined(_SEQUENT_)
  yes
#endif
], cl_cv_lib_sequent=yes, cl_cv_lib_sequent=no)
])
if test $cl_cv_lib_sequent = yes; then
AC_CHECK_LIB(seq,main,LIBS="$LIBS -lseq")
dnl libsocket is needed for select()
AC_CHECK_LIB(socket,main,LIBS="$LIBS -lsocket")
fi
])
