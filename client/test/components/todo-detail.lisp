; -*- mode: lisp -*-
(in-package #:cl-user)
(defpackage #:todo-client-test/components/todo-detail
  (:use #:cl #:rove)
  (:import-from #:cl-s3r.testing
                #:test-render-component)
  (:import-from #:cl-s3r.component
                #:http-error
                #:http-error-status-code
                #:http-error-params)
  (:import-from #:cl-s3r.cookie
                #:*current-cookies*
                #:*pending-cookie-changes*)
  (:import-from #:cl-s3r.session
                #:*session-secret*
                #:create-session-for-test
                #:reset-session-store!)
  (:import-from #:todo-client-test/helpers
                #:find-in-tree
                #:find-element
                #:with-mock-fn))
(in-package #:todo-client-test/components/todo-detail)

(defparameter +mock-todo-json+
  "{\"ulid\":\"01HGWPF3MCKYVHMDZRQT4WVJDS\",\"subject\":\"Test Todo\",\"content\":\"Some content\"}")

(defun reset-test-state ()
  (reset-session-store!)
  (setf *session-secret* "test-secret"))

(deftest test-todo-detail-page
  (testing "signals 404 when ulid is nil"
    (reset-test-state)
    (let ((session-cookie (create-session-for-test '(:token "faketoken"))))
      (let ((*current-cookies* (list session-cookie))
            (*pending-cookie-changes* nil))
        (let ((error-raised nil)
              (error-status nil))
          (handler-case
            (test-render-component "todo-detail-page"
                                   :args (list :ulid nil :mode nil :error nil))
            (http-error (e)
              (setf error-raised t)
              (setf error-status (http-error-status-code e))))
          (ok error-raised "http-error is signaled")
          (ok (= 404 error-status) "status code is 404")))))

  (testing "signals 404 when API fails"
    (reset-test-state)
    (let ((session-cookie (create-session-for-test '(:token "faketoken"))))
      (let ((*current-cookies* (list session-cookie))
            (*pending-cookie-changes* nil))
        (let ((error-raised nil)
              (error-status nil))
          ;; api-get fails (connection refused) -> handler-case -> todo = nil -> signal-http-error
          (handler-case
            (test-render-component "todo-detail-page"
                                   :args (list :ulid "00000000000000000000000000" :mode nil :error nil))
            (http-error (e)
              (setf error-raised t)
              (setf error-status (http-error-status-code e))))
          (ok error-raised "http-error is signaled")
          (ok (= 404 error-status) "status code is 404")))))

  (testing "renders detail view with todo subject"
    (reset-test-state)
    (let ((session-cookie (create-session-for-test '(:token "faketoken"))))
      (let ((*current-cookies* (list session-cookie))
            (*pending-cookie-changes* nil))
        (with-mock-fn (todo-client/api-client:api-get
                       (lambda (path token)
                         (declare (ignore path token))
                         +mock-todo-json+))
          (let* ((result (test-render-component "todo-detail-page"
                                                :args (list :ulid "01HGWPF3MCKYVHMDZRQT4WVJDS" :mode nil :error nil)))
                 (sexp (getf result :sexp)))
            (ok (find-in-tree sexp "Test Todo") "todo subject is shown")
            (ok (find-in-tree sexp "Not completed") "completion status is shown"))))))

  (testing "renders detail view with back link"
    (reset-test-state)
    (let ((session-cookie (create-session-for-test '(:token "faketoken"))))
      (let ((*current-cookies* (list session-cookie))
            (*pending-cookie-changes* nil))
        (with-mock-fn (todo-client/api-client:api-get
                       (lambda (path token)
                         (declare (ignore path token))
                         +mock-todo-json+))
          (let* ((result (test-render-component "todo-detail-page"
                                                :args (list :ulid "01HGWPF3MCKYVHMDZRQT4WVJDS" :mode nil :error nil)))
                 (sexp (getf result :sexp)))
            (ok (find-in-tree sexp "/todos") "back to list link is present"))))))

  (testing "renders edit form in edit mode"
    (reset-test-state)
    (let ((session-cookie (create-session-for-test '(:token "faketoken"))))
      (let ((*current-cookies* (list session-cookie))
            (*pending-cookie-changes* nil))
        (with-mock-fn (todo-client/api-client:api-get
                       (lambda (path token)
                         (declare (ignore path token))
                         +mock-todo-json+))
          (let* ((result (test-render-component "todo-detail-page"
                                                :args (list :ulid "01HGWPF3MCKYVHMDZRQT4WVJDS" :mode "edit" :error nil)))
                 (sexp (getf result :sexp)))
            (ok (find-in-tree sexp "Edit TODO") "edit form header is shown")
            (ok (find-element sexp :form) "form element is present"))))))

  (testing "edit form contains todo subject as input value"
    (reset-test-state)
    (let ((session-cookie (create-session-for-test '(:token "faketoken"))))
      (let ((*current-cookies* (list session-cookie))
            (*pending-cookie-changes* nil))
        (with-mock-fn (todo-client/api-client:api-get
                       (lambda (path token)
                         (declare (ignore path token))
                         +mock-todo-json+))
          (let* ((result (test-render-component "todo-detail-page"
                                                :args (list :ulid "01HGWPF3MCKYVHMDZRQT4WVJDS" :mode "edit" :error nil)))
                 (sexp (getf result :sexp)))
            (ok (find-in-tree sexp "Test Todo") "input has todo subject value"))))))

  (testing "shows error message in detail view when error arg is provided"
    (reset-test-state)
    (let ((session-cookie (create-session-for-test '(:token "faketoken"))))
      (let ((*current-cookies* (list session-cookie))
            (*pending-cookie-changes* nil))
        (with-mock-fn (todo-client/api-client:api-get
                       (lambda (path token)
                         (declare (ignore path token))
                         +mock-todo-json+))
          (let* ((result (test-render-component "todo-detail-page"
                                                :args (list :ulid "01HGWPF3MCKYVHMDZRQT4WVJDS" :mode nil :error "Update failed")))
                 (sexp (getf result :sexp)))
            (ok (find-in-tree sexp "Update failed") "error message is shown")))))))
