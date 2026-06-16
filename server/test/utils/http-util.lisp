; -*- mode: lisp -*-
(in-package #:cl-user)
(defpackage #:todo-server-test/utils/http-util
  (:use #:cl
        #:rove)
  (:import-from #:clails/test
                #:deftest-suite)
  (:import-from #:todo-server/utils/http-util
                #:parse-json-body
                #:extract-bearer-token
                #:authenticate-request
                #:set-code)
  (:import-from #:todo-server/models/user
                #:create-user)
  (:import-from #:todo-server/models/session
                #:create-session
                #:delete-session-by-token)
  (:import-from #:todo-server/controllers/users-controller
                #:<users-controller>)
  (:import-from #:clails/model
                #:ref
                #:destroy)
  (:import-from #:babel
                #:string-to-octets)
  (:import-from #:flexi-streams
                #:make-in-memory-input-stream))
(in-package #:todo-server-test/utils/http-util)

(defun make-body-env (json-string)
  (let* ((bytes (string-to-octets json-string :encoding :utf-8)))
    (list :raw-body (make-in-memory-input-stream bytes)
          :content-length (length bytes)
          :headers (make-hash-table :test 'equal))))

(defun make-headers-env (&rest header-pairs)
  (let ((headers (make-hash-table :test 'equal)))
    (loop for (key val) on header-pairs by #'cddr
          do (setf (gethash key headers) val))
    (list :headers headers
          :content-length 0)))


;;; parse-json-body

(deftest-suite :utils test-parse-json-body
  (testing "returns nil when no :raw-body in env"
    (ok (null (parse-json-body '(:content-length 5)))
        "nil when :raw-body is absent"))

  (testing "returns nil when :content-length is 0"
    (ok (null (parse-json-body (list :raw-body (make-in-memory-input-stream #())
                                     :content-length 0)))
        "nil when content-length is 0"))

  (testing "returns nil when :content-length is absent"
    (ok (null (parse-json-body (list :raw-body (make-in-memory-input-stream #()))))
        "nil when :content-length is absent"))

  (testing "returns parsed plist for valid JSON object"
    (let* ((env (make-body-env "{\"username\":\"alice\",\"email\":\"alice@example.com\"}"))
           (result (parse-json-body env)))
      (ok result "returns non-nil result")
      (ok (string= "alice" (getf result :|username|)) "username is parsed")
      (ok (string= "alice@example.com" (getf result :|email|)) "email is parsed")))

  (testing "returns parsed plist for JSON with numeric value"
    (let* ((env (make-body-env "{\"count\":42}"))
           (result (parse-json-body env)))
      (ok (= 42 (getf result :|count|)) "numeric value is parsed"))))


;;; extract-bearer-token

(deftest-suite :utils test-extract-bearer-token
  (testing "returns nil when Authorization header is absent"
    (ok (null (extract-bearer-token (make-headers-env)))
        "nil when no Authorization header"))

  (testing "returns nil when Authorization header is not Bearer"
    (ok (null (extract-bearer-token
               (make-headers-env "authorization" "Basic dXNlcjpwYXNz")))
        "nil for Basic auth"))

  (testing "returns nil when Authorization header is too short"
    (ok (null (extract-bearer-token
               (make-headers-env "authorization" "Bearer")))
        "nil for 'Bearer' with no token"))

  (testing "returns token string for valid Bearer header"
    (ok (string= "mytoken123"
                 (extract-bearer-token
                  (make-headers-env "authorization" "Bearer mytoken123")))
        "extracts token correctly"))

  (testing "trims surrounding whitespace from token"
    (ok (string= "trimmedtoken"
                 (extract-bearer-token
                  (make-headers-env "authorization" "Bearer  trimmedtoken ")))
        "leading/trailing spaces are trimmed")))


;;; authenticate-request

(deftest-suite :utils test-authenticate-request
  (testing "returns nil when no Authorization header"
    (ok (null (authenticate-request (make-headers-env)))
        "nil when no token in env"))

  (testing "returns nil for unknown token"
    (ok (null (authenticate-request
               (make-headers-env "authorization"
                "Bearer 0000000000000000000000000000000000000000000000000000000000000000")))
        "nil for unknown token"))

  (testing "returns session for valid token"
    (let ((user (create-user "authrequser" "authrequser@example.com" "pass123")))
      (unwind-protect
           (let* ((session (create-session (ref user :id)))
                  (token (ref session :token))
                  (env (make-headers-env "authorization"
                                         (format nil "Bearer ~A" token)))
                  (result (authenticate-request env)))
             (ok result "returns non-nil session")
             (ok (string= token (ref result :token)) "session token matches"))
        (when user (destroy user))))))


