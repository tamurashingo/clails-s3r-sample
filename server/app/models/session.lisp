; -*- mode: lisp -*-
(in-package #:cl-user)
(defpackage #:todo-server/models/session
  (:use #:cl
        #:clails/model/base-model)
  (:import-from #:clails/model
                #:<base-model>
                #:defmodel
                #:query
                #:execute-query
                #:make-record
                #:save
                #:ref
                #:destroy)
  (:import-from #:todo-server/utils/model-util
                #:generate-ulid
                #:generate-token)
  (:export #:<session>
           #:create-session
           #:find-session-by-token
           #:delete-session-by-token))

(in-package #:todo-server/models/session)

(defmodel <session> (<base-model>)
  (:table "sessions"))

(defparameter *query-find-session-by-token*
              (query <session>
                     :as :session
                     :where (:= (:session :token) :token)))

(defun find-session-by-token (token)
  (first (execute-query *query-find-session-by-token*
                        `(:token ,token))))

(defun create-session (user-id)
  (let* ((token (generate-token))
         (inst (make-record '<session>
                            :ulid (generate-ulid)
                            :user-id user-id
                            :token token
                            :expires-at (+ (get-universal-time) (* 7 24 60 60)))))
    (when (save inst)
      inst)))

(defun delete-session-by-token (token)
  (let ((session (find-session-by-token token)))
    (when session
      (destroy session)
      t)))

