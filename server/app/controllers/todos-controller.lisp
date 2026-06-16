; -*- mode: lisp -*-
(in-package #:cl-user)
(defpackage #:todo-server/controllers/todos-controller
  (:use #:cl
        #:clails/controller/base-controller)
  (:import-from #:todo-server/utils/http-util
                #:parse-json-body
                #:authenticate-request
                #:set-code)
  (:import-from #:todo-server/utils/date-util
                #:parse-deadline)
  (:import-from #:todo-server/models/todo
                #:find-todos-by-user
                #:find-todo-by-ulid
                #:create-todo
                #:update-todo
                #:complete-todo
                #:delete-todo
                #:todo-to-alist)
  (:import-from #:clails/model
                #:ref)
  (:export #:<todos-controller>
           #:<todo-controller>
           #:<todo-complete-controller>))

(in-package #:todo-server/controllers/todos-controller)


;;; helper

(defun unauthorized (c)
  (set-code c 401)
  (set-response c '(("error" . "unauthorized"))))

(defun not-found (c)
  (set-code c 404)
  (set-response c '(("error" . "not found"))))


;;; GET/POST /api/todos

(defclass <todos-controller> (<rest-controller>) ())


;; GET /api/todos - list todos
(defmethod do-get ((c <todos-controller>))
  (let ((session (authenticate-request (env c))))
    (if (null session)
        (unauthorized c)
        (let* ((user-id (ref session :user-id))
               (todos   (find-todos-by-user user-id)))
          (set-response c (mapcar #'todo-to-alist todos))))))

;; POST /api/todos - create todo
(defmethod do-post ((c <todos-controller>))
  (let ((session (authenticate-request (env c))))
    (if (null session)
        (unauthorized c)
        (let* ((user-id (ref session :user-id))
               (body    (parse-json-body (env c)))
               (subject (getf body :|subject|))
               (content (getf body :|content|))
               (deadline (parse-deadline (getf body :|deadline|))))
          (if (or (null subject) (string= subject ""))
              (progn
                (set-code c 400)
                (set-response c '(("error" . "subject is required"))))
              (let ((todo (create-todo user-id subject
                                       :content content
                                       :deadline deadline)))
                (if todo
                    (progn
                      (set-code c 201)
                      (set-response c (todo-to-alist todo)))
                    (progn
                      (set-code c 500)
                      (set-response c '(("error" . "failed to create todo")))))))))))


;;; GET/PUT/DELETE /api/todos/:ulid

(defclass <todo-controller> (<rest-controller>) ())

;; GET /api/todos/:ulid - get todo detail
(defmethod do-get ((c <todo-controller>))
  (let ((session (authenticate-request (env c))))
    (if (null session)
        (unauthorized c)
        (let* ((user-id (ref session :user-id))
               (ulid    (param c "ulid"))
               (todo    (find-todo-by-ulid ulid user-id)))
          (if (null todo)
              (not-found c)
              (set-response c (todo-to-alist todo)))))))

;; PUT /api/todos/:ulid - update todo
(defmethod do-put ((c <todo-controller>))
  (let ((session (authenticate-request (env c))))
    (if (null session)
        (unauthorized c)
        (let* ((user-id (ref session :user-id))
               (ulid    (param c "ulid"))
               (todo    (find-todo-by-ulid ulid user-id)))
          (if (null todo)
              (not-found c)
              (let* ((body     (parse-json-body (env c)))
                     (subject  (getf body :|subject|))
                     (content  (getf body :|content|))
                     (deadline (parse-deadline (getf body :|deadline|))))
                (set-response c (todo-to-alist
                                  (update-todo todo
                                               :subject subject
                                               :content content
                                               :deadline deadline)))))))))

;; DELETE /api/todos/:ulid - delete todo
(defmethod do-delete ((c <todo-controller>))
  (let ((session (authenticate-request (env c))))
    (if (null session)
        (unauthorized c)
        (let* ((user-id (ref session :user-id))
               (ulid    (param c "ulid"))
               (todo    (find-todo-by-ulid ulid user-id)))
          (if (null todo)
              (not-found c)
              (progn
                (delete-todo todo)
                (set-response c '(("message" . "deleted")))))))))


;;; PUT /api/todos/:ulid/complete

(defclass <todo-complete-controller> (<rest-controller>) ())

;; PUT /api/todos/:ulid/complete - mark todo as completed
(defmethod do-put ((c <todo-complete-controller>))
  (let ((session (authenticate-request (env c))))
    (if (null session)
        (unauthorized c)
        (let* ((user-id (ref session :user-id))
               (ulid    (param c "ulid"))
               (todo    (find-todo-by-ulid ulid user-id)))
          (if (null todo)
              (not-found c)
              (set-response c (todo-to-alist (complete-todo todo))))))))

