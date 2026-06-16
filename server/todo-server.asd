; -*- mode: lisp -*-
(in-package #:cl-user)
(defpackage #:todo-server-system
  (:use #:asdf #:cl))
(in-package #:todo-server-system)

(defsystem todo-server
  :class :package-inferred-system
  :description ""
  :version "0.0.1"
  :author ""
  :license ""
  :pathname "app"
  :depends-on ("babel"
               "swank"
               "clails"
               "ironclad"
               "todo-server/application-loader")
  :in-order-to ((test-op (test-op "todo-server-test"))))

