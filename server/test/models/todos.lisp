; -*- mode: lisp -*-
(in-package #:cl-user)
(defpackage #:todo-server-test/models/todos
  (:use #:cl
        #:rove)
  (:import-from #:clails/test
                #:deftest-suite)
  (:import-from #:todo-server/models/user
                #:create-user)
  (:import-from #:todo-server/models/todo
                #:create-todo
                #:find-todos-by-user
                #:find-todo-by-ulid
                #:update-todo
                #:complete-todo
                #:delete-todo
                #:todo-to-alist)
  (:import-from #:clails/model
                #:ref
                #:destroy))
(in-package #:todo-server-test/models/todos)

(deftest-suite :model test-create-todo
  (testing "create-todo creates a todo with expected fields"
    (let ((user (create-user "todouser" "todouser@example.com" "password123")))
      (unwind-protect
           (let ((todo (create-todo (ref user :id) "Buy milk")))
             (ok todo "todo is created")
             (ok (ref todo :id) "todo has an id")
             (ok (string= "Buy milk" (ref todo :subject)) "subject matches")
             (ok (= 26 (length (ref todo :ulid))) "ULID is 26 characters")
             (ok (null (ref todo :content)) "content defaults to nil")
             (ok (null (ref todo :deadline)) "deadline defaults to nil")
             (ok (null (ref todo :completed)) "completed defaults to nil")
             (when todo (delete-todo todo)))
        (when user (destroy user)))))

  (testing "create-todo stores optional content"
    (let ((user (create-user "todouser2" "todouser2@example.com" "password123")))
      (unwind-protect
           (let ((todo (create-todo (ref user :id) "Task" :content "Some details")))
             (ok todo "todo with content is created")
             (ok (string= "Some details" (ref todo :content)) "content matches")
             (when todo (delete-todo todo)))
        (when user (destroy user))))))

(deftest-suite :model test-find-todos-by-user
  (testing "find-todos-by-user returns todos for a user"
    (let ((user (create-user "listuser" "listuser@example.com" "password123")))
      (unwind-protect
           (let ((todo1 (create-todo (ref user :id) "First todo"))
                 (todo2 (create-todo (ref user :id) "Second todo")))
             (let ((todos (find-todos-by-user (ref user :id))))
               (ok (>= (length todos) 2) "returns at least 2 todos"))
             (when todo1 (delete-todo todo1))
             (when todo2 (delete-todo todo2)))
        (when user (destroy user)))))

  (testing "find-todos-by-user returns empty list for user with no todos"
    (let ((user (create-user "emptyuser" "emptyuser@example.com" "password123")))
      (unwind-protect
           (ok (null (find-todos-by-user (ref user :id)))
               "returns nil/empty list for user with no todos")
        (when user (destroy user))))))

(deftest-suite :model test-find-todo-by-ulid
  (testing "find-todo-by-ulid returns the todo for correct user"
    (let ((user (create-user "findtodouser" "findtodouser@example.com" "password123")))
      (unwind-protect
           (let ((todo (create-todo (ref user :id) "Find me")))
             (let ((found (find-todo-by-ulid (ref todo :ulid) (ref user :id))))
               (ok found "returns the todo")
               (ok (string= (ref todo :ulid) (ref found :ulid)) "ULID matches"))
             (when todo (delete-todo todo)))
        (when user (destroy user)))))

  (testing "find-todo-by-ulid returns nil when accessed by wrong user"
    (let ((user1 (create-user "owner1" "owner1@example.com" "password123"))
          (user2 (create-user "owner2" "owner2@example.com" "password123")))
      (unwind-protect
           (let ((todo (create-todo (ref user1 :id) "User1 todo")))
             (ok (null (find-todo-by-ulid (ref todo :ulid) (ref user2 :id)))
                 "returns nil when accessed by wrong user")
             (when todo (delete-todo todo)))
        (when user1 (destroy user1))
        (when user2 (destroy user2)))))

  (testing "find-todo-by-ulid returns nil for nonexistent ULID"
    (let ((user (create-user "ulidtestuser" "ulidtestuser@example.com" "password123")))
      (unwind-protect
           (ok (null (find-todo-by-ulid "00000000000000000000000000" (ref user :id)))
               "returns nil for unknown ULID")
        (when user (destroy user))))))

(deftest-suite :model test-update-todo
  (testing "update-todo updates subject and content"
    (let ((user (create-user "updateuser" "updateuser@example.com" "password123")))
      (unwind-protect
           (let ((todo (create-todo (ref user :id) "Original subject")))
             (update-todo todo :subject "Updated subject" :content "New content")
             (ok (string= "Updated subject" (ref todo :subject)) "subject is updated")
             (ok (string= "New content" (ref todo :content)) "content is updated")
             (when todo (delete-todo todo)))
        (when user (destroy user))))))

(deftest-suite :model test-complete-todo
  (testing "complete-todo marks the todo as completed"
    (let ((user (create-user "completeuser" "completeuser@example.com" "password123")))
      (unwind-protect
           (let ((todo (create-todo (ref user :id) "Complete me")))
             (complete-todo todo)
             (ok (ref todo :completed) "completed is true")
             (ok (ref todo :completed-at) "completed-at is set")
             (when todo (delete-todo todo)))
        (when user (destroy user))))))

(deftest-suite :model test-delete-todo
  (testing "delete-todo removes the todo from the database"
    (let ((user (create-user "deleteuser" "deleteuser@example.com" "password123")))
      (unwind-protect
           (let ((todo (create-todo (ref user :id) "Delete me")))
             (let ((ulid (ref todo :ulid))
                   (user-id (ref user :id)))
               (delete-todo todo)
               (ok (null (find-todo-by-ulid ulid user-id))
                   "todo is no longer found after deletion")))
        (when user (destroy user))))))

(deftest-suite :model test-todo-to-alist
  (testing "todo-to-alist returns an alist with expected keys"
    (let ((user (create-user "alistuser" "alistuser@example.com" "password123")))
      (unwind-protect
           (let ((todo (create-todo (ref user :id) "Alist test" :content "Some content")))
             (let ((alist (todo-to-alist todo)))
               (ok alist "returns a non-nil alist")
               (ok (assoc "ulid" alist :test #'string=) "has ulid key")
               (ok (assoc "subject" alist :test #'string=) "has subject key")
               (ok (assoc "content" alist :test #'string=) "has content key")
               (ok (assoc "completed" alist :test #'string=) "has completed key")
               (ok (assoc "createdAt" alist :test #'string=) "has createdAt key")
               (ok (assoc "updatedAt" alist :test #'string=) "has updatedAt key"))
             (when todo (delete-todo todo)))
        (when user (destroy user))))))
