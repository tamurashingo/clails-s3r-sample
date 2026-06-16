; -*- mode: lisp -*-
(in-package #:cl-user)
(defpackage #:todo-server-test/controllers/sessions-controller
  (:use #:cl
        #:rove)
  (:import-from #:clails/test
                #:deftest-suite)
  (:import-from #:todo-server/controllers/sessions-controller
                #:<sessions-controller>)
  (:import-from #:clails/controller/base-controller
                #:do-post
                #:do-delete
                #:response)
  (:import-from #:todo-server/models/user
                #:create-user)
  (:import-from #:todo-server/models/session
                #:create-session
                #:find-session-by-token)
  (:import-from #:clails/model
                #:ref
                #:destroy)
  (:import-from #:babel
                #:string-to-octets)
  (:import-from #:flexi-streams
                #:make-in-memory-input-stream))
(in-package #:todo-server-test/controllers/sessions-controller)

(defun make-json-env (json-string &optional auth-token)
  (let* ((bytes (string-to-octets json-string :encoding :utf-8))
         (headers (make-hash-table :test 'equal)))
    (when auth-token
      (setf (gethash "authorization" headers)
            (format nil "Bearer ~A" auth-token)))
    (list :raw-body (make-in-memory-input-stream bytes)
          :content-length (length bytes)
          :headers headers)))

(deftest-suite :controller test-post-sessions
  (testing "success: returns token and user data"
    (let ((user (create-user "loginuser" "loginuser@example.com" "pass123")))
      (unwind-protect
           (let ((c (make-instance '<sessions-controller>)))
             (setf (slot-value c 'clails/controller/base-controller::env)
                   (make-json-env "{\"email\":\"loginuser@example.com\",\"password\":\"pass123\"}"))
             (do-post c)
             (let ((resp (response c)))
               (ok resp "response is non-nil")
               (ok (assoc "token" resp :test #'string=) "response has token")
               (ok (= 64 (length (cdr (assoc "token" resp :test #'string=)))) "token is 64 characters")
               (ok (string= "loginuser" (cdr (assoc "username" resp :test #'string=))) "username matches")
               ;; cleanup session created by controller
               (let ((token (cdr (assoc "token" resp :test #'string=))))
                 (when token
                   (let ((session (find-session-by-token token)))
                     (when session (destroy session)))))))
        (when user (destroy user)))))

  (testing "missing email: returns 400"
    (let ((c (make-instance '<sessions-controller>)))
      (setf (slot-value c 'clails/controller/base-controller::env)
            (make-json-env "{\"password\":\"pass123\"}"))
      (do-post c)
      (ok (= 400 (slot-value c 'clails/controller/base-controller::code)) "returns 400")
      (ok (assoc "error" (response c) :test #'string=) "response has error key")))

  (testing "missing password: returns 400"
    (let ((c (make-instance '<sessions-controller>)))
      (setf (slot-value c 'clails/controller/base-controller::env)
            (make-json-env "{\"email\":\"x@example.com\"}"))
      (do-post c)
      (ok (= 400 (slot-value c 'clails/controller/base-controller::code)) "returns 400")))

  (testing "invalid credentials: returns 401"
    (let ((user (create-user "authfail" "authfail@example.com" "correct")))
      (unwind-protect
           (let ((c (make-instance '<sessions-controller>)))
             (setf (slot-value c 'clails/controller/base-controller::env)
                   (make-json-env "{\"email\":\"authfail@example.com\",\"password\":\"wrong\"}"))
             (do-post c)
             (ok (= 401 (slot-value c 'clails/controller/base-controller::code)) "returns 401")
             (ok (string= "invalid email or password"
                          (cdr (assoc "error" (response c) :test #'string=)))
                 "correct error message"))
        (when user (destroy user)))))

  (testing "nonexistent email: returns 401"
    (let ((c (make-instance '<sessions-controller>)))
      (setf (slot-value c 'clails/controller/base-controller::env)
            (make-json-env "{\"email\":\"nobody@example.com\",\"password\":\"pass\"}"))
      (do-post c)
      (ok (= 401 (slot-value c 'clails/controller/base-controller::code)) "returns 401"))))

(deftest-suite :controller test-delete-sessions
  (testing "success: returns logged out message"
    (let ((user (create-user "logoutuser" "logoutuser@example.com" "pass123")))
      (unwind-protect
           (let* ((session (create-session (ref user :id)))
                  (token (ref session :token))
                  (c (make-instance '<sessions-controller>)))
             (setf (slot-value c 'clails/controller/base-controller::env)
                   (make-json-env "{}" token))
             (do-delete c)
             (ok (string= "logged out"
                          (cdr (assoc "message" (response c) :test #'string=)))
                 "returns logged out message")
             (ok (null (find-session-by-token token)) "session is deleted"))
        (when user (destroy user)))))

  (testing "no token: returns 401"
    (let ((c (make-instance '<sessions-controller>)))
      (setf (slot-value c 'clails/controller/base-controller::env)
            (make-json-env "{}"))
      (do-delete c)
      (ok (= 401 (slot-value c 'clails/controller/base-controller::code)) "returns 401")
      (ok (string= "unauthorized"
                   (cdr (assoc "error" (response c) :test #'string=)))
          "returns unauthorized error"))))
