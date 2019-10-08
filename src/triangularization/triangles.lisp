(in-package img-genner/triangularization)
(defun clockwisep(polygon)
  (let ((points (coerce polygon 'vector)))
    (> 0
       (loop for rj from 1 to (length points)
             for i = (1- rj) then (1+ i)
             for j = (mod rj (length points)) then (mod rj (length points))
             summing (* (- (aref (svref points j) 0) (aref (svref points i) 0))
                        (- (aref (svref points j) 1) (aref (svref points i) 1)))
             ))))
(defun convexp(a b c)
  (> (triangle-sum (aref a 0) (aref a 1)
                   (aref b 0) (aref b 1)
                   (aref c 0) (aref c 1)) 0))
(defun triangle-sum (x1 y1 x2 y2 x3 y3)
  (+ (* x1 (- y2 y3))
     (* x2 (- y3 y1))
     (* x3 (- y2 y1))))
(defun triangle-area(x1 y1 x2 y2 x3 y3)
  (abs (/ (triangle-sum x1 y1 x2 y2 x3 y3) 2.0)))
(defun point-insidep(p a b c)
  (flet ((triangle-area (a b c)
           (triangle-area
            (aref a 0) (aref a 1)
            (aref b 0) (aref b 1)
            (aref c 0) (aref c 1)
            )))
    (let ((area (triangle-area a b c))
          (area1 (triangle-area p b c))
          (area2 (triangle-area p a c))
          (area3 (triangle-area p a b)))
      (> (sqrt single-float-epsilon)
         (abs (- area (+ area1 area2 area3)))))))
(defun contains-no-points(a b c polygon)
  (loop for i across polygon
        never (and (not (or  (equal a i)
                             (equal b i)
                             (equal c i)))
                   (point-insidep i a b c))))
(defun is-earp(a b c polygon)
  (and (contains-no-points a b c polygon)
       (convexp a b c)
       (> (triangle-area (aref a 0) (aref a 1)
                         (aref b 0) (aref b 1)
                         (aref c 0) (aref c 1))
          0.0)))
(defun ear-test(point earlist)
  (equal point (first earlist)))
(defun earclip(poly)
  "Triangulate a polygon O(N^2) time, use carefully :)"
  (let ((polygon (coerce poly 'vector))
        (ear-vertices nil)
        (point-count (length poly))
        (triangles nil))
    (when (clockwisep polygon)
      (setf polygon (reverse polygon)))
    (loop for i from 0 to (1- (length polygon))
          for prev-index = (mod -1 point-count) then (mod (1+ prev-index) point-count)
          for next-index = 1 then (mod (1+ next-index) point-count)
          when (is-earp (svref polygon prev-index)
                        (svref polygon i)
                        (svref polygon next-index) polygon)
            do(progn (print "found one") (if (not ear-vertices)
                                             (setf ear-vertices (list (list (svref polygon i)
                                                                            (svref polygon prev-index)
                                                                            (svref polygon next-index))))
                                             (push (list (svref polygon i)
                                                         (svref polygon prev-index)
                                                         (svref polygon next-index))
                                                   ear-vertices))))
    (loop while (and ear-vertices (> point-count 3))
          for (ear prev next) = (pop ear-vertices) then (pop ear-vertices)
          with ear-index =(position ear polygon :test #'equal)
          do(setf ear-index (position ear polygon :test #'equal))
          do (setf polygon (delete ear polygon :test #'equal))
          do(push (list prev ear next) triangles)
          do(decf point-count)
          when (> point-count 3)
            do(let* ((prev-prev-index (mod (- ear-index 2) point-count))
                     (next-next-index (mod (+ ear-index 2) point-count))
                     (prev-prev-point (aref polygon prev-prev-index))
                     (next-next-point (aref polygon next-next-index)))
                (loop for i in (list (list prev-prev-point prev next polygon)
                                     (list prev next next-next-point polygon))
                      do(if (apply #'is-earp i)
                            (if (not (member (first i) ear-vertices :test #'ear-test))
                                (push (subseq i 0 3) ear-vertices)
                                )
                            (when(member (first i) ear-vertices :test #'ear-test)
                              (setf ear-vertices
                                    (delete (first i) ear-vertices :test #'ear-test))
                                )
                            )

                  )
                )
          when (= 3 point-count)
            do(push (coerce polygon 'list) triangles)
          )
    (map 'list #'reverse triangles)
    ))
