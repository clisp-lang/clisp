;;; Parsing ordinary lambda lists
;;; Bruno Haible 1988-2004
;;; Sam Steingold 1999-2001

(in-package "SYSTEM")

(macrolet ((push (element-form list-var)
             `(setq ,list-var (cons ,element-form ,list-var)))
           (err-misplaced (item)
             `(funcall errfunc (TEXT "Lambda list marker ~S not allowed here.")
                               ,item))
           (err-invalid (item)
             `(funcall errfunc (if (or (symbolp ,item) (listp ,item))
                                 (TEXT "Invalid lambda list element ~S")
                                 (TEXT "Invalid lambda list element ~S. A lambda list may only contain symbols and lists."))
                               ,item))
           (check-item (item permissible)
             `(if (memq ,item ,permissible)
                (return)
                (err-misplaced ,item)))
           (skip-L (lastseen items)
             `(loop
                (when (atom L) (return))
                (let ((item (car L)))
                  (if (memq item lambda-list-keywords)
                    (check-item item ,items)
                    (funcall errfunc ,(case lastseen
                                        (&REST '(TEXT "Lambda list element ~S is superfluous. Only one variable is allowed after &REST."))
                                        (&ALLOW-OTHER-KEYS '(TEXT "Lambda list element ~S is superfluous. No variable is allowed right after &ALLOW-OTHER-KEYS."))
                                        (&ENVIRONMENT '(TEXT "Lambda list element ~S is superfluous. Only one variable is allowed after &ENVIRONMENT."))
                                        (t '(TEXT "Lambda list element ~S is superfluous.")))
                                     item)))
                (setq L (cdr L)))))

;;; Analyzes a lambda-list of a function (CLtL2 p. 76, ANSI CL 3.4.1.).
;;; Reports errors through errfunc (a function taking an error format string
;;; and format string arguments).
;; Returns 13 values:
;; 1. list of required parameters
;; 2. list of optional parameters
;; 3. list of init-forms of the optional parameters
;; 4. list of supplied-vars for the optional parameters (0 for the missing)
;; 5. &rest parameter or 0
;; 6. flag, if keywords are allowed
;; 7. list of keywords
;; 8. list of keyword parameters
;; 9. list of init-forms of the keyword parameters
;; 10. list of supplied-vars for the keyword parameters (0 for the missing)
;; 11. flag, if other keywords are allowed
;; 12. list of &aux variables
;; 13. list of init-forms of the &aux variables
  (defun analyze-lambdalist (lambdalist errfunc)
    (let ((L lambdalist) ; rest of the lambda-list
          (reqvar nil)
          (optvar nil)
          (optinit nil)
          (optsvar nil)
          (rest 0)
          (keyflag nil)
          (keyword nil)
          (keyvar nil)
          (keyinit nil)
          (keysvar nil)
          (allow-other-keys nil)
          (auxvar nil)
          (auxinit nil))
      ;; The lists are all accumulated in reversed order.
      ;; Required parameters:
      (loop
        (if (atom L) (return))
        (let ((item (car L)))
          (if (symbolp item)
            (if (memq item lambda-list-keywords)
              (check-item item '(&optional &rest &key &aux))
              (push item reqvar))
            (err-invalid item)))
        (setq L (cdr L)))
      ;; Now (or (atom L) (member (car L) '(&optional &rest &key &aux))).
      ;; Optional parameters:
      (when (and (consp L) (eq (car L) '&optional))
        (setq L (cdr L))
        (macrolet ((note-optional (var init svar)
                     `(progn
                        (push ,var optvar)
                        (push ,init optinit)
                        (push ,svar optsvar))))
          (loop
            (if (atom L) (return))
            (let ((item (car L)))
              (if (symbolp item)
                (if (memq item lambda-list-keywords)
                  (check-item item '(&rest &key &aux))
                  (note-optional item nil 0))
                (if (and (consp item) (symbolp (car item)))
                  (if (null (cdr item))
                    (note-optional (car item) nil 0)
                    (if (consp (cdr item))
                      (if (null (cddr item))
                        (note-optional (car item) (cadr item) 0)
                        (if (and (consp (cddr item)) (symbolp (caddr item))
                                 (null (cdddr item)))
                          (note-optional (car item) (cadr item) (caddr item))
                          (err-invalid item)))
                      (err-invalid item)))
                  (err-invalid item))))
            (setq L (cdr L)))))
      ;; Now (or (atom L) (member (car L) '(&rest &key &aux))).
      ;; &rest parameters:
      (when (and (consp L) (eq (car L) '&rest))
        (setq L (cdr L))
        (macrolet ((err-norest ()
                     `(funcall errfunc (TEXT "Missing &REST parameter in lambda list ~S")
                                       lambdalist)))
          (if (atom L)
            (err-norest)
            (prog ((item (car L)))
              (if (symbolp item)
                (if (memq item lambda-list-keywords)
                  (progn (err-norest) (return))
                  (setq rest item))
                (err-invalid item))
              (setq L (cdr L)))))
        ;; Move forward to the next &KEY or &AUX:
        (skip-L &rest '(&key &aux)))
      ;; Now (or (atom L) (member (car L) '(&key &aux))).
      ;; Keyword parameters:
      (when (and (consp L) (eq (car L) '&key))
        (setq L (cdr L))
        (setq keyflag t)
        (loop
          (if (atom L) (return))
          (let ((item (car L)))
            (if (symbolp item)
              (if (memq item lambda-list-keywords)
                (check-item item '(&allow-other-keys &aux))
                (progn
                  (push (intern (symbol-name item) *keyword-package*) keyword)
                  (push item keyvar) (push nil keyinit) (push 0 keysvar)))
              (if (and (consp item)
                       (or (symbolp (car item))
                           (and (consp (car item))
                                (symbolp (caar item))
                                (consp (cdar item))
                                (symbolp (cadar item))
                                (null (cddar item))))
                       (or (null (cdr item))
                           (and (consp (cdr item))
                                (or (null (cddr item))
                                    (and (consp (cddr item))
                                         (symbolp (caddr item))
                                         (null (cdddr item)))))))
                (progn
                  (if (consp (car item))
                    (progn
                      (push (caar item) keyword)
                      (push (cadar item) keyvar))
                    (progn
                      (push (intern (symbol-name (car item)) *keyword-package*)
                            keyword)
                      (push (car item) keyvar)))
                  (if (consp (cdr item))
                    (progn
                      (push (cadr item) keyinit)
                      (if (consp (cddr item))
                        (push (caddr item) keysvar)
                        (push 0 keysvar)))
                    (progn (push nil keyinit) (push 0 keysvar))))
                (err-invalid item))))
          (setq L (cdr L)))
        ;; Now (or (atom L) (member (car L) '(&allow-other-keys &aux))).
        (when (and (consp L) (eq (car L) '&allow-other-keys))
          (setq allow-other-keys t)
          (setq L (cdr L))
          ;; Move forward  to the next &AUX:
          (skip-L &allow-other-keys '(&aux))))
      ;; Now (or (atom L) (member (car L) '(&aux))).
      ;; &aux variables:
      (when (and (consp L) (eq (car L) '&aux))
        (setq L (cdr L))
        (loop
          (if (atom L) (return))
          (let ((item (car L)))
            (if (symbolp item)
              (if (memq item lambda-list-keywords)
                (err-misplaced item)
                (progn (push item auxvar) (push nil auxinit)))
              (if (and (consp item) (symbolp (car item)))
                (if (null (cdr item))
                  (progn (push (car item) auxvar) (push nil auxinit))
                  (if (and (consp (cdr item)) (null (cddr item)))
                    (progn (push (car item) auxvar) (push (cadr item) auxinit))
                    (err-invalid item)))
                (err-invalid item))))
          (setq L (cdr L))))
      ;; Now (atom L).
      (if L
        (funcall errfunc (TEXT "Lambda lists with dots are only allowed in macros, not here: ~S")
                         lambdalist))
      (values
        (nreverse reqvar)
        (nreverse optvar) (nreverse optinit) (nreverse optsvar)
        rest
        keyflag
        (nreverse keyword) (nreverse keyvar) (nreverse keyinit) (nreverse keysvar)
        allow-other-keys
        (nreverse auxvar) (nreverse auxinit))))

;;; Analyzes a defsetf lambda-list (ANSI CL 3.4.7.).
;;; Reports errors through errfunc (a function taking an error format string
;;; and format string arguments).
;; Returns 12 values:
;; 1. list of required parameters
;; 2. list of optional parameters
;; 3. list of init-forms of the optional parameters
;; 4. list of supplied-vars for the optional parameters (0 for the missing)
;; 5. &rest parameter or 0
;; 6. flag, if keywords are allowed
;; 7. list of keywords
;; 8. list of keyword parameters
;; 9. list of init-forms of the keyword parameters
;; 10. list of supplied-vars for the keyword parameters (0 for the missing)
;; 11. flag, if other keywords are allowed
;; 12. &environment parameter or 0
  (defun analyze-defsetf-lambdalist (lambdalist errfunc)
    (let ((L lambdalist) ; rest of the lambda-list
          (reqvar nil)
          (optvar nil)
          (optinit nil)
          (optsvar nil)
          (rest 0)
          (keyflag nil)
          (keyword nil)
          (keyvar nil)
          (keyinit nil)
          (keysvar nil)
          (allow-other-keys nil)
          (env 0))
      ;; The lists are all accumulated in reversed order.
      ;; Required parameters:
      (loop
        (if (atom L) (return))
        (let ((item (car L)))
          (if (symbolp item)
            (if (memq item lambda-list-keywords)
              (check-item item '(&optional &rest &key &environment))
              (push item reqvar))
            (err-invalid item)))
        (setq L (cdr L)))
      ;; Now (or (atom L) (member (car L) '(&optional &rest &key &environment))).
      ;; Optional parameters:
      (when (and (consp L) (eq (car L) '&optional))
        (setq L (cdr L))
        (macrolet ((note-optional (var init svar)
                     `(progn
                        (push ,var optvar)
                        (push ,init optinit)
                        (push ,svar optsvar))))
          (loop
            (if (atom L) (return))
            (let ((item (car L)))
              (if (symbolp item)
                (if (memq item lambda-list-keywords)
                  (check-item item '(&rest &key &environment))
                  (note-optional item nil 0))
                (if (and (consp item) (symbolp (car item)))
                  (if (null (cdr item))
                    (note-optional (car item) nil 0)
                    (if (consp (cdr item))
                      (if (null (cddr item))
                        (note-optional (car item) (cadr item) 0)
                        (if (and (consp (cddr item)) (symbolp (caddr item))
                                 (null (cdddr item)))
                          (note-optional (car item) (cadr item) (caddr item))
                          (err-invalid item)))
                      (err-invalid item)))
                  (err-invalid item))))
            (setq L (cdr L)))))
      ;; Now (or (atom L) (member (car L) '(&rest &key &environment))).
      ;; &rest parameters:
      (when (and (consp L) (eq (car L) '&rest))
        (setq L (cdr L))
        (macrolet ((err-norest ()
                     `(funcall errfunc (TEXT "Missing &REST parameter in lambda list ~S")
                                       lambdalist)))
          (if (atom L)
            (err-norest)
            (prog ((item (car L)))
              (if (symbolp item)
                (if (memq item lambda-list-keywords)
                  (progn (err-norest) (return))
                  (setq rest item))
                (err-invalid item))
              (setq L (cdr L)))))
        ;; Move forward to the next &KEY or &ENVIRONMENT:
        (skip-L &rest '(&key &environment)))
      ;; Now (or (atom L) (member (car L) '(&key &environment))).
      ;; Keyword parameters:
      (when (and (consp L) (eq (car L) '&key))
        (setq L (cdr L))
        (setq keyflag t)
        (loop
          (if (atom L) (return))
          (let ((item (car L)))
            (if (symbolp item)
              (if (memq item lambda-list-keywords)
                (check-item item '(&allow-other-keys &environment))
                (progn
                  (push (intern (symbol-name item) *keyword-package*) keyword)
                  (push item keyvar) (push nil keyinit) (push 0 keysvar)))
              (if (and (consp item)
                       (or (symbolp (car item))
                           (and (consp (car item))
                                (symbolp (caar item))
                                (consp (cdar item))
                                (symbolp (cadar item))
                                (null (cddar item))))
                       (or (null (cdr item))
                           (and (consp (cdr item))
                                (or (null (cddr item))
                                    (and (consp (cddr item))
                                         (symbolp (caddr item))
                                         (null (cdddr item)))))))
                (progn
                  (if (consp (car item))
                    (progn
                      (push (caar item) keyword)
                      (push (cadar item) keyvar))
                    (progn
                      (push (intern (symbol-name (car item)) *keyword-package*)
                            keyword)
                      (push (car item) keyvar)))
                  (if (consp (cdr item))
                    (progn
                      (push (cadr item) keyinit)
                      (if (consp (cddr item))
                        (push (caddr item) keysvar)
                        (push 0 keysvar)))
                    (progn (push nil keyinit) (push 0 keysvar))))
                (err-invalid item))))
          (setq L (cdr L)))
        ;; Now (or (atom L) (member (car L) '(&allow-other-keys &environment))).
        (when (and (consp L) (eq (car L) '&allow-other-keys))
          (setq allow-other-keys t)
          (setq L (cdr L))
          ;; Move forward to the next &ENVIRONMENT:
          (skip-L &allow-other-keys '(&environment))))
      ;; Now (or (atom L) (member (car L) '(&environment))).
      ;; &environment parameter:
      (when (and (consp L) (eq (car L) '&environment))
        (setq L (cdr L))
        (macrolet ((err-noenvironment ()
                     `(funcall errfunc (TEXT "Missing &ENVIRONMENT parameter in lambda list ~S")
                                       lambdalist)))
          (if (atom L)
            (err-noenvironment)
            (prog ((item (car L)))
              (if (symbolp item)
                (if (memq item lambda-list-keywords)
                  (progn (err-noenvironment) (return))
                  (setq env item))
                (err-invalid item))
              (setq L (cdr L)))))
        ;; Move forward to the end:
        (skip-L &environment '()))
      ;; Now (atom L).
      (if L
        (funcall errfunc (TEXT "Lambda lists with dots are only allowed in macros, not here: ~S")
                         lambdalist))
      (values
        (nreverse reqvar)
        (nreverse optvar) (nreverse optinit) (nreverse optsvar)
        rest
        keyflag
        (nreverse keyword) (nreverse keyvar) (nreverse keyinit) (nreverse keysvar)
        allow-other-keys
        env)))

) ; macrolet
