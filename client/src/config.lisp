; -*- mode: lisp -*-
(in-package #:cl-user)
(defpackage #:todo-client/config
  (:use #:cl)
  (:export #:api-server-url))

(in-package #:todo-client/config)

(defun api-server-url ()
  (or (uiop:getenv "API_SERVER_URL") "http://localhost:5000"))
