; -*- mode: lisp -*-
(in-package #:cl-user)
(defpackage #:todo-server-test/models/sessions
  (:use #:cl
        #:rove)
  (:import-from #:clails/test
                #:deftest-suite)
  (:import-from #:todo-server/models/user
                #:create-user)
  (:import-from #:todo-server/models/session
                #:create-session
                #:find-session-by-token
                #:delete-session-by-token)
  (:import-from #:clails/model
                #:ref
                #:destroy))
(in-package #:todo-server-test/models/sessions)

(deftest-suite :model test-create-session
  (testing "create-session creates a session with expected fields"
    (let ((user (create-user "sessionuser" "sessionuser@example.com" "password123")))
      (unwind-protect
           (let ((session (create-session (ref user :id))))
             (ok session "session is created")
             (ok (= 64 (length (ref session :token))) "token is 64 characters")
             (ok (= 26 (length (ref session :ulid))) "ULID is 26 characters")
             (ok (> (ref session :expires-at) (get-universal-time))
                 "expires-at is in the future")
             (when session (delete-session-by-token (ref session :token))))
        (when user (destroy user))))))

(deftest-suite :model test-find-session-by-token
  (testing "find-session-by-token returns the session for a valid token"
    (let ((user (create-user "findssuser" "findssuser@example.com" "password123")))
      (unwind-protect
           (let ((session (create-session (ref user :id))))
             (let ((found (find-session-by-token (ref session :token))))
               (ok found "returns a session")
               (ok (string= (ref session :token) (ref found :token)) "token matches"))
             (when session (delete-session-by-token (ref session :token))))
        (when user (destroy user)))))

  (testing "find-session-by-token returns nil for an unknown token"
    (ok (null (find-session-by-token
               "0000000000000000000000000000000000000000000000000000000000000000"))
        "returns nil for unknown token")))

(deftest-suite :model test-delete-session-by-token
  (testing "delete-session-by-token removes the session"
    (let ((user (create-user "deletessuser" "deletessuser@example.com" "password123")))
      (unwind-protect
           (let ((session (create-session (ref user :id))))
             (let ((token (ref session :token)))
               (ok (delete-session-by-token token) "returns T on success")
               (ok (null (find-session-by-token token))
                   "session is no longer found after deletion")))
        (when user (destroy user)))))

  (testing "delete-session-by-token returns nil for a nonexistent token"
    (ok (null (delete-session-by-token
               "0000000000000000000000000000000000000000000000000000000000000000"))
        "returns nil for unknown token")))
