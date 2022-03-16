;#lang r5rs
;(read-square-bracket-as-paren #t)
;;Depending on which version of scheme you are testing on,
;;  you can enable square brackets to be the same as round ones 

(define (zip l1 l2)
  (if (or (null? l1) (null? l2))
      '()
      (cons (cons (car l1) (car l2)) ( zip (cdr l1) (cdr l2)))))

(define (any? p? l)
  (if (null? l)
      #f
      (or (p? (car l)) (any? p? (cdr l)))))

(define (error reason . args)
  (display "Error: ")
  (display reason)
  (for-each (lambda (arg) 
              (display " ")
              (write arg))
            args)
  (newline))

(define error1
  (lambda ()
    (error "Match failed")))
;;pattern matching
(define-syntax match
  (syntax-rules (else guard)
    ((_ args (e ...) ...)  
     (match-aux args (e ...) ...))))

(define-syntax match-aux 
  (syntax-rules (else guard)
    ((_ (operator operand ...) tasks ...)
     (let ((v (operator operand ...)))
       (match-aux v tasks ...)))
    ((_ v)
     (error1))
    ((_ v (else task0 task1 ...))
     (begin task0 task1 ...))
    ((_ v (pattern (guard g ...) task0 task1 ...) cs ...)
     (let ((continue-next (lambda () (match-aux v cs ...))))
       (dec-pat v pattern (if (and g ...)
                              (begin task0 task1 ...)
                              (continue-next))
                (continue-next))))
    ((_ v (pattern task0 task1 ...) cs ...)
     (let ((continue-next (lambda () (match-aux v cs ...))))
       (dec-pat v pattern (begin task0 task1 ...) (continue-next))))))
  
(define-syntax dec-pat
  (syntax-rules (? comma unquote)
    ((_ v ? tasks next-m) tasks)
    ((_ v () tasks next-m) (if (null? v) tasks next-m))
    ((_ v (unquote var) tasks next-m) (let ((var v)) tasks))
    ((_ v (x . y) tasks next-m)
     (if (pair? v)
         (let ((vx (car v)) (vy (cdr v)))
           (dec-pat vx x (dec-pat vy y tasks next-m) next-m))
         next-m))
    ((_ v lit tasks next-m) (if (equal? v (quote lit)) tasks next-m))))

;;end of pattern matching definition


(define main-env '())
(define (env-bind! name value)
  (let ((bdg (assoc name main-env)))
    (if bdg
        (set-car! (cdr bdg) value)
        (set! main-env
              (cons (list name value) main-env)))))
(env-bind! '+ +)
(env-bind! '- -)
(env-bind! '* *)
(env-bind! '/ /)
(env-bind! '< <)
(env-bind! '> >)
(env-bind! '= =)
(env-bind! '<= <=)
(env-bind! '>= >=)
(env-bind! 'not not)
(env-bind! 'null? null?)
(env-bind! 'even? even?)
(env-bind! 'number? number?)
(env-bind! 'boolean? boolean?)
(env-bind! 'equal? equal?)
(env-bind! 'list? list?)
(env-bind! 'floor floor)
(env-bind! 'ceiling ceiling)
(env-bind! 'quotient quotient)
(env-bind! 'remainder remainder)
(env-bind! 'modulo modulo)
(env-bind! 'cons cons)
(env-bind! 'car car)
(env-bind! 'cdr cdr)
(env-bind! 'append append)


(define (env-get name)
  (cadr (assoc name main-env)))

(define (env-set! name value)
  (set-car! (cdr (assoc name main-env))
            value))

(define (eval-define! expr env)
  (if (pair? (cadr expr))
      (env-bind! (caadr expr)
                 (evalo (cons 'lambda (cons (cdadr expr) (cons (cddr expr) '() ))) env))
      (env-bind! (cadr expr)
                 (evalo (caddr expr) env))))
  
(define (eval-set! expr env)
  (env-set! (cadr expr)
            (evalo (caddr expr) env)))

(define (special-form-name? expr)
  (member expr '(cond list and or values define set! quote)))

(define (non-applicable? expr)
  (member expr '(if cond car list? and or values cdr map quote foldr lambda define set!)))

(define (eval-special-form expr env)
  (let ((name (car expr)))
    (cond ((eq? name 'define)
           (eval-define! expr env))
          ((eq? name 'set!)
           (eval-set! expr env))
          ((eq? name 'and)
           (eval-and expr env))
          ((eq? name 'or)
           (eval-or expr env))
          ((eq? name 'list)
           (eval-list expr env))
          ((eq? name 'quote)
           (eval-list (append '(list) (cadr expr)) env))
          ((eq? name 'values)
           (eval-values expr env))
          ((eq? name 'cond) 
           (eval-cond expr env)))))
(define (eval-and expr env)
  (if (null? (cdr expr))
      #t
      (and (evalo (cadr expr) env)  (eval-and (cdr expr) env))))

(define (eval-or expr env)
  (if (null? (cdr expr))
      #f
      (or (evalo (cadr expr) env)  (eval-or (cdr expr) env))))

(define (eval-list expr env)
  (if (null? (cdr expr))
      '()
      (cons (evalo (cadr expr) env) (eval-list (cdr expr) env) )))

(define (eval-values expr env)
  (define result
    (eval-list expr env))
  (apply values result))

(define  (eval-cond expr env)
  (let ((clause (caadr expr)) (body (cadadr expr)))
    (cond ((eq? clause 'else) (evalo body env))
          ((evalo clause env) (evalo body env))
          (else (evalo (cons (car expr) (cddr expr)) env)))))

(define env
  (lambda (y) (env-get y)))
(define (flatten-once l1)
  (if (null? l1)
      '()
      (append (if (not( pair? (car l1)))
                  (list (car l1) )
                  (car l1))
              (cdr l1))))
(define (interpret expr)
  (evalo (append '(values) expr) env))
(define evalo
  (lambda (expr env)
    (match expr
      (,x (guard (or (number? x) (boolean? x))) x)
      (,x (guard (and (pair? x) (special-form-name? (car x)))) (eval-special-form x env))
      (,x (guard (and (pair? x) (pair? (car x)) (not (eq? (caar x) 'lambda)) (not(null? (cdr x))) ))
          (if (member (caar x) '(define set!))
              (begin (evalo (car x) env) (evalo (cdr x) env))
              ((evalo (car x) env) (evalo (cadr x) env))))
      (,x (guard (and (pair? x) (pair? (car x)) (null? (cdr x)) ))
          (evalo (car x) env))
      (,x (guard (and (pair? x) (symbol? (car x))
                      (not (non-applicable? (car x) ))
                      (procedure? (env (car x)))))
          (apply (env (car x)) (map (lambda (x) (evalo x env)) (cdr x))))
      ((if ,x ,y ,z)
       (if (evalo x env)
           (evalo y env)
           (evalo z env)))
      ((map ,f ,x)
       (map (evalo f env) (evalo x env)))
      (,x (guard (symbol? x)) (env x))  
      ((lambda ,x ,body)
       (lambda args
         (let ((lambda-env (zip x args)))
           (evalo body (lambda (y)
                         (if (assoc y lambda-env)
                             (cdr  (assoc y lambda-env))
                             (env y)))))))
      ((,operator ,operand)
       ((evalo operator env)
        (evalo operand env))))))
  
