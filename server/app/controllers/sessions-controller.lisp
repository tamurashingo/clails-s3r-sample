; -*- mode: lisp -*-
(in-package #:cl-user)
(defpackage #:todo-server/controllers/sessions-controller
  (:use #:cl
        #:clails/controller/base-controller)
  (:import-from #:todo-server/utils/http-util
                #:parse-json-body
                #:authenticate-request
                #:set-code)
  (:import-from #:todo-server/utils/model-util
                #:verify-password)
  (:import-from #:todo-server/models/user
                #:find-user-by-email)
  (:import-from #:todo-server/models/session
                #:create-session
                #:delete-session-by-token)
  (:import-from #:clails/model
                #:ref)
  (:export #:<sessions-controller>))

(in-package #:todo-server/controllers/sessions-controller)

(defclass <sessions-controller> (<rest-controller>) ())

;; POST /api/sessions - login
(defmethod do-post ((c <sessions-controller>))
  (let* ((body     (parse-json-body (env c)))
         (email    (getf body :|email|))
         (password (getf body :|password|)))
    (cond
      ((or (null email) (string= email ""))
       (set-code c 400)
       (set-response c '(("error" . "email is required"))))
      ((or (null password) (string= password ""))
       (set-code c 400)
       (set-response c '(("error" . "password is required"))))
      (t
       (let ((user (find-user-by-email email)))
         (if (and user (verify-password password (ref user :password-digest)))
             (let ((session (create-session (ref user :id))))
               (if session
                   (set-response c
                     `(("token"    . ,(ref session :token)) 
                       ("ulid"     . ,(ref user :ulid))
                       ("username" . ,(ref user :username))))
                   (progn
                     (set-code c 500)
                     (set-response c '(("error" . "failed to create session"))))))
             (progn
               (set-code c 401)
               (set-response c '(("error" . "invalid email or password"))))))))))

;; DELETE /api/sessions - logout
(defmethod do-delete ((c <sessions-controller>))
  (let ((session (authenticate-request (env c))))
    (if (null session)
        (progn
          (set-code c 401)
          (set-response c '(("error" . "unauthorized"))))
        (progn
          (delete-session-by-token (ref session :token))
          (set-response c '(("message" . "logged out")))))))

