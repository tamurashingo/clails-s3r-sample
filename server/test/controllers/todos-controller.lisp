; -*- mode: lisp -*-
(in-package #:cl-user)
(defpackage #:todo-server-test/controllers/todos-controller
  (:use #:cl
        #:rove)
  (:import-from #:clails/test
                #:deftest-suite)
  (:import-from #:todo-server/controllers/todos-controller
                #:<todos-controller>
                #:<todo-controller>
                #:<todo-complete-controller>)
  (:import-from #:clails/controller/base-controller
                #:do-get
                #:do-post
                #:do-put
                #:do-delete
                #:response)
  (:import-from #:todo-server/models/user
                #:create-user)
  (:import-from #:todo-server/models/session
                #:create-session
                #:delete-session-by-token)
  (:import-from #:todo-server/models/todo
                #:create-todo
                #:find-todo-by-ulid
                #:delete-todo)
  (:import-from #:clails/model
                #:ref
                #:destroy)
  (:import-from #:babel
                #:string-to-octets)
  (:import-from #:flexi-streams
                #:make-in-memory-input-stream))
(in-package #:todo-server-test/controllers/todos-controller)

(defun make-auth-env (token &optional (json-string "{}"))
  (let* ((bytes (string-to-octets json-string :encoding :utf-8))
         (headers (make-hash-table :test 'equal)))
    (setf (gethash "authorization" headers)
          (format nil "Bearer ~A" token))
    (list :raw-body (make-in-memory-input-stream bytes)
          :content-length (length bytes)
          :headers headers)))

(defun make-unauth-env (&optional (json-string "{}"))
  (let* ((bytes (string-to-octets json-string :encoding :utf-8))
         (headers (make-hash-table :test 'equal)))
    (list :raw-body (make-in-memory-input-stream bytes)
          :content-length (length bytes)
          :headers headers)))

(defun set-param (c key value)
  (setf (gethash key (slot-value c 'clails/controller/base-controller::params)) value))


;;; GET /api/todos

(deftest-suite :controller test-get-todos
  (testing "unauthorized: returns 401"
    (let ((c (make-instance '<todos-controller>)))
      (setf (slot-value c 'clails/controller/base-controller::env) (make-unauth-env))
      (do-get c)
      (ok (= 401 (slot-value c 'clails/controller/base-controller::code)) "returns 401")))

  (testing "success: returns empty list when no todos"
    (let ((user (create-user "listuser0" "listuser0@example.com" "pass123")))
      (unwind-protect
           (let* ((session (create-session (ref user :id)))
                  (token (ref session :token))
                  (c (make-instance '<todos-controller>)))
             (setf (slot-value c 'clails/controller/base-controller::env)
                   (make-auth-env token))
             (do-get c)
             (ok (null (response c)) "returns empty list")
             (delete-session-by-token token))
        (when user (destroy user)))))

  (testing "success: returns todos list"
    (let ((user (create-user "listuser1" "listuser1@example.com" "pass123")))
      (unwind-protect
           (let* ((todo1 (create-todo (ref user :id) "First"))
                  (todo2 (create-todo (ref user :id) "Second"))
                  (session (create-session (ref user :id)))
                  (token (ref session :token))
                  (c (make-instance '<todos-controller>)))
             (setf (slot-value c 'clails/controller/base-controller::env)
                   (make-auth-env token))
             (do-get c)
             (ok (>= (length (response c)) 2) "returns at least 2 todos")
             (delete-session-by-token token)
             (when todo1 (delete-todo todo1))
             (when todo2 (delete-todo todo2)))
        (when user (destroy user))))))


;;; POST /api/todos

(deftest-suite :controller test-post-todos
  (testing "unauthorized: returns 401"
    (let ((c (make-instance '<todos-controller>)))
      (setf (slot-value c 'clails/controller/base-controller::env) (make-unauth-env))
      (do-post c)
      (ok (= 401 (slot-value c 'clails/controller/base-controller::code)) "returns 401")))

  (testing "missing subject: returns 400"
    (let ((user (create-user "postuser0" "postuser0@example.com" "pass123")))
      (unwind-protect
           (let* ((session (create-session (ref user :id)))
                  (token (ref session :token))
                  (c (make-instance '<todos-controller>)))
             (setf (slot-value c 'clails/controller/base-controller::env)
                   (make-auth-env token "{\"content\":\"no subject\"}"))
             (do-post c)
             (ok (= 400 (slot-value c 'clails/controller/base-controller::code)) "returns 400")
             (ok (assoc "error" (response c) :test #'string=) "response has error key")
             (delete-session-by-token token))
        (when user (destroy user)))))

  (testing "success: returns 201 with todo data"
    (let ((user (create-user "postuser1" "postuser1@example.com" "pass123")))
      (unwind-protect
           (let* ((session (create-session (ref user :id)))
                  (token (ref session :token))
                  (c (make-instance '<todos-controller>)))
             (setf (slot-value c 'clails/controller/base-controller::env)
                   (make-auth-env token "{\"subject\":\"New todo\",\"content\":\"Details\"}"))
             (do-post c)
             (let ((resp (response c)))
               (ok (= 201 (slot-value c 'clails/controller/base-controller::code)) "returns 201")
               (ok (assoc "ulid" resp :test #'string=) "response has ulid")
               (ok (string= "New todo" (cdr (assoc "subject" resp :test #'string=))) "subject matches")
               ;; cleanup todo created by controller
               (let ((ulid (cdr (assoc "ulid" resp :test #'string=))))
                 (when ulid
                   (let ((todo (find-todo-by-ulid ulid (ref user :id))))
                     (when todo (delete-todo todo))))))
             (delete-session-by-token token))
        (when user (destroy user))))))


;;; GET /api/todos/:ulid

(deftest-suite :controller test-get-todo
  (testing "unauthorized: returns 401"
    (let ((c (make-instance '<todo-controller>)))
      (setf (slot-value c 'clails/controller/base-controller::env) (make-unauth-env))
      (set-param c "ulid" "00000000000000000000000000")
      (do-get c)
      (ok (= 401 (slot-value c 'clails/controller/base-controller::code)) "returns 401")))

  (testing "not found: returns 404"
    (let ((user (create-user "getuser0" "getuser0@example.com" "pass123")))
      (unwind-protect
           (let* ((session (create-session (ref user :id)))
                  (token (ref session :token))
                  (c (make-instance '<todo-controller>)))
             (setf (slot-value c 'clails/controller/base-controller::env)
                   (make-auth-env token))
             (set-param c "ulid" "00000000000000000000000000")
             (do-get c)
             (ok (= 404 (slot-value c 'clails/controller/base-controller::code)) "returns 404")
             (delete-session-by-token token))
        (when user (destroy user)))))

  (testing "success: returns todo data"
    (let ((user (create-user "getuser1" "getuser1@example.com" "pass123")))
      (unwind-protect
           (let* ((todo (create-todo (ref user :id) "Get me"))
                  (session (create-session (ref user :id)))
                  (token (ref session :token))
                  (c (make-instance '<todo-controller>)))
             (setf (slot-value c 'clails/controller/base-controller::env)
                   (make-auth-env token))
             (set-param c "ulid" (ref todo :ulid))
             (do-get c)
             (let ((resp (response c)))
               (ok (assoc "ulid" resp :test #'string=) "response has ulid")
               (ok (string= (ref todo :ulid) (cdr (assoc "ulid" resp :test #'string=)))
                   "ulid matches"))
             (delete-session-by-token token)
             (when todo (delete-todo todo)))
        (when user (destroy user))))))


;;; PUT /api/todos/:ulid

(deftest-suite :controller test-put-todo
  (testing "unauthorized: returns 401"
    (let ((c (make-instance '<todo-controller>)))
      (setf (slot-value c 'clails/controller/base-controller::env) (make-unauth-env))
      (set-param c "ulid" "00000000000000000000000000")
      (do-put c)
      (ok (= 401 (slot-value c 'clails/controller/base-controller::code)) "returns 401")))

  (testing "not found: returns 404"
    (let ((user (create-user "putuser0" "putuser0@example.com" "pass123")))
      (unwind-protect
           (let* ((session (create-session (ref user :id)))
                  (token (ref session :token))
                  (c (make-instance '<todo-controller>)))
             (setf (slot-value c 'clails/controller/base-controller::env)
                   (make-auth-env token "{\"subject\":\"Updated\"}"))
             (set-param c "ulid" "00000000000000000000000000")
             (do-put c)
             (ok (= 404 (slot-value c 'clails/controller/base-controller::code)) "returns 404")
             (delete-session-by-token token))
        (when user (destroy user)))))

  (testing "success: returns updated todo"
    (let ((user (create-user "putuser1" "putuser1@example.com" "pass123")))
      (unwind-protect
           (let* ((todo (create-todo (ref user :id) "Original"))
                  (session (create-session (ref user :id)))
                  (token (ref session :token))
                  (c (make-instance '<todo-controller>)))
             (setf (slot-value c 'clails/controller/base-controller::env)
                   (make-auth-env token "{\"subject\":\"Updated subject\",\"content\":\"New content\"}"))
             (set-param c "ulid" (ref todo :ulid))
             (do-put c)
             (let ((resp (response c)))
               (ok (string= "Updated subject" (cdr (assoc "subject" resp :test #'string=)))
                   "subject is updated in response"))
             (delete-session-by-token token)
             (when todo (delete-todo todo)))
        (when user (destroy user))))))


;;; DELETE /api/todos/:ulid

(deftest-suite :controller test-delete-todo
  (testing "unauthorized: returns 401"
    (let ((c (make-instance '<todo-controller>)))
      (setf (slot-value c 'clails/controller/base-controller::env) (make-unauth-env))
      (set-param c "ulid" "00000000000000000000000000")
      (do-delete c)
      (ok (= 401 (slot-value c 'clails/controller/base-controller::code)) "returns 401")))

  (testing "not found: returns 404"
    (let ((user (create-user "deluser0" "deluser0@example.com" "pass123")))
      (unwind-protect
           (let* ((session (create-session (ref user :id)))
                  (token (ref session :token))
                  (c (make-instance '<todo-controller>)))
             (setf (slot-value c 'clails/controller/base-controller::env)
                   (make-auth-env token))
             (set-param c "ulid" "00000000000000000000000000")
             (do-delete c)
             (ok (= 404 (slot-value c 'clails/controller/base-controller::code)) "returns 404")
             (delete-session-by-token token))
        (when user (destroy user)))))

  (testing "success: returns deleted message"
    (let ((user (create-user "deluser1" "deluser1@example.com" "pass123")))
      (unwind-protect
           (let* ((todo (create-todo (ref user :id) "Delete me"))
                  (session (create-session (ref user :id)))
                  (token (ref session :token))
                  (c (make-instance '<todo-controller>)))
             (setf (slot-value c 'clails/controller/base-controller::env)
                   (make-auth-env token))
             (set-param c "ulid" (ref todo :ulid))
             (do-delete c)
             (ok (string= "deleted" (cdr (assoc "message" (response c) :test #'string=)))
                 "returns deleted message")
             (ok (null (find-todo-by-ulid (ref todo :ulid) (ref user :id)))
                 "todo is removed from db")
             (delete-session-by-token token))
        (when user (destroy user))))))


;;; PUT /api/todos/:ulid/complete

(deftest-suite :controller test-complete-todo
  (testing "unauthorized: returns 401"
    (let ((c (make-instance '<todo-complete-controller>)))
      (setf (slot-value c 'clails/controller/base-controller::env) (make-unauth-env))
      (set-param c "ulid" "00000000000000000000000000")
      (do-put c)
      (ok (= 401 (slot-value c 'clails/controller/base-controller::code)) "returns 401")))

  (testing "not found: returns 404"
    (let ((user (create-user "cmpuser0" "cmpuser0@example.com" "pass123")))
      (unwind-protect
           (let* ((session (create-session (ref user :id)))
                  (token (ref session :token))
                  (c (make-instance '<todo-complete-controller>)))
             (setf (slot-value c 'clails/controller/base-controller::env)
                   (make-auth-env token))
             (set-param c "ulid" "00000000000000000000000000")
             (do-put c)
             (ok (= 404 (slot-value c 'clails/controller/base-controller::code)) "returns 404")
             (delete-session-by-token token))
        (when user (destroy user)))))

  (testing "success: returns todo marked as completed"
    (let ((user (create-user "cmpuser1" "cmpuser1@example.com" "pass123")))
      (unwind-protect
           (let* ((todo (create-todo (ref user :id) "Complete me"))
                  (session (create-session (ref user :id)))
                  (token (ref session :token))
                  (c (make-instance '<todo-complete-controller>)))
             (setf (slot-value c 'clails/controller/base-controller::env)
                   (make-auth-env token))
             (set-param c "ulid" (ref todo :ulid))
             (do-put c)
             (let ((resp (response c)))
               (ok (eq t (cdr (assoc "completed" resp :test #'string=)))
                   "completed is true in response"))
             (delete-session-by-token token)
             (when todo (delete-todo todo)))
        (when user (destroy user))))))
