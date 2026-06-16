; -*- mode: lisp -*-
(in-package #:cl-user)
(defpackage #:todo-client-test/helpers
  (:use #:cl)
  (:export #:find-in-tree
           #:string-in-tree-p
           #:find-element
           #:with-mock-fn))
(in-package #:todo-client-test/helpers)

(defun find-in-tree (tree target)
  "Return T if target appears anywhere in the sexp tree (using equal)."
  (cond
    ((equal tree target) t)
    ((listp tree) (some (lambda (x) (find-in-tree x target)) tree))
    (t nil)))

(defun string-in-tree-p (tree substring)
  "Return T if any string in the sexp tree contains SUBSTRING."
  (cond
    ((and (stringp tree) (search substring tree)) t)
    ((listp tree) (some (lambda (x) (string-in-tree-p x substring)) tree))
    (t nil)))

(defun find-element (sexp tag)
  "Find the first element (direct or nested) with the given keyword tag."
  (when (listp sexp)
    (if (and (keywordp (car sexp)) (eq (car sexp) tag))
        sexp
        (some (lambda (x) (when (listp x) (find-element x tag))) (cdr sexp)))))

(defmacro with-mock-fn ((fn-name mock-fn) &body body)
  "Temporarily replace FN-NAME's fdefinition with MOCK-FN for the duration of BODY."
  (let ((original (gensym "ORIGINAL")))
    `(let ((,original (fdefinition ',fn-name)))
       (setf (fdefinition ',fn-name) ,mock-fn)
       (unwind-protect
            (progn ,@body)
         (setf (fdefinition ',fn-name) ,original)))))
