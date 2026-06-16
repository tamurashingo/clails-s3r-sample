; -*- mode: lisp -*-
(in-package #:cl-user)
(defpackage #:todo-server/controllers/users-controller
  (:use #:cl
        #:clails/controller/base-controller)
  (:import-from #:todo-server/models/user
                #:user-exists-p
                #:create-user
                #:find-user-by-email)
  (:import-from #:todo-server/utils/http-util
                #:parse-json-body
                #:set-code)
  (:import-from #:clails/model
                #:ref)
  (:export #:<users-controller>))

(in-package #:todo-server/controllers/users-controller)

(defclass <users-controller> (<rest-controller>)
  ())


;; POST /api/users - sign up
(defmethod do-post ((c <users-controller>))
  (let* ((body (parse-json-body (env c)))
         (username (getf body :|username|))
         (email    (getf body :|email|))
         (password (getf body :|password|)))
    (cond
      ((or (null username) (string= username ""))
       (set-code c 400)
       (set-response c '(("error" . "username is required"))))
      ((or (null email) (string= email ""))
       (set-code c 400)
       (set-response c '(("erorr" . "email is required"))))
      ((or (null password) (string= password ""))
       (set-code c 400)
       (set-response c '(("error" . "password is required"))))
      ((user-exists-p email)
       (set-code c 409)
       (set-response c '(("error" . "email already registered"))))
      (t
       (let ((user (create-user username email password)))
         (if user
             (progn
               (set-code c 201)
               (set-response c `(("ulid"     . ,(ref user :ulid))
                                 ("username" . ,(ref user :username))
                                 ("email"    . ,(ref user :email)))))
             (progn
               (set-code c 500)
               (set-response c '(("error" . "failed to create user"))))))))))

