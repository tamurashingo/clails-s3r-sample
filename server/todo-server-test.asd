; -*- mode: lisp -*-
(in-package #:cl-user)
(defpackage #:todo-server-test-system
  (:use #:asdf #:cl))
(in-package #:todo-server-test-system)

(defsystem todo-server-test
  :class :package-inferred-system
  :pathname "test"
  :depends-on ("clails"
               "rove"
               "todo-server"
               "todo-server-test/test-loader")
  :perform (test-op (o c)
             (uiop:symbol-call :rove :run c)))
