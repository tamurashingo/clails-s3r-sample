; -*- mode: lisp -*-
(in-package #:cl-user)
(defpackage #:todo-client/config
  (:use #:cl)
  (:import-from #:cl-s3r.config
                #:getenv)
  (:export #:api-server-url))

(in-package #:todo-client/config)

(defun api-server-url ()
  (getenv "API_SERVER_URL" :default "http://localhost:5000"))
