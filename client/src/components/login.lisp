; -*- mode: lisp -*-
(in-package #:cl-user)
(defpackage #:todo-client/components/login
  (:use #:cl)
  (:import-from #:cl-s3r.component #:define-component))

(in-package #:todo-client/components/login)

(define-component login-page (&key error &allow-other-keys)
  `(:div
    (:h1 "Log In")
    ,@(when error
        `((:p (@ (:class "error")) "Invalid email or password")))
    (:form (@ (:action "/login") (:method "post"))
      (:label "Email")
      (:input (@ (:type "email") (:name "email") (:required "required") (:autofocus "autofocus")))
      (:label "Password")
      (:input (@ (:type "password") (:name "password") (:required "required")))
      (:button (@ (:type "submit")) "Log In"))
    (:p (:a (@ (:href "/signup")) "Don't have an account? Sign up"))))
