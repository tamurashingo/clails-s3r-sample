; -*- mode: lisp -*-
(in-package #:cl-user)
(defpackage #:todo-server-test/controllers/users-controller
  (:use #:cl
        #:rove)
  (:import-from #:clails/test
                #:deftest-suite)
  (:import-from #:todo-server/controllers/users-controller
                #:<users-controller>)
  (:import-from #:clails/controller/base-controller
                #:do-post
                #:response)
  (:import-from #:todo-server/models/user
                #:find-user-by-email)
  (:import-from #:clails/model
                #:destroy)
  (:import-from #:babel
                #:string-to-octets)
  (:import-from #:flexi-streams
                #:make-in-memory-input-stream))
(in-package #:todo-server-test/controllers/users-controller)

(defun make-json-env (json-string)
  (let* ((bytes (string-to-octets json-string :encoding :utf-8))
         (headers (make-hash-table :test 'equal)))
    (list :raw-body (make-in-memory-input-stream bytes)
          :content-length (length bytes)
          :headers headers)))

(deftest-suite :controller test-post-users
  (testing "success: returns 201 with user data"
    (let ((c (make-instance '<users-controller>)))
      (setf (slot-value c 'clails/controller/base-controller::env)
            (make-json-env "{\"username\":\"newuser\",\"email\":\"newuser@example.com\",\"password\":\"pass123\"}"))
      (do-post c)
      (unwind-protect
           (let ((resp (response c)))
             (ok (= 201 (slot-value c 'clails/controller/base-controller::code)) "returns 201")
             (ok (assoc "ulid" resp :test #'string=) "response has ulid")
             (ok (string= "newuser" (cdr (assoc "username" resp :test #'string=))) "username matches")
             (ok (string= "newuser@example.com" (cdr (assoc "email" resp :test #'string=))) "email matches"))
        (let ((user (find-user-by-email "newuser@example.com")))
          (when user (destroy user))))))

  (testing "missing username: returns 400"
    (let ((c (make-instance '<users-controller>)))
      (setf (slot-value c 'clails/controller/base-controller::env)
            (make-json-env "{\"email\":\"x@example.com\",\"password\":\"pass123\"}"))
      (do-post c)
      (ok (= 400 (slot-value c 'clails/controller/base-controller::code)) "returns 400")
      (ok (assoc "error" (response c) :test #'string=) "response has error key")))

  (testing "missing email: returns 400"
    (let ((c (make-instance '<users-controller>)))
      (setf (slot-value c 'clails/controller/base-controller::env)
            (make-json-env "{\"username\":\"user1\",\"password\":\"pass123\"}"))
      (do-post c)
      (ok (= 400 (slot-value c 'clails/controller/base-controller::code)) "returns 400")))

  (testing "missing password: returns 400"
    (let ((c (make-instance '<users-controller>)))
      (setf (slot-value c 'clails/controller/base-controller::env)
            (make-json-env "{\"username\":\"user1\",\"email\":\"user1@example.com\"}"))
      (do-post c)
      (ok (= 400 (slot-value c 'clails/controller/base-controller::code)) "returns 400")
      (ok (assoc "error" (response c) :test #'string=) "response has error key")))

  (testing "duplicate email: returns 409"
    (let ((c1 (make-instance '<users-controller>))
          (c2 (make-instance '<users-controller>)))
      (setf (slot-value c1 'clails/controller/base-controller::env)
            (make-json-env "{\"username\":\"dupuser\",\"email\":\"dup@example.com\",\"password\":\"pass123\"}"))
      (do-post c1)
      (unwind-protect
           (progn
             (setf (slot-value c2 'clails/controller/base-controller::env)
                   (make-json-env "{\"username\":\"dupuser2\",\"email\":\"dup@example.com\",\"password\":\"pass456\"}"))
             (do-post c2)
             (ok (= 409 (slot-value c2 'clails/controller/base-controller::code)) "returns 409")
             (ok (string= "email already registered"
                          (cdr (assoc "error" (response c2) :test #'string=)))
                 "correct error message"))
        (let ((user (find-user-by-email "dup@example.com")))
          (when user (destroy user)))))))
