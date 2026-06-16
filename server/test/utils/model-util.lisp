; -*- mode: lisp -*-
(in-package #:cl-user)
(defpackage #:todo-server-test/utils/model-util
  (:use #:cl
        #:rove)
  (:import-from #:clails/test
                #:deftest-suite)
  (:import-from #:todo-server/utils/model-util
                #:generate-ulid
                #:generate-token
                #:hash-password
                #:verify-password))
(in-package #:todo-server-test/utils/model-util)

(deftest-suite :utils test-generate-ulid
  (testing "generate-ulid returns a 26-character string"
    (let ((ulid (generate-ulid)))
      (ok (stringp ulid) "returns a string")
      (ok (= 26 (length ulid)) "length is 26")))

  (testing "generate-ulid returns unique values"
    (ok (string/= (generate-ulid) (generate-ulid))
        "two calls produce different ULIDs")))

(deftest-suite :utils test-generate-token
  (testing "generate-token returns a 64-character string"
    (let ((token (generate-token)))
      (ok (stringp token) "returns a string")
      (ok (= 64 (length token)) "length is 64")))

  (testing "generate-token returns unique values"
    (ok (string/= (generate-token) (generate-token))
        "two calls produce different tokens")))

(deftest-suite :utils test-hash-password
  (testing "hash-password returns a non-empty string"
    (let ((hash (hash-password "secret")))
      (ok (stringp hash) "returns a string")
      (ok (> (length hash) 0) "hash is non-empty")))

  (testing "two hashes of the same password differ due to random salt"
    (ok (string/= (hash-password "secret") (hash-password "secret"))
        "different hashes for the same password")))

(deftest-suite :utils test-verify-password
  (testing "verify-password returns T for the correct password"
    (let ((hash (hash-password "correct-password")))
      (ok (verify-password "correct-password" hash)
          "correct password verifies successfully")))

  (testing "verify-password returns nil for a wrong password"
    (let ((hash (hash-password "correct-password")))
      (ok (null (verify-password "wrong-password" hash))
          "wrong password fails verification")))

  (testing "verify-password returns nil for an invalid hash without signaling"
    (ok (null (verify-password "any" "not-a-valid-hash"))
        "invalid hash returns nil without error")))
