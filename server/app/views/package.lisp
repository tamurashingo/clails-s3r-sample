; -*- mode: lisp -*-
(in-package #:cl-user)
(defpackage #:todo-server/views/package
  (:use #:cl)
  (:import-from #:clails/view/view-helper
                #:*view-context*
                #:view)
  (:import-from #:todo-server/controllers/application-controller
                #:lisp-type
                #:lisp-version))

(in-package #:todo-server/views/package)