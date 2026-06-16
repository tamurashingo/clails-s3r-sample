; -*- mode: lisp -*-
(in-package #:cl-user)
(defpackage #:todo-server/models/user
  (:use #:cl
        #:clails/model/base-model)
  (:import-from #:clails/model
                #:<base-model>
                #:defmodel
                #:query
                #:execute-query
                #:make-record
                #:save
                #:ref)
  (:import-from #:todo-server/utils/model-util
                #:generate-ulid
                #:hash-password)
  (:export #:<user>
           #:find-user-by-email
           #:find-user-by-ulid
           #:create-user
           #:user-exists-p))

(in-package #:todo-server/models/user)

(defmodel <user> (<base-model>)
  (:table "users"))

(defun find-user-by-email (email)
  (first (execute-query
           (query <user>
                  :as :u
                  :where (:= (:u :email) :email))
           `(:email ,email))))

(defun find-user-by-ulid (ulid)
  (first (execute-query
           (query <user>
                  :as :u
                  :where (:= (:u :ulid) :ulid))
           `(:ulid ,ulid))))

(defun user-exists-p (email)
  (not (null (find-user-by-email email))))

(defun create-user (username email password)
  (let ((inst (make-record '<user>
                           :ulid (generate-ulid)
                           :username username
                           :email email
                           :password-digest (hash-password password))))
    (when (save inst)
      inst)))

