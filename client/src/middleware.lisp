; -*- mode: lisp -*-
(in-package #:cl-user)
(defpackage #:todo-client/middleware
  (:use #:cl)
  (:import-from #:todo-client/api-client
                #:api-post
                #:api-put
                #:api-delete)
  (:import-from #:cl-s3r.session
                #:get-session
                #:set-session
                #:destroy-session)
  (:export #:handle-post))

(in-package #:todo-client/middleware)

;;; helpers

(defun url-decode (str)
  "URL-decode STR, handling UTF-8 multibyte percent-encoded sequences."
  (let ((pending (make-array 4 :element-type '(unsigned-byte 8) :fill-pointer 0))
        (result  (make-array (length str) :element-type 'character :fill-pointer 0))
        (i 0)
        (len (length str)))
    (flet ((flush ()
             (when (> (fill-pointer pending) 0)
               (let ((s (babel:octets-to-string pending :encoding :utf-8)))
                 (dotimes (j (length s))
                   (vector-push-extend (char s j) result)))
               (setf (fill-pointer pending) 0))))
      (loop while (< i len)
            for c = (char str i)
            do (cond
                 ((and (char= c #\%) (< (+ i 2) len))
                  (vector-push-extend
                   (parse-integer (subseq str (1+ i) (+ i 3)) :radix 16)
                   pending)
                  (incf i 3))
                 (t
                  (flush)
                  (vector-push-extend (if (char= c #\+) #\Space c) result)
                  (incf i))))
      (flush))
    (coerce result 'string)))

(defun parse-form-body (env)
  "Parse application/x-www-form-urlencoded body into an alist."
  (let ((len (getf env :content-length))
        (body (getf env :raw-body)))
    (when (and len body (> len 0))
      (let ((buf (make-array len :element-type '(unsigned-byte 8))))
        (read-sequence buf body)
        (let ((str (babel:octets-to-string buf :encoding :utf-8)))
          (loop for pair in (split-string str #\&)
                for eq-pos = (position #\= pair)
                when eq-pos
                collect (cons (url-decode (subseq pair 0 eq-pos))
                              (url-decode (subseq pair (1+ eq-pos))))))))))

(defun split-string (str char)
  (loop for start = 0 then (1+ pos)
        for pos = (position char str :start start)
        collect (subseq str start pos)
        while pos))

(defun get-form-param (params key)
  (cdr (assoc key params :test #'string=)))

(defun get-session-token ()
  (getf (get-session :token) :token))

(defun redirect-303 (location)
  `(303 (:location ,location :content-type "text/html") ("")))

(defun extract-todo-ulid (path)
  "Extract ULID from /todo/:ulid or /todo/:ulid/action paths."
  (when (and (> (length path) 6)
             (string= "/todo/" (subseq path 0 6)))
    (let* ((rest (subseq path 6))
           (slash (position #\/ rest)))
      (if slash
          (subseq rest 0 slash)
          rest))))

(defun todo-subpath (path)
  "Return the action suffix after /todo/:ulid, e.g. \"/complete\" or nil."
  (when (and (> (length path) 6)
             (string= "/todo/" (subseq path 0 6)))
    (let* ((rest (subseq path 6))
           (slash (position #\/ rest)))
      (when slash
        (subseq rest slash)))))


;;; POST handlers

(defun do-signup (params)
  (handler-case
      (let* ((username (get-form-param params "username"))
             (email    (get-form-param params "email"))
             (password (get-form-param params "password")))
        (api-post "/api/users" nil
                  (list :|username| username :|email| email :|password| password))
        (redirect-303 "/login"))
    (dex:http-request-failed (e)
      (let ((msg (dex:response-body e)))
        (redirect-303 (format nil "/signup?error=~A"
                               (url-encode (or msg "signup failed"))))))))

(defun do-login (params)
  (handler-case
      (let* ((email    (get-form-param params "email"))
             (password (get-form-param params "password"))
             (resp     (api-post "/api/sessions" nil
                                  (list :|email| email :|password| password)))
             (data     (jonathan:parse resp))
             (token    (getf data :|token|)))
        (set-session (list :token token))
        (redirect-303 "/todos"))
    (dex:http-request-failed ()
      (redirect-303 "/login?error=invalid"))))

(defun do-logout (token)
  (handler-case
      (when token
        (api-delete "/api/sessions" token))
    (error ()))
  (destroy-session)
  (redirect-303 "/login"))

(defun do-create-todo (params token)
  (if (null token)
      (redirect-303 "/login")
      (handler-case
          (let* ((subject  (get-form-param params "subject"))
                 (content  (get-form-param params "content"))
                 (deadline (get-form-param params "deadline")))
            (api-post "/api/todos" token
                       (list :|subject| subject
                             :|content| (when (and content (not (string= content ""))) content)
                             :|deadline| (when (and deadline (not (string= deadline ""))) deadline)))
            (redirect-303 "/todos"))
        (dex:http-request-failed ()
          (redirect-303 "/todo/new?error=failed")))))

(defun do-edit-todo (ulid params token)
  (if (null token)
      (redirect-303 "/login")
      (handler-case
          (let* ((subject  (get-form-param params "subject"))
                 (content  (get-form-param params "content"))
                 (deadline (get-form-param params "deadline")))
            (api-put (format nil "/api/todos/~A" ulid) token
                      (list :|subject| subject
                            :|content| (when (and content (not (string= content ""))) content)
                            :|deadline| (when (and deadline (not (string= deadline ""))) deadline)))
            (redirect-303 (format nil "/todo/~A" ulid)))
        (dex:http-request-failed ()
          (redirect-303 (format nil "/todo/~A?mode=edit&error=failed" ulid))))))

(defun do-complete-todo (ulid token)
  (if (null token)
      (redirect-303 "/login")
      (handler-case
          (progn
            (api-put (format nil "/api/todos/~A/complete" ulid) token)
            (redirect-303 (format nil "/todo/~A" ulid)))
        (dex:http-request-failed ()
          (redirect-303 (format nil "/todo/~A?error=failed" ulid))))))

(defun do-delete-todo (ulid token)
  (if (null token)
      (redirect-303 "/login")
      (handler-case
          (progn
            (api-delete (format nil "/api/todos/~A" ulid) token)
            (redirect-303 "/todos"))
        (dex:http-request-failed ()
          (redirect-303 (format nil "/todo/~A?error=failed" ulid))))))


;;; URL encoder (for error messages in redirects)

(defun url-encode (str)
  (with-output-to-string (out)
    (loop for c across str do
      (cond
        ((or (alphanumericp c) (find c "-_.~"))
         (write-char c out))
        (t
         (format out "%~2,'0X" (char-code c)))))))


;;; Main dispatch

(defun handle-post (env s3r-app)
  (let ((path  (getf env :path-info))
        (token (get-session-token)))
    (cond
      ((string= path "/signup")
       (do-signup (parse-form-body env)))
      ((string= path "/login")
       (do-login (parse-form-body env)))
      ((string= path "/logout")
       (do-logout token))
      ((string= path "/todos")
       (do-create-todo (parse-form-body env) token))
      (t
       (let ((ulid    (extract-todo-ulid path))
             (subpath (todo-subpath path)))
         (cond
           ((null ulid)
            (funcall s3r-app env))
           ((string= subpath "/action")
            (funcall s3r-app env))
           ((string= subpath "/complete")
            (do-complete-todo ulid token))
           ((string= subpath "/delete")
            (do-delete-todo ulid token))
           (t
            (do-edit-todo ulid (parse-form-body env) token))))))))
