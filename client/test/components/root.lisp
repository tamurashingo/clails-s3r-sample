; -*- mode: lisp -*-
(in-package #:cl-user)
(defpackage #:todo-client-test/components/root
  (:use #:cl #:rove)
  (:import-from #:cl-s3r.testing
                #:test-render-component)
  (:import-from #:todo-client-test/helpers
                #:find-in-tree
                #:find-element))
(in-package #:todo-client-test/components/root)

(deftest test-root
  (testing "top element is :html"
    (let* ((result (test-render-component "root" :args (list :children nil)))
           (sexp (getf result :sexp)))
      (ok (eq :html (car sexp)) "top element is :html")))

  (testing "has :head with title 'TODO App'"
    (let* ((result (test-render-component "root" :args (list :children nil)))
           (sexp (getf result :sexp))
           (head (find-element sexp :head)))
      (ok head "head element is present")
      (ok (find-in-tree head "TODO App") "title is 'TODO App'")))

  (testing "has :body"
    (let* ((result (test-render-component "root" :args (list :children nil)))
           (sexp (getf result :sexp)))
      (ok (find-element sexp :body) "body element is present")))

  (testing "body contains passed children"
    (let* ((children '(:p "Hello World"))
           (result (test-render-component "root" :args (list :children children)))
           (sexp (getf result :sexp))
           (body (find-element sexp :body)))
      (ok (find-in-tree body "Hello World") "children are rendered in body"))))
