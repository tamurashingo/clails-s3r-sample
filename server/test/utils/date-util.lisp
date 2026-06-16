; -*- mode: lisp -*-
(in-package #:cl-user)
(defpackage #:todo-server-test/utils/date-util
  (:use #:cl
        #:rove)
  (:import-from #:clails/test
                #:deftest-suite)
  (:import-from #:todo-server/utils/date-util
                #:parse-deadline))
(in-package #:todo-server-test/utils/date-util)

(deftest-suite :utils test-parse-deadline-nil-and-non-string
  (testing "nil and non-string inputs return nil"
    (ok (null (parse-deadline nil)) "nil input returns nil")
    (ok (null (parse-deadline 42)) "integer input returns nil")
    (ok (null (parse-deadline "")) "empty string returns nil")))

(deftest-suite :utils test-parse-deadline-invalid
  (testing "invalid string returns nil without signaling"
    (ok (null (parse-deadline "not-a-date")) "invalid string returns nil")))

(deftest-suite :utils test-parse-deadline-valid
  (testing "full ISO8601 format returns a universal-time integer"
    (let ((result (parse-deadline "2026-06-15T10:30:00")))
      (ok (integerp result) "returns an integer")))

  (testing "datetime-local format (no seconds) returns a universal-time integer"
    (let ((result (parse-deadline "2026-06-15T10:30")))
      (ok (integerp result) "returns an integer")))

  (testing "datetime-local and full format produce the same value"
    (ok (= (parse-deadline "2026-06-15T10:30")
           (parse-deadline "2026-06-15T10:30:00"))
        "appending :00 produces identical result")))
