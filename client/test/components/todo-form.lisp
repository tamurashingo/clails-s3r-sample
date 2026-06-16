; -*- mode: lisp -*-
(in-package #:cl-user)
(defpackage #:todo-client-test/components/todo-form
  (:use #:cl #:rove)
  (:import-from #:cl-s3r.testing
                #:test-render-component)
  (:import-from #:todo-client-test/helpers
                #:find-in-tree
                #:find-element))
(in-package #:todo-client-test/components/todo-form)

(deftest test-todo-form-page
  (testing "renders form"
    (let* ((result (test-render-component "todo-form-page" :args (list :error nil)))
           (sexp (getf result :sexp)))
      (ok (eq :div (car sexp)) "returns :div element")
      (ok (find-element sexp :form) "form element is present")))

  (testing "form action is /todos"
    (let* ((result (test-render-component "todo-form-page" :args (list :error nil)))
           (sexp (getf result :sexp))
           (form (find-element sexp :form)))
      (ok (find-in-tree form "/todos") "form action is /todos")))

  (testing "no error paragraph without error arg"
    (let* ((result (test-render-component "todo-form-page" :args (list :error nil)))
           (sexp (getf result :sexp)))
      (ok (not (find-in-tree sexp '(:class "error")))
          "no error class present")))

  (testing "shows error message when error arg is provided"
    (let* ((result (test-render-component "todo-form-page"
                                          :args (list :error "Title is required")))
           (sexp (getf result :sexp)))
      (ok (find-in-tree sexp "Title is required") "error message is shown")
      (ok (find-in-tree sexp '(:class "error")) "error class is present"))))
