; -*- mode: lisp -*-
(in-package #:cl-user)
(defpackage #:todo-client/components/todo-list
  (:use #:cl)
  (:import-from #:cl-s3r.component
                #:define-component
                #:let-component-state
                #:let-function)
  (:import-from #:cl-s3r.cookie #:get-cookie)
  (:import-from #:todo-client/api-client #:api-get #:api-post #:api-put))

(in-package #:todo-client/components/todo-list)

(defun render-todo-item (todo)
  (let* ((ulid      (getf todo :|ulid|))
         (subject   (getf todo :|subject|))
         (completed (getf todo :|completed|))
         (deadline  (getf todo :|deadline|)))
    `(:li (@ (class ,(if completed "todo-item done" "todo-item")))
      (:input (@ (type "checkbox")
                 (class "complete-checkbox")
                 ,@(when completed '((checked "checked") (disabled "disabled")))
                 ,@(unless completed
                     `((onclick (complete-todo ,ulid))))))
      (:a (@ (href ,(format nil "/todo/~A" ulid)) (class "todo-link"))
          ,subject)
      ,@(when (and deadline (not (eq deadline :null)))
          `((:span (@ (class "deadline")) ,(format nil "Deadline: ~A" deadline)))))))

(define-component todo-list-page (&key &allow-other-keys)
  (let ((token (get-cookie "todo-session")))
    (if (null token)
        `(:script "window.location.replace('/login');")
        (let ((todos (handler-case
                         (jonathan:parse (api-get "/api/todos" token))
                       (error () nil))))
          (let-component-state ((show-modal nil))
            (let-function
                ((open-modal ()
                   (setf show-modal t))
                 (close-modal ()
                   (setf show-modal nil))
                 (create-todo (form-data)
                   (let ((subject  (getf form-data :|subject|))
                         (content  (getf form-data :|content|))
                         (deadline (getf form-data :|deadline|)))
                     (when (and subject (not (string= subject "")))
                       (handler-case
                           (api-post "/api/todos" token
                                     (list :|subject| subject
                                           :|content| (when (and content (not (string= content ""))) content)
                                           :|deadline| (when (and deadline (not (string= deadline ""))) deadline)))
                         (error ()))))
                   (setf show-modal nil))
                 (complete-todo (ulid)
                   (when ulid
                     (handler-case
                         (api-put (format nil "/api/todos/~A/complete" ulid) token nil)
                       (error ())))))
              `(:div
                (:div (@ (class "header"))
                  (:h1 "TODO List")
                  (:div
                   (:button (@ (class "btn") (onclick (open-modal))) "New")
                   " "
                   (:form (@ (:action "/logout") (:method "post") (:style "display:inline"))
                     (:button (@ (:type "submit")) "Log Out"))))

                ;; New TODO modal -- toggle display via show-modal state
                (:div (@ (class "modal-overlay")
                         (style ,(format nil "display:~A" (if show-modal "flex" "none"))))
                  (:div (@ (class "modal"))
                    (:h2 "New TODO")
                    (:form (@ (onsubmit (create-todo)))
                      (:label "Title *")
                      (:input (@ (type "text") (name "subject") (required "required")))
                      (:label "Content")
                      (:textarea (@ (name "content") (rows "3")) "")
                      (:label "Deadline")
                      (:input (@ (type "date") (name "deadline")))
                      (:div (@ (class "modal-actions"))
                        (:button (@ (type "submit")) "Create")
                        (:button (@ (type "button") (onclick (close-modal))) "Cancel")))))

                ,(if (null todos)
                     '(:p "No TODOs yet")
                     `(:ul ,@(mapcar #'render-todo-item todos))))))))))
