; -*- mode: lisp -*-
(in-package #:cl-user)
(defpackage #:todo-client-test/components/todo-list
  (:use #:cl #:rove)
  (:import-from #:cl-s3r.testing
                #:test-render-component
                #:test-call-action
                #:test-get-state)
  (:import-from #:cl-s3r.cookie
                #:*current-cookies*)
  (:import-from #:todo-client-test/helpers
                #:find-in-tree
                #:string-in-tree-p
                #:find-element
                #:with-mock-fn))
(in-package #:todo-client-test/components/todo-list)

(deftest test-todo-list-page
  (testing "redirects to /login when no session cookie"
    (let ((*current-cookies* nil))
      (let* ((result (test-render-component "todo-list-page"))
             (sexp (getf result :sexp)))
        (ok (eq :script (car sexp)) "returns :script element")
        (ok (string-in-tree-p sexp "/login") "redirects to /login"))))

  (testing "shows 'No TODOs yet' when API fails (no server)"
    (let ((*current-cookies* '(("todo-session" . "faketoken"))))
      (let* ((result (test-render-component "todo-list-page"))
             (sexp (getf result :sexp)))
        (ok (eq :div (car sexp)) "returns :div element")
        (ok (find-in-tree sexp "No TODOs yet") "shows no todos message"))))

  (testing "shows todo list when API returns todos"
    (let ((*current-cookies* '(("todo-session" . "faketoken"))))
      (with-mock-fn (todo-client/api-client:api-get
                     (lambda (path token)
                       (declare (ignore path token))
                       "[{\"ulid\":\"01HGWPF3MCKYVHMDZRQT4WVJDS\",\"subject\":\"Buy milk\",\"completed\":false}]"))
        (let* ((result (test-render-component "todo-list-page"))
               (sexp (getf result :sexp)))
          (ok (find-in-tree sexp "Buy milk") "todo subject is rendered")))))

  (testing "initial show-modal state is nil"
    (let ((*current-cookies* '(("todo-session" . "faketoken"))))
      (let* ((result (test-render-component "todo-list-page"))
             (state (getf result :state)))
        (ok (null (test-get-state state :show-modal))
            "show-modal is initially nil"))))

  (testing "modal is hidden initially (display:none)"
    (let ((*current-cookies* '(("todo-session" . "faketoken"))))
      (let* ((result (test-render-component "todo-list-page"))
             (sexp (getf result :sexp)))
        (ok (find-in-tree sexp "display:none") "modal style is display:none"))))

  (testing "open-modal action sets show-modal to t"
    (let ((*current-cookies* '(("todo-session" . "faketoken"))))
      (let* ((r1 (test-render-component "todo-list-page"))
             (r2 (test-call-action "todo-list-page" "open-modal"
                                   :state (getf r1 :state))))
        (ok (test-get-state (getf r2 :state) :show-modal)
            "show-modal is t after open-modal"))))

  (testing "open-modal makes modal visible (display:flex)"
    (let ((*current-cookies* '(("todo-session" . "faketoken"))))
      (let* ((r1 (test-render-component "todo-list-page"))
             (r2 (test-call-action "todo-list-page" "open-modal"
                                   :state (getf r1 :state)))
             (sexp (getf r2 :sexp)))
        (ok (find-in-tree sexp "display:flex") "modal style is display:flex"))))

  (testing "close-modal action sets show-modal back to nil"
    (let ((*current-cookies* '(("todo-session" . "faketoken"))))
      (let* ((r1 (test-render-component "todo-list-page"))
             (r2 (test-call-action "todo-list-page" "open-modal"
                                   :state (getf r1 :state)))
             (r3 (test-call-action "todo-list-page" "close-modal"
                                   :state (getf r2 :state))))
        (ok (null (test-get-state (getf r3 :state) :show-modal))
            "show-modal is nil after close-modal"))))

  (testing "close-modal hides modal again (display:none)"
    (let ((*current-cookies* '(("todo-session" . "faketoken"))))
      (let* ((r1 (test-render-component "todo-list-page"))
             (r2 (test-call-action "todo-list-page" "open-modal"
                                   :state (getf r1 :state)))
             (r3 (test-call-action "todo-list-page" "close-modal"
                                   :state (getf r2 :state)))
             (sexp (getf r3 :sexp)))
        (ok (find-in-tree sexp "display:none") "modal style is display:none after close")))))
