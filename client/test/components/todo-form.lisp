; -*- mode: lisp -*-
(in-package #:cl-user)
(defpackage #:todo-client-test/components/todo-form
  (:use #:cl #:rove)
  (:import-from #:cl-s3r.testing
                #:test-render-component)
  (:import-from #:cl-s3r.cookie
                #:*current-cookies*)
  (:import-from #:todo-client-test/helpers
                #:find-in-tree
                #:string-in-tree-p
                #:find-element))
(in-package #:todo-client-test/components/todo-form)

(deftest test-todo-form-page
  (testing "redirects to /login when no session cookie"
    (let ((*current-cookies* nil))
      (let* ((result (test-render-component "todo-form-page" :args (list :error nil)))
             (sexp (getf result :sexp)))
        (ok (eq :script (car sexp)) "returns :script element")
        (ok (string-in-tree-p sexp "/login") "redirects to /login"))))

  (testing "renders form when session cookie is present"
    (let ((*current-cookies* '(("todo-session" . "faketoken"))))
      (let* ((result (test-render-component "todo-form-page" :args (list :error nil)))
             (sexp (getf result :sexp)))
        (ok (eq :div (car sexp)) "returns :div element")
        (ok (find-element sexp :form) "form element is present"))))

  (testing "form action is /todos"
    (let ((*current-cookies* '(("todo-session" . "faketoken"))))
      (let* ((result (test-render-component "todo-form-page" :args (list :error nil)))
             (sexp (getf result :sexp))
             (form (find-element sexp :form)))
        (ok (find-in-tree form "/todos") "form action is /todos"))))

  (testing "no error paragraph without error arg"
    (let ((*current-cookies* '(("todo-session" . "faketoken"))))
      (let* ((result (test-render-component "todo-form-page" :args (list :error nil)))
             (sexp (getf result :sexp)))
        (ok (not (find-in-tree sexp '(:class "error")))
            "no error class present"))))

  (testing "shows error message when error arg is provided"
    (let ((*current-cookies* '(("todo-session" . "faketoken"))))
      (let* ((result (test-render-component "todo-form-page"
                                            :args (list :error "Title is required")))
             (sexp (getf result :sexp)))
        (ok (find-in-tree sexp "Title is required") "error message is shown")
        (ok (find-in-tree sexp '(:class "error")) "error class is present")))))
