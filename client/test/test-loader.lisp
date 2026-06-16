; -*- mode: lisp -*-
(in-package #:cl-user)
(defpackage #:todo-client-test/test-loader
  (:use #:cl)
  (:import-from #:todo-client-test/components/login)
  (:import-from #:todo-client-test/components/signup)
  (:import-from #:todo-client-test/components/root)
  (:import-from #:todo-client-test/components/todo-form)
  (:import-from #:todo-client-test/components/todo-list)
  (:import-from #:todo-client-test/components/todo-detail))
(in-package #:todo-client-test/test-loader)
