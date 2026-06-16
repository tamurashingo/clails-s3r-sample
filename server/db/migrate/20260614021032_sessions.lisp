; -*- mode: lisp -*-
(in-package #:todo-server-db)

(defmigration "20260614021032_sessions"
  (:up #'(lambda (connection)
           (create-table connection
                         :table "sessions"
                         :columns '(("ulid"       :type :string
                                                  :not-null t)
                                    ("user-id"    :type :integer
                                                  :not-null t)
                                    ("token"      :type :string
                                                  :not-null t)
                                    ("expires-at" :type :datetime
                                                  :not-null t)))
           (add-index connection
                      :table "sessions"
                      :index "idx-sessions-token"
                      :columns '("token"))
           (add-index connection
                      :table "sessions"
                      :index "idx-sessions-user-id"
                      :columns '("user-id")))
   :down #'(lambda (connection)
             (drop-table connection :table "sessions"))))

