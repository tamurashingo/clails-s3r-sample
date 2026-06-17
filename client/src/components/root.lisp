; -*- mode: lisp -*-
(in-package #:cl-user)
(defpackage #:todo-client/components/root
  (:use #:cl)
  (:import-from #:cl-s3r.component #:define-layout #:define-component))

(in-package #:todo-client/components/root)

(define-layout app-layout (&key children &allow-other-keys)
  `(:html
    (:head
     (:meta (@ (:charset "UTF-8")))
     (:meta (@ (:name "viewport") (:content "width=device-width, initial-scale=1.0")))
     (:title "TODO App")
     (:style "
       body { font-family: sans-serif; max-width: 800px; margin: 0 auto; padding: 1rem; }
       .error { color: red; margin: 0.5rem 0; }
       .success { color: green; margin: 0.5rem 0; }
       input, textarea { display: block; width: 100%; margin: 0.25rem 0 0.75rem; padding: 0.4rem; box-sizing: border-box; }
       button, .btn { padding: 0.4rem 1rem; cursor: pointer; }
       .header { display: flex; justify-content: space-between; align-items: center; }
       .todo-item { display: flex; align-items: center; gap: 0.5rem; border: 1px solid #ccc; padding: 0.5rem; margin: 0.5rem 0; }
       .todo-item .todo-link { flex: 1; }
       .todo-item .deadline { font-size: 0.85em; color: #666; white-space: nowrap; }
       .todo-item.done .todo-link { text-decoration: line-through; color: #aaa; }
       .complete-checkbox { width: auto; margin: 0; cursor: pointer; }
       .modal-overlay { position: fixed; inset: 0; background: rgba(0,0,0,0.5); align-items: center; justify-content: center; z-index: 100; }
       .modal { background: #fff; padding: 1.5rem; border-radius: 8px; width: 420px; max-width: 90vw; box-shadow: 0 4px 24px rgba(0,0,0,0.2); }
       .modal h2 { margin-top: 0; }
       .modal-actions { margin-top: 1rem; display: flex; gap: 0.5rem; }
     "))
    (:body
     ,children)))

(define-component not-found-page (&key message &allow-other-keys)
  `(:div (@ (:class "error"))
     (:h1 "404 - Not Found")
     ,@(when message `((:p ,message)))
     (:a (@ (:href "/todos")) "<- Back to list")))

(define-component server-error-page (&key message &allow-other-keys)
  `(:div (@ (:class "error"))
     (:h1 "500 - Internal Server Error")
     ,@(when message `((:p ,message)))
     (:a (@ (:href "/todos")) "<- Back to list")))
