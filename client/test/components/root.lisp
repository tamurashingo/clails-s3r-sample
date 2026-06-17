; -*- mode: lisp -*-
(in-package #:cl-user)
(defpackage #:todo-client-test/components/root
  (:use #:cl #:rove)
  (:import-from #:cl-s3r.component
                #:*layout-registry*)
  (:import-from #:cl-s3r.testing
                #:test-render-component)
  (:import-from #:todo-client-test/helpers
                #:find-in-tree
                #:find-element))
(in-package #:todo-client-test/components/root)

(defun render-layout (name &rest args)
  (let* ((layout-info (gethash (string-downcase (string name)) *layout-registry*))
         (func-name (getf layout-info :name)))
    (unless func-name
      (error "Layout ~S not found" name))
    (apply (symbol-function func-name) args)))

(deftest test-app-layout
  (testing "top element is :html"
    (let* ((sexp (render-layout "app-layout" :children nil)))
      (ok (eq :html (car sexp)) "top element is :html")))

  (testing "has :head with title 'TODO App'"
    (let* ((sexp (render-layout "app-layout" :children nil))
           (head (find-element sexp :head)))
      (ok head "head element is present")
      (ok (find-in-tree head "TODO App") "title is 'TODO App'")))

  (testing "has :body"
    (let* ((sexp (render-layout "app-layout" :children nil)))
      (ok (find-element sexp :body) "body element is present")))

  (testing "body contains passed children"
    (let* ((children '(:p "Hello World"))
           (sexp (render-layout "app-layout" :children children))
           (body (find-element sexp :body)))
      (ok (find-in-tree body "Hello World") "children are rendered in body"))))

(deftest test-not-found-page
  (testing "renders 404 heading"
    (let* ((result (test-render-component "not-found-page" :args '()))
           (sexp (getf result :sexp)))
      (ok (find-in-tree sexp "404 - Not Found") "404 heading is shown")))

  (testing "renders message when provided"
    (let* ((result (test-render-component "not-found-page" :args '(:message "Item not found.")))
           (sexp (getf result :sexp)))
      (ok (find-in-tree sexp "Item not found.") "message is shown")))

  (testing "contains back link"
    (let* ((result (test-render-component "not-found-page" :args '()))
           (sexp (getf result :sexp)))
      (ok (find-in-tree sexp "/todos") "back link is present"))))

(deftest test-server-error-page
  (testing "renders 500 heading"
    (let* ((result (test-render-component "server-error-page" :args '()))
           (sexp (getf result :sexp)))
      (ok (find-in-tree sexp "500 - Internal Server Error") "500 heading is shown")))

  (testing "renders message when provided"
    (let* ((result (test-render-component "server-error-page" :args '(:message "Something went wrong.")))
           (sexp (getf result :sexp)))
      (ok (find-in-tree sexp "Something went wrong.") "message is shown")))

  (testing "contains back link"
    (let* ((result (test-render-component "server-error-page" :args '()))
           (sexp (getf result :sexp)))
      (ok (find-in-tree sexp "/todos") "back link is present"))))
