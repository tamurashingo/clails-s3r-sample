; -*- mode: lisp -*-
(in-package #:cl-user)
(defpackage #:todo-client/components/todo-form
  (:use #:cl)
  (:import-from #:cl-s3r.component #:define-component)
  (:import-from #:cl-s3r.cookie #:get-cookie))

(in-package #:todo-client/components/todo-form)

(define-component todo-form-page (&key error &allow-other-keys)
  (let ((token (get-cookie "todo-session")))
    (if (null token)
        `(:script "window.location.replace('/login');")
        `(:div
          (:div (@ (:class "header"))
            (:h1 "New TODO")
            (:a (@ (:href "/todos")) "<- Back to list"))
          ,@(when error `((:p (@ (:class "error")) ,error)))
          (:form (@ (:action "/todos") (:method "post"))
            (:label "Title *")
            (:input (@ (:type "text") (:name "subject") (:required "required") (:autofocus "autofocus")))
            (:label "Content")
            (:textarea (@ (:name "content") (:rows "5")) "")
            (:label "Deadline")
            (:input (@ (:type "date") (:name "deadline")))
            (:div
             (:button (@ (:type "submit")) "Create")
             " "
             (:a (@ (:href "/todos")) "Cancel")))))))
