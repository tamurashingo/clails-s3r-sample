; -*- mode: lisp -*-
(in-package #:cl-user)
(defpackage #:todo-client/components/root
  (:use #:cl)
  (:import-from #:cl-s3r.component #:define-layout #:define-component)
  (:import-from #:cl-s3r.server #:asset-path))

(in-package #:todo-client/components/root)

(define-layout app-layout (&key children &allow-other-keys)
  `(:html
    (:head
     (:meta (@ (:charset "UTF-8")))
     (:meta (@ (:name "viewport") (:content "width=device-width, initial-scale=1.0")))
     (:title "TODO App")
     (:link (@ (:rel "stylesheet") (:href ,(asset-path "/styles.css")))))
    (:body
     ,children)))

(define-component not-found-page (&key message &allow-other-keys)
  `(:div (@ (:class "error"))
     (:h1 "404 - Not Found")
     ,@(when message `((:p ,message)))
     (:a (@ (:href "/todos")) "<- Back to list")))

(define-component server-error-page (&key message &allow-other-keys)
  `(:div (@ (:class "error"))
     (:h1 "500 - Internal Server Error")
     ,@(when message `((:p ,message)))
     (:a (@ (:href "/todos")) "<- Back to list")))
