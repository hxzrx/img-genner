(in-package "img-genner")

(defmacro with-array-items(items array &body body)
  `(symbol-macrolet ,(loop for i in items
                           collect (list (first i)  (cons 'aref (cons array (rest i))))
                           )
     ,@body)
  )
(defun copy-vector-extend(vec item)
  (let ((v (make-array (1+ (array-dimension vec 0))
                       :element-type (array-element-type vec)
                       :fill-pointer 0
                       :adjustable t)))
    (loop for i across vec
          do(vector-push-extend i v))
    (vector-push-extend item v)
    v))
(print (macroexpand '(with-array-items ((a 1 2)(b 2 3)) c (setf a 2 b 5))))
