(in-package #:cl-user)
(defpackage #:todo-server/utils/model-util
  (:use #:cl)
  (:export #:generate-ulid
           #:generate-token
           #:hash-password
           #:verify-password))

(in-package #:todo-server/utils/model-util)

(defparameter *encoding* "0123456789ABCDEFGHJKMNPQRSTVWXYZ")
(defparameter *encoding-length* 32)

(defun timestamp-ms ()
  (multiple-value-bind (sec usec) (sb-ext:get-time-of-day)
    (+ (* sec 1000) (floor usec 1000))))

(defun encode-timestamp (timestamp)
  (let ((result (make-string 10 :initial-element #\0)))
    (loop for i from 9 downto 0
          do (setf (char result i)
                   (char *encoding* (mod timestamp *encoding-length*)))
             (setf timestamp
                   (floor timestamp *encoding-length*)))
    result))

(defun encode-random (rand-bytes)
  (let ((result (make-string 16 :initial-element #\0))
        (value 0))
    (loop for byte across rand-bytes
          do (setf value (+ (* value 256) byte)))
    (loop for i from 15 downto 0
          do (setf (char result i)
                   (char *encoding* (mod value *encoding-length*)))
             (setf value
                   (floor value *encoding-length*)))
      result))

(defun generate-ulid ()
  (let ((ts (timestamp-ms))
        (rand-bytes (make-array 10 :element-type '(unsigned-byte 8))))
    (dotimes (i 10)
      (setf (aref rand-bytes i)
            (random 256)))
    (concatenate 'string
                 (encode-timestamp ts)
                 (encode-random rand-bytes))))

(defun generate-token ()
  (ironclad:byte-array-to-hex-string (ironclad:random-data 32)))

(defun hash-password (plain)
  (let* ((octets    (babel:string-to-octets plain :encoding :utf-8))
         (salt      (ironclad:make-random-salt))
         (hash      (ironclad:pbkdf2-hash-password octets
                                                :salt salt
                                                :digest :sha256
                                                :iterations 10000))
         (salt+hash (concatenate '(vector (unsigned-byte 8)) salt hash)))
    (ironclad:byte-array-to-hex-string salt+hash)))

(defun verify-password (plain stored-hash)
  (handler-case
      (let* ((octets    (babel:string-to-octets plain :encoding :utf-8))
             (salt+hash (ironclad:hex-string-to-byte-array stored-hash))
             (salt      (subseq salt+hash 0 16))
             (stored    (subseq salt+hash 16))
             (computed  (ironclad:pbkdf2-hash-password octets
                                                       :salt salt
                                                       :digest :sha256
                                                       :iterations 10000)))
        (ironclad:constant-time-equal stored computed))
    (error () nil)))



