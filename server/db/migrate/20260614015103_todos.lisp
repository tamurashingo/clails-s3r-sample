; -*- mode: lisp -*-
(in-package #:todo-server-db)

(defmigration "20260614015103_todos"
  (:up #'(lambda (connection)
           (create-table connection
                         :table "todos"
                         :columns '(("ulid"         :type :string
                                                    :not-null t
                                                    :unique t)
                                    ("user-id"      :type :integer
                                                    :not-null t)
                                    ("subject"      :type :string
                                                    :not-null t)
                                    ("content"      :type :string)
                                    ("deadline"     :type :date)
                                    ("completed"    :type :boolean
                                                    :not-null t
                                                    :default-value nil)
                                    ("completed-at" :type :datetime)))
           (add-index connection
                      :table "todos"
                      :index "idx-todos-ulid"
                      :columns '("ulid"))
           (add-index connection
                      :table "todos"
                      :index "idx-todos-user-id"
                      :columns '("user-id")))
   :down #'(lambda (connection)
             (drop-table connection :table "todos"))))
