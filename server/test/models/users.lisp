; -*- mode: lisp -*-
(in-package #:cl-user)
(defpackage #:todo-server-test/models/users
  (:use #:cl
        #:rove)
  (:import-from #:clails/test
                #:deftest-suite)
  (:import-from #:todo-server/models/user
                #:create-user
                #:find-user-by-email
                #:find-user-by-ulid
                #:user-exists-p)
  (:import-from #:clails/model
                #:ref
                #:destroy))
(in-package #:todo-server-test/models/users)

(deftest-suite :model test-create-user
  (testing "create-user creates a user with expected fields"
    (let ((user (create-user "testuser" "testuser@example.com" "password123")))
      (unwind-protect
           (progn
             (ok user "user is created")
             (ok (ref user :id) "user has an id")
             (ok (string= "testuser" (ref user :username)) "username matches")
             (ok (string= "testuser@example.com" (ref user :email)) "email matches")
             (ok (= 26 (length (ref user :ulid))) "ULID is 26 characters")
             (ok (not (string= "password123" (ref user :password-digest)))
                 "password is stored as a hash"))
        (when user (destroy user))))))

(deftest-suite :model test-find-user-by-email
  (testing "find-user-by-email returns user for existing email"
    (let ((user (create-user "finduser" "finduser@example.com" "password123")))
      (unwind-protect
           (let ((found (find-user-by-email "finduser@example.com")))
             (ok found "returns a user")
             (ok (string= "finduser@example.com" (ref found :email)) "email matches"))
        (when user (destroy user)))))

  (testing "find-user-by-email returns nil for nonexistent email"
    (ok (null (find-user-by-email "no-such@example.com"))
        "returns nil for unknown email")))

(deftest-suite :model test-find-user-by-ulid
  (testing "find-user-by-ulid returns user for existing ULID"
    (let ((user (create-user "uliduser" "uliduser@example.com" "password123")))
      (unwind-protect
           (let ((found (find-user-by-ulid (ref user :ulid))))
             (ok found "returns a user")
             (ok (string= (ref user :ulid) (ref found :ulid)) "ULID matches"))
        (when user (destroy user)))))

  (testing "find-user-by-ulid returns nil for nonexistent ULID"
    (ok (null (find-user-by-ulid "00000000000000000000000000"))
        "returns nil for unknown ULID")))

(deftest-suite :model test-user-exists-p
  (testing "user-exists-p returns T when email exists"
    (let ((user (create-user "existsuser" "exists@example.com" "password123")))
      (unwind-protect
           (ok (user-exists-p "exists@example.com") "returns T for existing email")
        (when user (destroy user)))))

  (testing "user-exists-p returns nil when email does not exist"
    (ok (null (user-exists-p "nobody@example.com"))
        "returns nil for unknown email")))
