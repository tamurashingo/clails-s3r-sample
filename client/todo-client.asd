; -*- mode: lisp -*-
(in-package #:cl-user)
(defpackage #:todo-client-system
  (:use #:asdf #:cl))
(in-package #:todo-client-system)

(defsystem "todo-client"
  :description "TODO Client (BFF using cl-s3r)"
  :version "0.0.1"
  :depends-on ("cl-s3r"
               "clack"
               "dexador"
               "jonathan"
               "babel")
  :components ((:module "src"
                :components
                ((:file "package")
                 (:file "config"       :depends-on ("package"))
                 (:file "api-client"   :depends-on ("config"))
                 (:file "middleware"   :depends-on ("api-client"))
                 (:module "components"
                  :depends-on ("api-client")
                  :components
                  ((:file "root")
                   (:file "signup")
                   (:file "login")
                   (:file "todo-list")
                   (:file "todo-detail")
                   (:file "todo-form")))))
               (:file "app" :depends-on ("src")))
  :in-order-to ((test-op (test-op "todo-client/test"))))

(defsystem "todo-client/test"
  :description "Tests for todo-client BFF components"
  :depends-on ("todo-client" "rove" "cl-s3r")
  :components ((:module "test"
                :components
                ((:file "helpers")
                 (:module "components"
                  :depends-on ("helpers")
                  :components
                  ((:file "login")
                   (:file "signup")
                   (:file "root")
                   (:file "todo-form")
                   (:file "todo-list")
                   (:file "todo-detail")))
                 (:file "test-loader" :depends-on ("components")))))
  :perform (test-op (o c)
    (uiop:symbol-call :rove :run c)))
