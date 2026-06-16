; -*- mode: lisp -*-
(in-package #:cl-user)
(defpackage #:todo-client-test/components/login
  (:use #:cl #:rove)
  (:import-from #:cl-s3r.testing
                #:test-render-component)
  (:import-from #:todo-client-test/helpers
                #:find-in-tree
                #:find-element))
(in-package #:todo-client-test/components/login)

(deftest test-login-page
  (testing "top element is :div"
    (let* ((result (test-render-component "login-page" :args (list nil)))
           (sexp (getf result :sexp)))
      (ok (eq :div (car sexp)) "top element is :div")))

  (testing "h1 shows 'Log In'"
    (let* ((result (test-render-component "login-page" :args (list nil)))
           (sexp (getf result :sexp)))
      (ok (equal '(:h1 "Log In") (second sexp)) "h1 is 'Log In'")))

  (testing "no error message without error arg"
    (let* ((result (test-render-component "login-page" :args (list nil)))
           (sexp (getf result :sexp)))
      (ok (not (find-in-tree sexp "Invalid email or password"))
          "error text is absent")))

  (testing "shows error message when error arg is truthy"
    (let* ((result (test-render-component "login-page" :args (list t)))
           (sexp (getf result :sexp)))
      (ok (find-in-tree sexp "Invalid email or password")
          "error text is present")))

  (testing "error paragraph has class 'error'"
    (let* ((result (test-render-component "login-page" :args (list t)))
           (sexp (getf result :sexp)))
      (ok (find-in-tree sexp '(:class "error")) "error class is present")))

  (testing "form action is /login"
    (let* ((result (test-render-component "login-page" :args (list nil)))
           (sexp (getf result :sexp))
           (form (find-element sexp :form)))
      (ok form "form element is present")
      (ok (find-in-tree form "/login") "form action is /login")))

  (testing "has link to /signup"
    (let* ((result (test-render-component "login-page" :args (list nil)))
           (sexp (getf result :sexp)))
      (ok (find-in-tree sexp "/signup") "signup link is present"))))
