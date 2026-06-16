; -*- mode: lisp -*-
(in-package #:cl-user)
(defpackage #:todo-client-test/components/signup
  (:use #:cl #:rove)
  (:import-from #:cl-s3r.testing
                #:test-render-component)
  (:import-from #:todo-client-test/helpers
                #:find-in-tree
                #:find-element))
(in-package #:todo-client-test/components/signup)

(deftest test-signup-page
  (testing "top element is :div"
    (let* ((result (test-render-component "signup-page" :args (list :error nil)))
           (sexp (getf result :sexp)))
      (ok (eq :div (car sexp)) "top element is :div")))

  (testing "h1 shows 'Sign Up'"
    (let* ((result (test-render-component "signup-page" :args (list :error nil)))
           (sexp (getf result :sexp)))
      (ok (equal '(:h1 "Sign Up") (second sexp)) "h1 is 'Sign Up'")))

  (testing "no error paragraph without error arg"
    (let* ((result (test-render-component "signup-page" :args (list :error nil)))
           (sexp (getf result :sexp)))
      (ok (not (find-in-tree sexp '(:class "error")))
          "error class is absent")))

  (testing "shows provided error string"
    (let* ((result (test-render-component "signup-page"
                                          :args (list :error "Email already taken")))
           (sexp (getf result :sexp)))
      (ok (find-in-tree sexp "Email already taken")
          "error message is present")))

  (testing "error paragraph has class 'error'"
    (let* ((result (test-render-component "signup-page"
                                          :args (list :error "Some error")))
           (sexp (getf result :sexp)))
      (ok (find-in-tree sexp '(:class "error")) "error class is present")))

  (testing "form action is /signup"
    (let* ((result (test-render-component "signup-page" :args (list :error nil)))
           (sexp (getf result :sexp))
           (form (find-element sexp :form)))
      (ok form "form element is present")
      (ok (find-in-tree form "/signup") "form action is /signup")))

  (testing "has link to /login"
    (let* ((result (test-render-component "signup-page" :args (list :error nil)))
           (sexp (getf result :sexp)))
      (ok (find-in-tree sexp "/login") "login link is present"))))
