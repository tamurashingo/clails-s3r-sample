(in-package #:cl-user)
(defpackage #:todo-server/utils/http-util
  (:use #:cl)
  (:import-from #:todo-server/models/session
                #:find-session-by-token)
  (:export #:parse-json-body
           #:extract-bearer-token
           #:authenticate-request
           #:set-code))

(in-package #:todo-server/utils/http-util)

(defun parse-json-body (env)
  (let ((len (getf env :content-length))
        (body (getf env :raw-body)))
    (when (and len body (> len 0))
      (let ((buf (make-array len :element-type '(unsigned-byte 8))))
        (read-sequence buf body)
        (jonathan:parse (babel:octets-to-string buf :encoding :utf-8))))))

(defun extract-bearer-token (env)
  (let ((auth (gethash "authorization" (getf env :headers))))
    (when (and auth
               (>= (length auth) 7)
               (string= "Bearer " (subseq auth 0 7)))
      (string-trim '(#\Space #\Tab) (subseq auth 7)))))

(defun authenticate-request (env)
  (let ((token (extract-bearer-token env)))
    (when token
      (find-session-by-token token))))

(defun set-code (controller code)
  (setf (slot-value controller 'clails/controller/base-controller:code) code))

