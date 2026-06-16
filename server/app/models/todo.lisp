; -*- mode: lisp -*-
(in-package #:cl-user)
(defpackage #:todo-server/models/todo
  (:use #:cl)
  (:import-from #:clails/model
                #:<base-model>
                #:defmodel
                #:query
                #:execute-query
                #:make-record
                #:save
                #:ref
                #:destroy)
  (:import-from #:clails/helper/date-helper
                #:view/datetime)
  (:import-from #:todo-server/utils/model-util
                #:generate-ulid)
  (:export #:<todo>
           #:find-todos-by-user
           #:find-todo-by-ulid
           #:create-todo
           #:update-todo
           #:complete-todo
           #:delete-todo
           #:todo-to-alist))

(in-package #:todo-server/models/todo)

(defmodel <todo> (<base-model>)
  (:table "todos"))


(defparameter *query-find-todos-by-user*
              (query <todo>
                     :as :todo
                     :where (:= (:todo :user-id) :user-id)
                     :order-by ((:todo :created-at :desc))))


(defun find-todos-by-user (user-id)
  (execute-query *query-find-todos-by-user*
                 `(:user-id ,user-id)))


(defparameter *query-find-todo-by-ulid*
              (query <todo>
                     :as :todo
                     :where (:and (:= (:todo :ulid) :ulid)
                                  (:= (:todo :user-id) :user-id))))

(defun find-todo-by-ulid (ulid user-id)
  (first (execute-query *query-find-todo-by-ulid*
                       `(:ulid ,ulid
                         :user-id ,user-id))))

(defun create-todo (user-id subject &key content deadline)
  (let ((inst (make-record '<todo>
                           :ulid (generate-ulid)
                           :user-id user-id
                           :subject subject
                           :content content
                           :deadline deadline
                           :completed nil)))
    (when (save inst)
      inst)))

(defun update-todo (todo &key subject content deadline)
  (when subject
    (setf (ref todo :subject) subject))
  (when content
    (setf (ref todo :content) content))
  (when deadline
    (setf (ref todo :deadline) deadline))
  (save todo)
  todo)

(defun complete-todo (todo)
  (setf (ref todo :completed) t)
  (setf (ref todo :completed-at) (get-universal-time))
  (save todo)
  todo)

(defun delete-todo (todo)
  (destroy todo))

(defun ut-to-iso-ymd (ut)
  (let ((s (view/datetime ut :fmt "%Y-%m-%d")))
    (when (and s (not (string= s "")))
      s)))

(defun ut-to-iso-ymdhm (ut)
  (let ((s (view/datetime ut :fmt "%Y-%m-%d %H:%M")))
    (when (and s (not (string= s "")))
      s)))

(defun todo-to-alist (todo)
  (list (cons "ulid"        (ref todo :ulid))
        (cons "subject"     (ref todo :subject))
        (cons "content"     (or (ref todo :content)
                                :null))
        (cons "deadline"    (or (ut-to-iso-ymd (ref todo :deadline))
                                :null))
        (cons "completed"   (if (ref todo :completed) t
                                                      :false))
        (cons "completedAt" (or (ut-to-iso-ymdhm (ref todo :completed-at))
                                :null))
        (cons "createdAt"   (ut-to-iso-ymdhm (ref todo :created-at)))
        (cons "updatedAt"   (ut-to-iso-ymdhm (ref todo :updated-at)))))

