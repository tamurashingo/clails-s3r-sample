; -*- mode: lisp -*-
(in-package #:cl-user)
(defpackage #:todo-server/config/environment
  (:use #:cl)
  (:import-from #:clails/environment
                #:*project-environment*
                #:*routing-tables*))

(in-package #:todo-server/config/environment)

;; project name
(setf clails/environment:*project-name* "todo-server")

;; project environment
(setf clails/environment:*project-environment* :develop)

(setf clails/environment:*routing-tables*
  '((:path "/api/users"
     :controller "todo-server/controllers/users-controller:<users-controller>")
    (:path "/api/sessions"
     :controller "todo-server/controllers/sessions-controller:<sessions-controller>")
    (:path "/api/todos/:ulid/complete"
     :controller "todo-server/controllers/todos-controller:<todo-complete-controller>")
    (:path "/api/todos/:ulid"
     :controller "todo-server/controllers/todos-controller:<todo-controller>")
    (:path "/api/todos"
     :controller "todo-server/controllers/todos-controller:<todos-controller>")))


;; startup hooks
(push "todo-server/config/logger:initialize-logger" clails/environment:*startup-hooks*)
(push "clails/model/base-model:initialize-table-information" clails/environment:*startup-hooks*)

;; shutdown hooks
(push "todo-server/config/logger:finalize-logger" clails/environment:*shutdown-hooks*)

