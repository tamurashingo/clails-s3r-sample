; -*- mode: lisp -*-
(in-package #:cl-user)
(defpackage #:todo-client/api-client
  (:use #:cl)
  (:import-from #:todo-client/config #:api-server-url)
  (:export #:api-get
           #:api-post
           #:api-put
           #:api-delete))

(in-package #:todo-client/api-client)

(defun bearer-headers (token)
  `(("Authorization" . ,(format nil "Bearer ~A" token))
    ("Content-Type"  . "application/json")))

(defun json-headers ()
  '(("Content-Type" . "application/json")))

(defun full-url (path)
  (format nil "~A~A" (api-server-url) path))

(defun api-get (path token)
  (dex:get (full-url path)
           :headers (bearer-headers token)
           :force-string t))

(defun api-post (path token body-alist)
  (let ((json-body (jonathan:to-json body-alist)))
    (dex:post (full-url path)
              :headers (if token (bearer-headers token) (json-headers))
              :content json-body
              :force-string t)))

(defun api-put (path token &optional body-alist)
  (let ((json-body (if body-alist (jonathan:to-json body-alist) "{}")))
    (dex:put (full-url path)
             :headers (bearer-headers token)
             :content json-body
             :force-string t)))

(defun api-delete (path token)
  (dex:delete (full-url path)
              :headers (bearer-headers token)
              :force-string t))
