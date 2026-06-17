; -*- mode: lisp -*-
(in-package #:cl-user)
(defpackage #:todo-client/app
  (:use #:cl)
  (:import-from #:cl-s3r.server
                #:configure-default-layout
                #:configure-route
                #:configure-static-dir
                #:define-error-page)
  (:import-from #:cl-s3r.session
                #:get-session)
  (:import-from #:cl-s3r.cookie
                #:*current-cookies*
                #:*pending-cookie-changes*
                #:parse-cookies
                #:inject-set-cookie-headers)
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

(defun require-auth (env)
  (declare (ignore env))
  (unless (getf (get-session :token) :token)
    "/login"))

;; Register routes at load time so s3rup can start the server directly.
(configure-static-dir (asdf:system-relative-pathname "todo-client" "public/"))
(configure-default-layout 'todo-client/components/root::app-layout)

(define-error-page :status 404 :component "not-found-page")
(define-error-page :status 500 :component "server-error-page")

(configure-route :path "/signup"   :component "signup-page"      :props '())
(configure-route :path "/login"    :component "login-page"        :props '())
(configure-route :path "/todos"    :component "todo-list-page"    :props '()
                 :guard #'require-auth)
(configure-route :path "/todo/new" :component "todo-form-page"    :props '()
                 :guard #'require-auth)
(configure-route :path "/todo"     :component "todo-detail-page"  :props '()
                 :path-param :ulid :guard #'require-auth)

;; Holds the cl-s3r app wrapped with static file middleware (set in start-server).
(defvar *s3r-handler* nil)

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
       (let ((*current-cookies* (parse-cookies (gethash "cookie" (getf env :headers))))
             (*pending-cookie-changes* nil))
         (inject-set-cookie-headers
          (handle-post env (lambda (e) (funcall *s3r-handler* e))))))
      (t
       (funcall *s3r-handler* env)))))

;; Override start-server so s3rup's run-server -> start-server picks up our app
;; instead of cl-s3r.server::app.  Patching start-server (not app) avoids the
;; SBCL in-place defun update that caused infinite recursion when patching app.
;; *s3r-handler* is set to build-app's result so static file middleware is active.
(defun cl-s3r.server::start-server (&key (port 5000) (address "0.0.0.0"))
  (format t "Starting server on ~A:~A...~%" address port)
  (setf *s3r-handler* (cl-s3r.server::build-app))
  (setf cl-s3r.server::*handler*
        (clack:clackup #'app :port port :address address)))
