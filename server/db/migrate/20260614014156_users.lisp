; -*- mode: lisp -*-
(in-package #:todo-server-db)

(defmigration "20260614014156_users"
  (:up #'(lambda (connection)
           (create-table connection
                         :table "users"
                         :columns '(("ulid"            :type :string
                                                       :not-null t
                                                       :unique t)
                                    ("username"        :type :string
                                                       :not-null t
                                                       :unique t)
                                    ("email"           :type :string
                                                       :not-null t
                                                       :unique t)
                                    ("password-digest" :type :string
                                                       :not-null t)))
           (add-index connection
                      :table "users"
                      :index "idx-users-email"
                      :columns '("email"))
           (add-index connection
                      :table "users"
                      :index "idx-users-ulid"
                      :columns '("ulid")))
   :down #'(lambda (connection)
             (drop-table connection :table "users"))))

