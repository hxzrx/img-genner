(require 'png)
(in-package "img-genner")

(defun set-pixel(image x y color)
  "Bounds respecting color setting"
  (if (and
       (< x (array-dimension image 1))
       (< y (array-dimension image 0))
       (= (array-dimension color 0) (array-dimension image 2)))
      (loop for i across color
            for z = 0 then (1+ z)
            do(setf (aref image y x z) i)))
  )

(defun set-pixel-component(image x y c color)
  "Bounds respecting color setting, but more convenient for gradients"
  (if (and
       (< x (array-dimension image 1))
       (< y (array-dimension image 0))
       (< c (array-dimension image 2)))
      (setf (aref image y x c) color)
      )
  )
(defun interpolate(max a b frac)
  (let ((f (max 0 (min 1 frac))))
    (+ (* a (- 1 frac))
       (* b frac))))
(defun static-color-stroker(color)
  (lambda (i x y frac)
    (declare (ignore frac))
    (set-pixel i x y color)
    ))
(defun gradient-color-stroker(c1 c2)
  "This returns a function that can be used to color a line/line-like object with a gradient
based on how far the coordinate is along the line"
  (lambda (i x y frac)
    (loop for a across c1
          for b across c2
          for z = 0 then (1+ z)
          do(set-pixel-component i x y z
                  (coerce (truncate
                           (+ (* a (- 1 frac))
                              (* b frac)))
                          '(unsigned-byte 8)))
          )
    )
  )
(defun radial-gradient-stroker(c1 c2 center-x center-y maxradius)
  "Creates a radial gradient stroker centered on a given coordinate, with a scale up to max radius"
  (lambda (i x y frac)
    (declare (ignore frac))
    (loop for a across c1
          for b across c2
          for z = 0 then (1+ z)
          with d = (min 1.0
                        (max 0
                             (/ (sqrt (+
                                       (expt (- x center-x) 2)
                                       (expt (- y center-y) 2)
                                       ))
                                maxradius)
                             ))
          do(set-pixel-component i x y z
                  (coerce (truncate
                           (+ (* a (- 1 d)) (* b d)))
                          '(unsigned-byte 8))
                  )
          )
    )
  )
(defun calculate-bounding-box(segments)
  (loop for i in segments
        for x = (aref i 0 0) then (aref i 0 0)
        for y = (aref i 1 0) then (aref i 1 0)
        maximizing x into max-x
        minimizing y into min-y
        maximizing y into max-y
        minimizing x into min-x
        finally (return
                  (list (vector min-x max-y)
                        (vector max-x min-y))
                  )
;          when (> x (aref bottom-right 0))
;            do(setf (aref bottom-right 0) x)
;          when (< x (aref top-left 0))
;            do(setf (aref top-left 0) x)
;          when (> y (aref top-left 1))
;            do(setf (aref top-left 1) y)
;          when (< y (aref bottom-right 1))
;            do(setf (aref bottom-right 1) y)
          )
  )

(defun stroke-h-line(image stroker start end)
  (let ((sx (truncate (aref start 0 0)))
        (ex (truncate (aref end 0 0)))
        (y (truncate (aref start 1 0))))
;    (format t "stroking color from ~a to ~a \n" sx ex)
    (loop for i from sx to ex
          for frac = 0.0 then (/ (- i sx)
                                 (- ex
                                    sx))
          do (funcall stroker image i y frac)
          ))
  )
(defun line-pairs(l)
  "Generate pairs of lines that can be stroked in order to fill a polygon."
  (loop for i from 0 upto (1- (length l))
        with a = nil
        with b = nil
        when (evenp i)
          do(setf a (elt l i))
        when (oddp i)
          collect `(,a . ,(elt l i))
   )
  )
(defun fill-shape(segments image stroker)
  (let* ((dim (calculate-bounding-box segments))
         (startx (truncate (aref (first dim) 0)))
         (endx (truncate (aref (second dim) 0)))
         (starty (truncate (aref (second dim) 1)))
         (endy (truncate (aref (first dim) 1)))
         (lines (get-lines segments))
         )
    ;(format t "Looking for intersections between y coords ~A ~A" starty endy)
    (loop for y from starty upto endy
          do(map 'list
                 (lambda (x)
                   (stroke-h-line image stroker (car x) (cdr x))
                   )
                 (line-pairs
                  (sort (remove-if-not #'identity
                                       (map 'list
                                            (lambda (x)
                                              (get-intersection startx y endx y
                                                                (aref (car x) 0 0)
                                                                (aref (car x) 1 0)
                                                                (aref (cdr x) 0 0)
                                                                (aref (cdr x) 1 0)
                                                                )
                                              )
                                            lines))
                        #'compare-points)))
          )
    ))
;TODO figure out how to just do this on call, rather than all the time
(let ((a (make-instance 'ellipse))
      (b (png:make-image 101 101 3)))
  (setf (slot-value a 'radius) #(50 50)
        (slot-value a 'center) #2a((50)(50)(0)))
  (format t "Line pairs: ~a" (line-pairs (get-segments a :max-degree 10)))(terpri)
  (fill-shape (get-segments a) b (static-color-stroker #(255 0 0)))
  (with-open-file (f "hello.png" :direction :output :element-type '(unsigned-byte 8) :if-exists :supersede :if-does-not-exist :create)
    (png:encode b f))
  (fill-shape (get-segments a :max-degree 20) b (radial-gradient-stroker #(255 0 0 0) #(0 255 0) 50 50 50))
  (with-open-file (f "hello1.png" :direction :output :element-type '(unsigned-byte 8) :if-exists :supersede :if-does-not-exist :create)
    (png:encode b f))
  )
(let ((a (loop repeat 4
               for i = 20 then (+ i 35)
               collect (let ((g (make-instance 'ellipse )))
                         (setf (slot-value g 'radius) (vector 20 20)
                               (slot-value g 'center) (make-array '(3 1)
                                                                  :initial-contents  `((,i)
                                                                                       (20.0)
                                                                                       (0.0))))
                         g
                         )))
      (colors (list (vector 255 0 0) (vector 0 255 0) (vector 0 0 255) (vector 255 0 255)))
      (b (png:make-image 40 400 3)))
  (loop for i in a
        for c in colors
        do(fill-shape (get-segments i :max-degree 20)
                      b
                      (static-color-stroker c))
        )
  (with-open-file (f "circles.png" :direction :output :element-type '(unsigned-byte 8)
                                    :if-exists :supersede :if-does-not-exist :create)
    (png:encode b f)
    )
  )
