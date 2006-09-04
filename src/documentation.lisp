;;;; Generic documentation
;;;; Sam Steingold 2002 - 2006
;;;; Bruno Haible 2004

(in-package "CLOS")

(defun function-documentation (x)
  (cond ((typep-class x <standard-generic-function>)
         (std-gf-documentation x))
        ((eq (type-of x) 'FUNCTION) ; interpreted function?
         (sys::%record-ref x 2))
        #+FFI ((eq (type-of x) 'ffi::foreign-function)
               (getf (sys::%record-ref x 5) :documentation))
        ((sys::subr-info x)     ; built-in
         (get :documentation (sys::function-name x)))
        (t (sys::closure-documentation x))))

;;; documentation
(defgeneric documentation (x doc-type)
  (:argument-precedence-order doc-type x)
  (:method ((x function) (doc-type (eql 't)))
    (function-documentation x))
  (:method ((x function) (doc-type (eql 'function)))
    (function-documentation x))
  (:method ((x cons) (doc-type (eql 'function)))
    (setq x (check-function-name x 'documentation))
    (and (fboundp x) (function-documentation (sys::unwrapped-fdefinition x))))
  (:method ((x cons) (doc-type (eql 'compiler-macro)))
    (setq x (check-function-name x 'documentation))
    (if (symbolp x)
      (documentation x 'compiler-macro)
      (documentation (second x) 'setf-compiler-macro)))
  (:method ((x symbol) (doc-type (eql 'function)))
    (and (fboundp x) (function-documentation (sys::unwrapped-fdefinition x))))
  (:method ((x symbol) (doc-type symbol))
    ;; doc-type = `compiler-macro', `setf', `variable', `type',
    ;; `setf-compiler-macro'
    (getf (get x 'sys::doc) doc-type))
  (:method ((x symbol) (doc-type (eql 'type)))
    (let ((class (find-class x nil)))
      (if class
        (documentation class 't)
        (call-next-method))))
  (:method ((x symbol) (doc-type (eql 'structure))) ; structure --> type
    (documentation x 'type))
  (:method ((x symbol) (doc-type (eql 'class))) ; class --> type
    (documentation x 'type))
  (:method ((x method-combination) (doc-type (eql 't)))
    (method-combination-documentation x))
  (:method ((x method-combination) (doc-type (eql 'method-combination)))
    (method-combination-documentation x))
  (:method ((x symbol) (doc-type (eql 'method-combination)))
    (method-combination-documentation (get-method-combination x 'documentation)))
  (:method ((x standard-method) (doc-type (eql 't)))
    (std-method-documentation x))
  (:method ((x package) (doc-type (eql 't)))
    (let ((doc (sys::package-documentation x)))
      (if (consp doc) (first doc) doc)))
  (:method ((x standard-class) (doc-type (eql 't)))
    (class-documentation x))
  (:method ((x standard-class) (doc-type (eql 'type)))
    (class-documentation x))
  (:method ((x structure-class) (doc-type (eql 't)))
    (class-documentation x))
  (:method ((x structure-class) (doc-type (eql 'type)))
    (class-documentation x))
  ;;; The following are CLISP extensions.
  (:method ((x standard-object) (doc-type (eql 't)))
    (documentation (class-of x) 'type))
  (:method ((x standard-object) (doc-type (eql 'type)))
    (documentation (class-of x) 'type))
  (:method ((x structure-object) (doc-type (eql 't)))
    (documentation (class-of x) 'type))
  (:method ((x structure-object) (doc-type (eql 'type)))
    (documentation (class-of x) 'type))
  (:method ((x defined-class) (doc-type (eql 't)))
    (class-documentation x))
  (:method ((x defined-class) (doc-type (eql 'type)))
    (class-documentation x))
  (:method ((x slot-definition) (doc-type (eql 't)))
    (slot-definition-documentation x)))

(defun set-function-documentation (x new-value)
  (cond ((typep-class x <standard-generic-function>)
         (setf (std-gf-documentation x) new-value))
        ((eq (type-of x) 'FUNCTION) ; interpreted function?
         (setf (sys::%record-ref x 2) new-value))
        #+FFI ((eq (type-of x) 'ffi::foreign-function)
               (setf (getf (sys::%record-ref x 5) :documentation) new-value))
        ((sys::subr-info x)     ; built-in
         (get :documentation (sys::function-name x)))
        (t (sys::closure-set-documentation x new-value))))

(defgeneric (setf documentation) (new-value x doc-type)
  (:argument-precedence-order doc-type x new-value)
  (:method (new-value (x function) (doc-type (eql 't)))
    (set-function-documentation x new-value))
  (:method (new-value (x function) (doc-type (eql 'function)))
    (set-function-documentation x new-value))
  (:method (new-value (x cons) (doc-type (eql 'function)))
    (setq x (check-function-name x '(setf documentation)))
    (and (fboundp x)
         (set-function-documentation (sys::unwrapped-fdefinition x) new-value)))
  (:method (new-value (x cons) (doc-type (eql 'compiler-macro)))
    (setq x (check-function-name x '(setf documentation)))
    (if (symbolp x)
      (sys::%set-documentation x 'compiler-macro new-value)
      (sys::%set-documentation (second x) 'setf-compiler-macro new-value)))
  (:method (new-value (x symbol) (doc-type (eql 'function)))
    (and (fboundp x)
         (set-function-documentation (sys::unwrapped-fdefinition x) new-value)))
  (:method (new-value (x symbol) (doc-type symbol))
    ;; doc-type = `compiler-macro', `setf', `variable', `type',
    ;; `setf-compiler-macro'
    (sys::%set-documentation x doc-type new-value))
  (:method (new-value (x symbol) (doc-type (eql 'type)))
    (let ((class (find-class x nil)))
      (if class
        (setf (documentation class 't) new-value)
        (call-next-method))))
  (:method (new-value (x symbol) (doc-type (eql 'structure)))
    (sys::%set-documentation x 'type new-value))
  (:method (new-value (x symbol) (doc-type (eql 'class)))
    (sys::%set-documentation x 'type new-value))
  (:method (new-value (x method-combination) (doc-type (eql 't)))
    (setf (method-combination-documentation x) new-value))
  (:method
      (new-value (x method-combination) (doc-type (eql 'method-combination)))
    (setf (method-combination-documentation x) new-value))
  (:method (new-value (x symbol) (doc-type (eql 'method-combination)))
    (setf (method-combination-documentation (get-method-combination x '(setf documentation)))
          new-value))
  (:method (new-value (x standard-method) (doc-type (eql 't)))
    (setf (std-method-documentation x) new-value))
  (:method (new-value (x package) (doc-type (eql 't)))
    (let ((doc (sys::package-documentation x)))
      (if (consp doc)
          (setf (first doc) new-value)
          (setf (sys::package-documentation x) new-value))))
  (:method (new-value (x standard-class) (doc-type (eql 't)))
    (setf (class-documentation x) new-value))
  (:method (new-value (x standard-class) (doc-type (eql 'type)))
    (setf (class-documentation x) new-value))
  (:method (new-value (x structure-class) (doc-type (eql 't)))
    (setf (class-documentation x) new-value))
  (:method (new-value (x structure-class) (doc-type (eql 'type)))
    (setf (class-documentation x) new-value))
  ;;; The following are CLISP extensions.
  (:method (new-value (x standard-object) (doc-type (eql 't)))
    (sys::%set-documentation (class-of x) 'type new-value))
  (:method (new-value (x standard-object) (doc-type (eql 'type)))
    (sys::%set-documentation (class-of x) 'type new-value))
  (:method (new-value (x structure-object) (doc-type (eql 't)))
    (sys::%set-documentation (class-of x) 'type new-value))
  (:method (new-value (x structure-object) (doc-type (eql 'type)))
    (sys::%set-documentation (class-of x) 'type new-value))
  (:method (new-value (x defined-class) (doc-type (eql 't)))
    (setf (class-documentation x) new-value))
  (:method (new-value (x defined-class) (doc-type (eql 'type)))
    (setf (class-documentation x) new-value))
  (:method (new-value (x slot-definition) (doc-type (eql 't)))
    (setf (slot-definition-documentation x) new-value)))
