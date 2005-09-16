;; -*- Lisp -*-
;; some tests for WIN32
;; clisp -K full -E utf-8 -q -norc -i ../tests/tests -x '(run-test "bindings/win32/test")'

(defmacro show-mv (form) `(listp (show (multiple-value-list ,form)))) SHOW-MV

(stringp (show (win32:GetCommandLineA))) T
(integerp (show (win32:GetLastError))) T
(integerp (show (win32:GetCurrentProcessId))) T
(integerp (show (win32:GetCurrentThreadId))) T

(let ((handle (win32:GetModuleHandleA "kernel32")))
  (unwind-protect (show-mv (win32:GetModuleFileNameA handle win32:MAX_PATH))
    (win32:CloseHandle handle)))
T

(show-mv (win32:GetConsoleTitleA win32:BUFSIZ)) T
(show-mv (win32:GetSystemDirectoryA win32:MAX_PATH)) T
(show-mv (win32:GetWindowsDirectoryA win32:MAX_PATH)) T
(show-mv (win32:GetCurrentDirectoryA win32:MAX_PATH)) T
(integerp (show (win32:GetVersion))) T
(show-mv (win32:GetUserNameA win32:UNLEN)) T
(show-mv (win32:GetComputerNameA win32:MAX_COMPUTERNAME_LENGTH)) T

(defun check-all (enum-type function buf-size)
  (format t "~&;; ~s:~%" function)
  (maphash (lambda (key val)
             (let ((res (multiple-value-list (funcall function key buf-size))))
               (format t " ~S -> ~S~@[ ~S~]~%" val res
                       (unless (car res) (w32:GetLastError)))))
           (ffi::enum-table enum-type)))
CHECK-ALL

(check-all 'w32:EXTENDED_NAME_FORMAT 'w32:GetUserNameExA w32:UNLEN) NIL
(check-all 'w32:EXTENDED_NAME_FORMAT 'w32:GetComputerObjectNameA w32:UNLEN) NIL
(check-all 'w32:COMPUTER_NAME_FORMAT 'w32:GetComputerNameExA
           w32:MAX_COMPUTERNAME_LENGTH) NIL
