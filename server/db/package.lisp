; -*- mode: lisp -*-
(in-package #:cl-user)
(defpackage #:todo-server-db
  (:use #:cl
        #:clails/model)
  (:import-from #:clails/model/migration
                #:defmigration
                #:create-table
                #:add-column
                #:add-index
                #:drop-table
                #:drop-table
                #:drop-column
                #:drop-index))
(in-package #:todo-server-db)
