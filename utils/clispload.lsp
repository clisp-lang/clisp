;; Load the ansi-tests testsuite into CLISP in *ANSI* mode.
;; Usage:
;;   $ cd ansi-tests
;;   $ clisp -q -ansi -i clispload.lsp

;; First the infrastructure.
(load "gclload1.lsp")

;; Set *package*.
(in-package :cl-test)

;; for ENSURE-DIRECTORIES-EXIST.8
(when (ext:probe-directory "scratch/")
  (mapc #'delete-file (directory "scratch/*"))
  (ext:delete-dir "scratch/"))

;; The expected failures.
(setq regression-test::*expected-failures* '(

  ;; ANSI CL 11.1.2. says that the only nickname of the COMMON-LISP package
  ;; is "CL". In CLISP it also has the nickname "LISP", for backward
  ;; compatibility with older programs.
  COMMON-LISP-PACKAGE-NICKNAMES

  ;; ANSI CL 11.1.2. says that the only nickname of the COMMON-LISP-USER
  ;; package is "CL-USER". In CLISP it also has the nickname "USER", for
  ;; backward compatibility with older programs.
  COMMON-LISP-USER-PACKAGE-NICKNAMES

  ;; The symbols
  ;;   LEAST-NEGATIVE-LONG-FLOAT LEAST-NEGATIVE-NORMALIZED-LONG-FLOAT
  ;;   LEAST-POSITIVE-LONG-FLOAT LEAST-POSITIVE-NORMALIZED-LONG-FLOAT
  ;;   LONG-FLOAT-EPSILON LONG-FLOAT-NEGATIVE-EPSILON MOST-NEGATIVE-LONG-FLOAT
  ;;   MOST-POSITIVE-LONG-FLOAT PI
  ;; are variables, not constants, in CLISP, because the long-float precision
  ;; can be changed at run-time, and the values of these symbols change
  ;; accordingly.
  CL-CONSTANT-SYMBOLS.1
  CONSTANTP.10

  ;; Paul Dietz assumes that the qualifiers of methods are checked only
  ;; at run time, when the effective method is determined.
  ;; I argue that the description of DEFMETHOD allows qualifier checking to
  ;; occur already at method definition time.
  DEFGENERIC-METHOD-COMBINATION.+.10
  DEFGENERIC-METHOD-COMBINATION.+.11
  DEFGENERIC-METHOD-COMBINATION.APPEND.10
  DEFGENERIC-METHOD-COMBINATION.APPEND.11
  DEFGENERIC-METHOD-COMBINATION.APPEND.13
  DEFGENERIC-METHOD-COMBINATION.NCONC.10
  DEFGENERIC-METHOD-COMBINATION.NCONC.11
  DEFGENERIC-METHOD-COMBINATION.LIST.10
  DEFGENERIC-METHOD-COMBINATION.LIST.11
  DEFGENERIC-METHOD-COMBINATION.MAX.10
  DEFGENERIC-METHOD-COMBINATION.MAX.11
  DEFGENERIC-METHOD-COMBINATION.MIN.10
  DEFGENERIC-METHOD-COMBINATION.MIN.11
  DEFGENERIC-METHOD-COMBINATION.AND.10
  DEFGENERIC-METHOD-COMBINATION.AND.11
  DEFGENERIC-METHOD-COMBINATION.OR.10
  DEFGENERIC-METHOD-COMBINATION.OR.11
  DEFGENERIC-METHOD-COMBINATION.PROGN.10
  DEFGENERIC-METHOD-COMBINATION.PROGN.11

  ;; Paul Dietz assumes that the HASH-TABLE-TEST function returns the
  ;; EQ/EQL/EQUAL/EQUALP symbol.
  ;; In CLISP, #'EQ has several function designators: EQ, EXT:FASTHASH-EQ,
  ;; EXT:STABLEHASH-EQ, and the HASH-TABLE-TEST function returns one of
  ;; them, arbitrarily.
  HASH-TABLE-TEST.1 HASH-TABLE-TEST.2 HASH-TABLE-TEST.3 HASH-TABLE-TEST.4

  ;; Paul Dietz assumes that any range of floating-point number can be
  ;; converted to integer, i.e. that the exponent range of integers is
  ;; bigger than the exponent range of all kinds of floating-point numbers.
  ;; In CLISP, the range of long-float exponents is bigger than the range
  ;; of integer exponents (ca. 2^31 versus 2^21).
  ;; None of these approaches is perfect: Either you cannot assume that
  ;; conversion from integer to floating-point always works, or you cannot
  ;; assume that conversion from floating-point to integer always works.
  BIGNUM.FLOAT.COMPARE.1A BIGNUM.FLOAT.COMPARE.1B BIGNUM.FLOAT.COMPARE.2A
  BIGNUM.FLOAT.COMPARE.2B BIGNUM.FLOAT.COMPARE.3A BIGNUM.FLOAT.COMPARE.3B
  BIGNUM.FLOAT.COMPARE.4A BIGNUM.FLOAT.COMPARE.4B BIGNUM.FLOAT.COMPARE.5A
  BIGNUM.FLOAT.COMPARE.5B BIGNUM.FLOAT.COMPARE.6A BIGNUM.FLOAT.COMPARE.6B
  BIGNUM.FLOAT.COMPARE.7 BIGNUM.FLOAT.COMPARE.8

  ;; In CLISP (atan 1L0) is more than long-float-epsilon apart from (/ pi 4).
  ATAN.11 ATAN.13

  ;; In CLISP rounding errors cause (let ((c #C(97748.0s0 0.0s0))) (/ c c))
  ;; to be different from #C(1.0s0 0.0s0).
  /.8

  ;; CLISP supports complex numbers with realpart and imagpart of different
  ;; type.
  COMPLEX.2 COMPLEX.4 COMPLEX.5 IMAGPART.4

  ;; Paul Dietz assumes that the classes STREAM and CONDITION are disjoint.
  ;; In CLISP they are not, because the user can create subclasses inheriting
  ;; from FUNDAMENTAL-STREAM and any other class with metaclass STANDARD-CLASS.
  ;; ANSI CL 4.2.2.(1) allows such classes.
  TYPES.7B TYPES.7C

  ;; Paul Dietz assumes that the class STREAM is disjoint from user-defined
  ;; classes with metaclass STANDARD-CLASS.
  ;; In CLISP this is not the case, because the user can create subclasses
  ;; inheriting from FUNDAMENTAL-STREAM and any other class with metaclass
  ;; STANDARD-CLASS. ANSI CL 4.2.2. allows such classes.
  USER-CLASS-DISJOINTNESS

  ;; Paul Dietz assumes that two user-defined classes with metaclass
  ;; STANDARD-CLASS that don't inherit from each other are disjoint.
  ;; In CLISP this is not the case, because the user can create subclasses
  ;; inheriting from both classes. ANSI CL 4.2.2.(3) allows such classes.
  ;; We don't want SUBTYPEP to depend on the existence or absence of
  ;; subclasses.
  USER-CLASS-DISJOINTNESS-2 TAC-3.16

  ;; Paul Dietz assumes that HOST-NAMESTRING's first value is always a string.
  ;; In CLISP, on Unix, HOST-NAMESTRING always returns NIL.
  HOST-NAMESTRING.1 HOST-NAMESTRING.2

  ;; Paul Dietz assumes that (PARSE-NAMESTRING "") returns a pathname with
  ;; directory NIL.
  ;; In CLISP the resulting directory is (:RELATIVE).
  PARSE-NAMESTRING.1 PARSE-NAMESTRING.2 PARSE-NAMESTRING.3 PARSE-NAMESTRING.4

  ;; Broken test.
  PRINT-UNREADABLE-OBJECT.2

  ;; Paul Dietz assumes that binding *PRINT-READABLY* to T has no effect on
  ;; how integers are printed.
  ;; In CLISP *PRINT-READABLY* = T implies the effects of *PRINT-RADIX* = T.
  WRITE.2 WRITE.3 WRITE.4 WRITE.5 WRITE.6 WRITE.7 PRINT.2 PRINT.3 PPRINT.2
  PPRINT.3 PRIN1.2 PRIN1.3 WRITE-TO-STRING.2 WRITE-TO-STRING.3
  WRITE-TO-STRING.4 PRIN1-TO-STRING.2

  ;; Paul Dietz assumes that the printed representation of unreadable objects
  ;; stays the same over time.
  ;; CLISP shows object identity through the memory address, which can vary
  ;; over time. Thus in RANDOM-PRINT-TEST, we can have
  ;;   S1 = "((common-lisp:most-positive-fixnum . #\\=) #<array common-lisp:t (11) #x20B62A7E> . #<array common-lisp:t (11) #x208A68FE>)"
  ;;   S2 = "((common-lisp:most-positive-fixnum . #\\=) #<array common-lisp:t (11) #x208A67EE> . #<array common-lisp:t (11) #x208A68FE>)"
  PRINT.1 PPRINT.1 WRITE-TO-STRING.1

  ;; Paul Dietz assumes that structure objects are printed like atoms.
  ;; CLISP prints them as objects with components, like vectors.
  PRINT-LEVEL.8 PRINT-LEVEL.9

  ;; Paul Dietz assumes a superficial interpretation of *PRINT-LENGTH* in the
  ;; context of printing structure objects.
  ;; CLISP has a structural interpretation of *PRINT-LENGTH*.
  PRINT-LENGTH.11

  ;; Paul Dietz assumes that FORMAT ~F works like WRITE.
  ;; CLISP prints 23346.8s0 (exact value is 23346.75) with ~F to "23346.7"
  ;; and with WRITE to "23346.8s0" (round-to-even). ANSI CL 22.3.3.1 permits
  ;; this: "When rounding up and rounding down would produce printed values
  ;; equidistant from the scaled value of arg, then the implementation is free
  ;; to use either one."
  FORMAT.F.2 FORMAT.F.3

  ;; Paul Dietz assumes that FORMAT ~S prints characters like FORMAT ~:C.
  ;; CLISP behaviour for graphic characters with non-standardized names is,
  ;; however, that FORMAT ~S uses the character's name, whereas FORMAT ~:C
  ;; doesn't.
  ;;   (format nil "~S" #\euro_sign)  => "#\\EURO_SIGN"
  ;;   (format nil "~:C" #\euro_sign) => "€"
  ;; ANSI CL 22.3.4.2, 22.1.3.2 and 22.3.1.1 allow this.
  FORMAT.S.8

  ;; Paul Dietz assumes that FORMAT ~10:T does nothing if the stream is not
  ;; a pretty-printing stream.
  ;; CLISP honors the FORMAT ~10:T even when the stream is a string-stream.
  |FORMAT.:T.1| |FORMAT.:T.2| |FORMAT.:T.3|

  ;; Paul Dietz assumes that the FORMAT ~< minpad parameter applies only
  ;; to the gaps between segments, not to the gap before the first or after
  ;; the last segment.
  ;; CLISP treats all gap types equally.
  FORMAT.JUSTIFY.8

  ; To be fixed:
  NAMESTRING.3 NAMESTRING.4 PATHNAME-MATCH-P.4
  PARSE-NAMESTRING.4 ; only the second value can be fixed
  DIRECTORY.6 DIRECTORY.7
  PPRINT-TABULAR.6

  ; Requires a rewrite of parts of the pretty-printer.
  PPRINT-TABULAR.7 PPRINT-TABULAR.8 PPRINT-TABULAR.9 PPRINT-TABULAR.10
  PPRINT-TABULAR.11 PPRINT-TABULAR.12 PPRINT-TABULAR.13 PPRINT-TABULAR.14
  PPRINT-TABULAR.15 PPRINT-TABULAR.16 PPRINT-TABULAR.17 PPRINT-TABULAR.18
  PPRINT-TABULAR.19 PPRINT-TABULAR.20 PPRINT-TABULAR.21 PPRINT-TABULAR.22
  PPRINT-TABULAR.24 PPRINT-INDENT.9 PPRINT-INDENT.10 PPRINT-INDENT.19
  PPRINT-INDENT.21 PPRINT-INDENT.22 PPRINT-INDENT.23
  PPRINT-LOGICAL-BLOCK.ERROR.1 PPRINT-LOGICAL-BLOCK.ERROR.1-UNSAFE
  PPRINT-LOGICAL-BLOCK.ERROR.2 PPRINT-LOGICAL-BLOCK.ERROR.2-UNSAFE
  PPRINT-LOGICAL-BLOCK.ERROR.3 PPRINT-LOGICAL-BLOCK.ERROR.3-UNSAFE
  PPRINT-POP.6 PPRINT-POP.7 PPRINT-POP.8
  PPRINT-NEWLINE.1 PPRINT-NEWLINE.2 PPRINT-NEWLINE.3 PPRINT-NEWLINE.LINEAR.1
  PPRINT-NEWLINE.LINEAR.2 PPRINT-NEWLINE.LINEAR.6 PPRINT-NEWLINE.LINEAR.7
  PPRINT-NEWLINE.LINEAR.8 PPRINT-NEWLINE.MISER.4 PPRINT-NEWLINE.MISER.6
  PPRINT-NEWLINE.MISER.7 PPRINT-NEWLINE.MISER.8 PPRINT-NEWLINE.MISER.9
  PPRINT-NEWLINE.MISER.10 PPRINT-NEWLINE.MISER.11 PPRINT-NEWLINE.FILL.1
  PPRINT-NEWLINE.FILL.2 PPRINT-NEWLINE.FILL.3 PPRINT-NEWLINE.FILL.4
  PPRINT-NEWLINE.FILL.5 PPRINT-NEWLINE.FILL.6 PPRINT-NEWLINE.FILL.7
  PPRINT-NEWLINE.MANDATORY.1 PPRINT-NEWLINE.MANDATORY.2
  PPRINT-NEWLINE.MANDATORY.3 PPRINT-NEWLINE.MANDATORY.5 PPRINT-TAB.NON-PRETTY.1
  PPRINT-TAB.NON-PRETTY.2 PPRINT-TAB.NON-PRETTY.3 PPRINT-TAB.NON-PRETTY.4
  PPRINT-TAB.NON-PRETTY.5 PPRINT-TAB.NON-PRETTY.6 PPRINT-TAB.NON-PRETTY.7
  PPRINT-TAB.NON-PRETTY.8 PPRINT-TAB.SECTION-RELATIVE.1
  FORMAT._.1 FORMAT._.2 FORMAT._.6 FORMAT._.7 FORMAT._.8
  FORMAT.@_.4 FORMAT.@_.6 FORMAT.@_.7 FORMAT.@_.8 FORMAT.@_.9
  |FORMAT.:T.5| |FORMAT.:T.5A| |FORMAT.:T.7| |FORMAT.:T.8| |FORMAT.:T.9|
  |FORMAT.:T.10| |FORMAT.:T.12| |FORMAT.:T.ERROR.1| |FORMAT.:T.ERROR.2|
  |FORMAT.:T.ERROR.3| |FORMAT.:@T.2| |FORMAT.:@T.3| |FORMAT.:@T.4|
  |FORMAT.:@T.5|
  |FORMAT.:_.1| |FORMAT.:_.2| |FORMAT.:_.3| |FORMAT.:_.4| |FORMAT.:_.5|
  |FORMAT.:_.6| |FORMAT.:@_.1| |FORMAT.:@_.2| |FORMAT.:@_.3|
  FORMAT.LOGICAL-BLOCK.ERROR.1 FORMAT.LOGICAL-BLOCK.ERROR.2
  FORMAT.LOGICAL-BLOCK.ERROR.3 FORMAT.LOGICAL-BLOCK.ERROR.4
  FORMAT.LOGICAL-BLOCK.ERROR.5 FORMAT.LOGICAL-BLOCK.ERROR.6
  FORMAT.LOGICAL-BLOCK.ERROR.7 FORMAT.LOGICAL-BLOCK.ERROR.8
  FORMAT.LOGICAL-BLOCK.ERROR.9 FORMAT.LOGICAL-BLOCK.ERROR.10
  FORMAT.LOGICAL-BLOCK.ERROR.11 FORMAT.LOGICAL-BLOCK.ERROR.12
  FORMAT.LOGICAL-BLOCK.ERROR.13 FORMAT.LOGICAL-BLOCK.ERROR.14
  FORMAT.LOGICAL-BLOCK.ERROR.15 FORMAT.LOGICAL-BLOCK.ERROR.16
  FORMAT.LOGICAL-BLOCK.ERROR.17 FORMAT.LOGICAL-BLOCK.ERROR.18
  FORMAT.LOGICAL-BLOCK.ERROR.19 FORMAT.LOGICAL-BLOCK.ERROR.20
  FORMAT.LOGICAL-BLOCK.ERROR.21 FORMAT.LOGICAL-BLOCK.ERROR.22
  FORMAT.LOGICAL-BLOCK.ERROR.23 FORMAT.LOGICAL-BLOCK.ERROR.24
  FORMAT.LOGICAL-BLOCK.ERROR.25 FORMAT.LOGICAL-BLOCK.ERROR.26
  FORMAT.LOGICAL-BLOCK.ERROR.27 FORMAT.LOGICAL-BLOCK.1 FORMAT.LOGICAL-BLOCK.4
  FORMAT.LOGICAL-BLOCK.5 FORMAT.LOGICAL-BLOCK.6 FORMAT.LOGICAL-BLOCK.7
  FORMAT.LOGICAL-BLOCK.9 FORMAT.LOGICAL-BLOCK.10 FORMAT.LOGICAL-BLOCK.13
  FORMAT.LOGICAL-BLOCK.14 FORMAT.LOGICAL-BLOCK.15 FORMAT.LOGICAL-BLOCK.18
  FORMAT.LOGICAL-BLOCK.19 FORMAT.LOGICAL-BLOCK.20 FORMAT.LOGICAL-BLOCK.21
  FORMAT.LOGICAL-BLOCK.22 FORMAT.LOGICAL-BLOCK.23 FORMAT.LOGICAL-BLOCK.24
  FORMAT.LOGICAL-BLOCK.25 FORMAT.LOGICAL-BLOCK.26 FORMAT.LOGICAL-BLOCK.27
  FORMAT.LOGICAL-BLOCK.28 FORMAT.LOGICAL-BLOCK.29 FORMAT.I.1 FORMAT.I.2
  FORMAT.I.3 FORMAT.I.4 FORMAT.I.5 FORMAT.I.6 FORMAT.I.7 FORMAT.I.8 FORMAT.I.9
  FORMAT.I.10 FORMAT.I.11 FORMAT.I.12 FORMAT.I.13 FORMAT.I.14 FORMAT.I.15
  FORMAT.I.16 FORMAT./.12 FORMAT./.13 FORMAT./.14 FORMAT./.15 FORMAT./.16
  FORMAT./.17 FORMAT./.18 FORMAT.JUSTIFY.ERROR.W.1 FORMAT.JUSTIFY.ERROR.W.2
  FORMAT.JUSTIFY.ERROR.W.3 FORMAT.JUSTIFY.ERROR._.1 FORMAT.JUSTIFY.ERROR._.2
  FORMAT.JUSTIFY.ERROR._.3 FORMAT.JUSTIFY.ERROR.I.1 FORMAT.JUSTIFY.ERROR.I.2
  FORMAT.JUSTIFY.ERROR.I.3

  ; To be revisited:
  FORMAT.D.18 FORMAT.D.19 FORMAT.D.20 FORMAT.D.21 FORMAT.B.18 FORMAT.B.19
  FORMAT.B.20 FORMAT.B.21 FORMAT.O.18 FORMAT.O.19 FORMAT.O.20 FORMAT.O.21
  FORMAT.X.18 FORMAT.X.19 FORMAT.X.20 FORMAT.X.21
  PRIN1.1 PRINC-TO-STRING.1
))

;; A few tests call DISASSEMBLE. Make it work without user intervention.
(setf (ext:getenv "PAGER") "cat")

;; Avoid floating-point computation warnings that bloat the log file.
(setq custom:*warn-on-floating-point-contagion* nil)
(setq custom:*warn-on-floating-point-rational-contagion* nil)

;; Then the tests.
(load "gclload2.lsp")

;; One test exceeds the memory available in the SPVW_PURE_BLOCKS model.
(when (and (= (logand (sys::address-of nil) #xffffff) 0) ; SPVW_PURE_BLOCKS ?
           (<= (integer-length most-positive-fixnum) 26)) ; 32-bit machine ?
  ;; Inhibit the CHAR-INT.2 test.
  (defun char-int.2.fn () t))
