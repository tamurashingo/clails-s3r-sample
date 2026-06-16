; -*- mode: lisp -*-
(in-package #:cl-user)
(defpackage #:todo-client/components/todo-detail
  (:use #:cl)
  (:import-from #:cl-s3r.component #:define-component)
  (:import-from #:cl-s3r.cookie #:get-cookie)
  (:import-from #:todo-client/api-client #:api-get))

(in-package #:todo-client/components/todo-detail)

(defun nullish-p (v)
  (or (null v) (eq v :null) (equal v "")))

(defun render-edit-form (todo ulid)
  `(:div
    (:div (@ (:class "header"))
      (:h1 "Edit TODO")
      (:a (@ (:href "/todos")) "<- Back to list"))
    (:form (@ (:action ,(format nil "/todo/~A" ulid)) (:method "post"))
      (:label "Title *")
      (:input (@ (:type "text") (:name "subject") (:required "required")
                 (:value ,(or (getf todo :|subject|) ""))))
      (:label "Content")
      (:textarea (@ (:name "content"))
        ,(let ((c (getf todo :|content|)))
           (if (nullish-p c) "" c)))
      (:label "Deadline")
      (:input (@ (:type "date") (:name "deadline")
                 (:value ,(let ((d (getf todo :|deadline|)))
                            (if (nullish-p d) "" d)))))
      (:div
       (:button (@ (:type "submit")) "Save")
       " "
       (:a (@ (:href ,(format nil "/todo/~A" ulid))) "Cancel")))))

(defun render-detail-view (todo ulid error)
  (let* ((subject   (getf todo :|subject|))
         (content   (getf todo :|content|))
         (deadline  (getf todo :|deadline|))
         (completed (getf todo :|completed|)))
    `(:div
      ,@(when error `((:p (@ (:class "error")) ,error)))
      (:div (@ (:class "header"))
        (:h1 ,subject)
        (:a (@ (:href "/todos")) "<- Back to list"))
      ,@(unless (nullish-p content) `((:p ,content)))
      ,@(unless (nullish-p deadline) `((:p "Deadline: " ,deadline)))
      (:p "Status: " ,(if completed "Completed" "Not completed"))
      (:div
       ,@(unless completed
           `((:form (@ (:action ,(format nil "/todo/~A/complete" ulid))
                       (:method "post") (:style "display:inline"))
               (:button (@ (:type "submit")) "Mark as done"))
             " "))
       (:a (@ (:href ,(format nil "/todo/~A?mode=edit" ulid)) (:class "btn")) "Edit")
       " "
       (:form (@ (:action ,(format nil "/todo/~A/delete" ulid))
                 (:method "post") (:style "display:inline"))
         (:button (@ (:type "submit")) "Delete"))))))

; positional args: ulid, mode, error
(define-component todo-detail-page (ulid mode error)
  (let ((token (get-cookie "todo-session")))
    (if (null token)
        `(:script "window.location.replace('/login');")
        (if (null ulid)
            `(:p "ULID not specified")
            (let ((todo (handler-case
                             (jonathan:parse (api-get (format nil "/api/todos/~A" ulid) token))
                           (error () nil))))
              (if (null todo)
                  `(:p "TODO not found")
                  (if (and mode (not (string= mode "")) (string= mode "edit"))
                      (render-edit-form todo ulid)
                      (render-detail-view todo ulid error))))))))
