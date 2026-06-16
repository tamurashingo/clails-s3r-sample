(in-package #:cl-user)
(defpackage #:todo-server/utils/date-util
  (:use #:cl)
  (:import-from #:clails/datetime/parser
                #:parse)
  (:import-from #:clails/datetime/accessors
                #:to-universal-time)
  (:export #:parse-deadline))

(in-package #:todo-server/utils/date-util)

(defun parse-deadline (s)
  "Parse ISO 8601 datetime string (e.g. '2026-06-12T08:41') to CL universal time.
   datetime-local inputs omit seconds, so append :00 when only one colon is present."
  (when (and s (stringp s) (not (string= s "")))
    (handler-case
        (to-universal-time
          (parse (if (= (count #\: s) 1)
                     (concatenate 'string s ":00")
                     s)
                 :format :iso8601))
      (error () nil))))

