; -*- mode: lisp -*-
(in-package #:cl-user)
(defpackage #:todo-client/app
  (:use #:cl)
  (:import-from #:cl-s3r.server
                #:configure-root-page
                #:configure-route)
  (:import-from #:todo-client/components/root)
  (:import-from #:todo-client/components/signup)
  (:import-from #:todo-client/components/login)
  (:import-from #:todo-client/components/todo-list)
  (:import-from #:todo-client/components/todo-detail)
  (:import-from #:todo-client/components/todo-form)
  (:import-from #:todo-client/middleware #:handle-post))

(in-package #:todo-client/app)

(defun cl-s3r-path-p (path)
  "Return true for paths that cl-s3r handles internally."
  (or (search "/api/render" path)
      (search "/api/action" path)
      (string= "/app.js" path)))

;; Register routes at load time so s3rup can start the server directly.
(configure-root-page :component "root")
(configure-route :path "/signup"   :component "signup-page"      :props '())
(configure-route :path "/login"    :component "login-page"        :props '())
(configure-route :path "/todos"    :component "todo-list-page"    :props '())
(configure-route :path "/todo/new" :component "todo-form-page"    :props '())
(configure-route :path "/todo"     :component "todo-detail-page"  :props '()
                 :path-param :ulid)

(defun app (env)
  "POST middleware wrapper: intercepts form submissions, delegates everything else to cl-s3r."
  (let ((method (getf env :request-method))
        (path   (getf env :path-info)))
    (cond
      ((and (eq method :get)
            (or (string= path "/") (string= path "")))
       '(302 (:location "/login") ("")))
      ((and (eq method :post)
            (not (cl-s3r-path-p path)))
       (handle-post env (lambda (e) (cl-s3r.server::app e))))
      (t
       (cl-s3r.server::app env)))))

;; Override start-server so s3rup's run-server -> start-server picks up our app
;; instead of cl-s3r.server::app.  Patching start-server (not app) avoids the
;; SBCL in-place defun update that caused infinite recursion when patching app.
(defun cl-s3r.server::start-server (&key (port 5000) (address "0.0.0.0"))
  (format t "Starting server on ~A:~A...~%" address port)
  (setf cl-s3r.server::*handler*
        (clack:clackup #'app :port port :address address)))
