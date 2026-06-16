; -*- mode: lisp -*-
(in-package #:cl-user)
(defpackage #:todo-client/components/signup
  (:use #:cl)
  (:import-from #:cl-s3r.component #:define-component))

(in-package #:todo-client/components/signup)

(define-component signup-page (error)
  `(:div
    (:h1 "Sign Up")
    ,@(when error
        `((:p (@ (:class "error")) ,error)))
    (:form (@ (:action "/signup") (:method "post"))
      (:label "Username")
      (:input (@ (:type "text") (:name "username") (:required "required")))
      (:label "Email")
      (:input (@ (:type "email") (:name "email") (:required "required")))
      (:label "Password")
      (:input (@ (:type "password") (:name "password") (:required "required")))
      (:button (@ (:type "submit")) "Sign Up"))
    (:p (:a (@ (:href "/login")) "Already have an account? Log in"))))
