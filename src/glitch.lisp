(in-package :img-genner)
(declaim (optimize  (debug 3)))
(defun quick-get-pixel(image x y)
  (declare (type (simple-array (unsigned-byte 8) (* * 3)) image)
           (type fixnum x y) (optimize (speed 3)))
  (values (aref image y x 0) (aref image y x 1) (aref image y x 2)))

(defun compare-colors-bytewise(c1 c2)
  (declare (type (vector (unsigned-byte 8) 3) c1 c2))
  (loop for a across c1
        for b across c2
          until (not (= a b))
        finally (return (< a b))))
(defun compare-colors-magnitude(c1 c2)
  (declare (type (simple-array (unsigned-byte 8)) c1 c2)
           (optimize (speed 3) (safety 0)))
  (< (+ (aref c1 0) (aref c1 1) (aref c1 2))
     (+ (aref c2 0) (aref c2 1) (aref c2 2))))
;  (loop for i fixnum across c1
;        for j fixnum across c2
;        summing i into c3 fixnum
;        summing j into c4 fixnum
;        finally (return (< c3 c4))))
(declaim (inline compare-colors-magnitude))
(defun split-n-length(input l)
  "split a sequence into segments of at most l elements"
  (let ((len (length input)))
    (loop for start = 0 then (+ start l)
          for end = (min len (+ start l)) then (min len (+ start l))
          collect (subseq input start end)
          until (= end len)
          )
    ))
(defun sort-along-line(image line &optional (comparison #'compare-colors-bytewise))
  "Sort according to the values of pixels in image along the coordinate pairs in line
using the comparison function passed"
  (declare (optimize (speed 3))
           (type (simple-array (unsigned-byte 8) (* * 3)) image)
           (type (vector cons) line)
           (type (function (vector vector)
                           boolean)
                 comparison)
           (inline get-pixel swap-pixel)
           )
  (let ((comb-length (length line))
        (sorted nil)
        (shrink 1.3)
        (color-a (make-array 3 :element-type '(unsigned-byte 8)))
        (color-b (make-array 3 :element-type '(unsigned-byte 8))))
    (loop for gap fixnum = comb-length then (floor gap shrink)
                                        ;Implementation of Comb sort, as it is fast,
                                        ;lightweight, and very easy to write
          when (<= gap 1)
            do(setf gap 1
                    sorted t)
          do(loop for i = 0 then (1+ i)
                  for j = (+ i gap) then (1+ j)
                  while (< (+ i gap) comb-length)
                  for (ax . ay) = (aref line i) then (aref line i)
                  for (bx . by) = (aref line j) then (aref line j)
                  when (funcall comparison
                                (get-pixel image ax ay color-a)
                                (get-pixel image bx by color-b))
                    do(progn (swap-pixel image ax ay bx by)
                             (setf sorted nil))
                  )
          while (not sorted))))
(defun ordinal-pixel-sort(image &key (comparison #'compare-colors-bytewise)
                                  (segment-length 20) (direction :left))
  (declare (optimize (speed 2))
           (type (simple-array (unsigned-byte 8) (* * *)) image))
  (flet ((line (start)
           "start is the x or y coordinate to use"
           (multiple-value-bind (offset-x offset-y start-x start-y)
               (ecase direction
                 (:left (values -1 0 (1- (array-dimension image 1)) start))
                 (:right (values 1 0 0 start))
                 (:up (values 0 1 start 0))
                 (:down (values 0 -1 start (1- (array-dimension image 0))))
                 )
             (loop with r = (make-array 100 :adjustable t :fill-pointer 0)
                   for x fixnum = start-x then (+ x offset-x)
                   for y fixnum = start-y then (+ y offset-y)
                   while (and (>= x 0) (< x (array-dimension image 1))
                              (>= y 0) (< y (array-dimension image 0)))
                   do(vector-push-extend (cons x y) r)
                   finally (return r)
                   )
             )))
    (loop for i from 0 below (array-dimension image (ecase direction (:up 1) (:down 1) (:left 0) (:right 0)))
          do(loop for l in (split-n-length (line i) segment-length)
                  do(sort-along-line image l comparison))
          )
    ))
(defun color-diff(c1 c2)
  (declare (type (simple-array (unsigned-byte 8) (3)) c1 c2)
           (optimize speed (safety 0)))
  (let* ((r1 (aref c1 0))
         (r2 (aref c2 0))
         (g1 (aref c1 1))
         (g2 (aref c2 1))
         (b1 (aref c1 2))
         (b2 (aref c2 2))
         (dr (coerce (- r1 r2) 'single-float))
         (dg (coerce (- g1 g2) 'single-float))
         (db (coerce (- b1 b2) 'single-float)))
    (+ (* dr dr) (* dg dg) (* db db))))
(defun color-brightness(c1 c2)
  (declare (type (simple-array (unsigned-byte 8) (3)) c1 c2)
           (optimize speed (safety 0)))
  (let* ((s1 (+ 0.0 (aref c1 0) (aref c1 1) (aref c1 2)))
         (s2 (+ 0.0 (aref c2 0) (aref c2 1) (aref c2 2)))
         (d (- s1 s2)))
         (* d d)
         ))
(defun color-hue(c1 c2)
  (declare (type (simple-array (unsigned-byte 8) (3)) c1 c2)
           (optimize speed (safety 0)))
  (let ((r1 (aref c1 0))
        (r2 (aref c2 0))
        (g1 (aref c1 1))
        (g2 (aref c2 1))
        (b1 (aref c1 2))
        (b2 (aref c2 2)))
    (let ((h1 (rgb-to-hsl r1 g1 b1))
          (h2 (rgb-to-hsl r2 g2 b2)))
      (declare (type (simple-array single-float (3) ) h1 h2)
               (dynamic-extent h1 h2))
      (expt (- (aref h1 0) (aref h2 0)) 2.0)
    )))
(defun copy-tile(dest dx dy src sx sy tw th)
  (declare (type (array (unsigned-byte 8) (* * 3)) dest src)
           (type fixnum dx dy sx sy tw th)
           (optimize speed))
  (loop for y fixnum from 0 below th
        with pix = (make-array '(3) :element-type '(unsigned-byte 8) :initial-element 0)
        do(loop for x fixnum from 0 below tw
                do(set-pixel dest (the fixnum (+ dx x)) (the fixnum (+ dy y)) (get-pixel src (the fixnum (+ sx x)) (the fixnum (+ sy y)) pix)))))
(defun compare-tiles(dest dx dy src sx sy width height &key (distance #'color-diff) (threshold 1e15) (sample-mask nil))
  (declare (type (simple-array (unsigned-byte 8) (* * 3)) dest src)
           (type function distance)
           (type fixnum dx dy sx sy width height)
           (type single-float threshold)
           (type (or null (simple-array bit (* *))) sample-mask)
           (type (function ((simple-array (unsigned-byte 8) (3))
                             (simple-array (unsigned-byte 8) (3)))
                            single-float)
                  distance)
           (optimize speed (safety 0)))
  (loop with not-empty = nil
        for x from 0 below width
        for dpx fixnum = (+ x dx)
        for spx fixnum = (+ x sx)
        with threshold = (* threshold threshold)
        with total = 0.0
        with pix-a = (make-array '(3) :element-type '(unsigned-byte 8) :initial-element 0 :adjustable nil)
        with pix-b = (make-array '(3) :element-type '(unsigned-byte 8) :initial-element 0 :adjustable nil)
        do(loop for y from 0 below height
                for dpy = (min (1- (array-dimension dest 0)) (+ y dy))
                for spy = (min (1- (array-dimension src 0)) (+ y sy))
                for spix = (get-pixel src spx spy pix-a)
                for dpix = (get-pixel dest dpx dpy pix-b)
;               when (or (> (max (aref dpix 0) (aref dpix 1) (aref dpix 2)) 20))
;                  do(setf not-empty t)
                when (or (not sample-mask) (bit sample-mask y x))
                do(incf (the single-float total) (funcall distance spix dpix))
                until(> total threshold)
                )
        until (> total threshold)
        finally (return (the single-float (if t (sqrt total) (* 2 threshold)))))
  )
(defun tile-coordinates(tile-width tile-height image-width image-height)
              (loop for y from 0 below (* tile-height (floor image-height tile-height)) by tile-height
                    until (> (+ y tile-height) image-height);cut off partial tiles :3
                    appending (loop for x from 0 below (* tile-width (floor image-width tile-width)) by tile-width
                                    until(> (+ x tile-width) image-width)
                                    collecting (cons x y))
                    ))
#+sbcl (declaim (sb-ext:maybe-inline improve-tile))
(defun improve-tile(i1 x1 y1 i2 x2 y2 tw th cost distance sample-mask)
  "Attempt to shift the tile diagonally a bit, so long as the match is better than the current one"
  (declare (optimize speed)
           (type fixnum x1 y1 x2 y2 tw th)
           (type single-float cost)
           (type (simple-array bit (* *)))
           (type (simple-array (unsigned-byte 8) (* * 3)) i1 i2))
  (loop with best-x = x2
        with best-y = y2
        with best-cost = cost
        for offset fixnum from 1
        for x fixnum = (+ x2 offset)
        until (>= (+ tw x) (1- (array-dimension i2 1)))
        for y fixnum = (+ y2 offset)
        until (>= (+ th y) (1- (array-dimension i2 0)))
        for ncost = (compare-tiles i1 x1 y1 i2 x y tw th :distance distance :sample-mask sample-mask)
        until (<= best-cost ncost)
        when (< ncost best-cost)
          do(progn
              (setf best-cost ncost
                    best-x x
                    best-y y))
        finally (progn
                  (return (cons best-x best-y)))
        )
  )
(defun  most-similar-tiles(i1 x1 y1  i2 width height tile-width tile-height &key (distance #'color-diff) (sample-mask nil))
  "Find the most similar tiles by a given metric. i1 is the image with the tile and i2 is the image you want to find the best tile from.
Width and height are for i2, hence their place in the order."
  (declare (optimize speed))
  (loop for coord in (alexandria:shuffle (tile-coordinates tile-width tile-height width height))
        for x fixnum = (car coord) then (car coord)
        for y fixnum = (cdr coord) then (cdr coord)
        for cost = (compare-tiles i1 x1 y1 i2 x y tile-width tile-height :distance distance :threshold (or best-cost 20000.0) :sample-mask sample-mask)
        with best = '(0 . 0)
        with best-cost = (compare-tiles i1 x1 y1 i2 0 0 tile-width tile-height :distance distance :sample-mask sample-mask)
        when (and coord (> best-cost cost))
                                        ;This seems like it could be extended to keep on following the improvement until it stops improving, but the
                                        ;details are taxing to us right now and we are putting it off for later
             do(let* ((alt (cons (+ x (the fixnum (if (= x (the fixnum (- (array-dimension i2 1) 1))) 1 -1))) (+ y (if (= y (- (array-dimension i2 0) 1)) 1 -1))))
                      (alt-cost (compare-tiles i1 x1 y1 i2 (car alt) (cdr alt) tile-width tile-height :distance distance :threshold best-cost :sample-mask sample-mask)))
                 (when (> cost alt-cost) (setf coord alt cost alt-cost))
                 (setf best coord
                       best-cost cost))
        finally (return  (improve-tile i1 x1 y1 i2 (car best) (cdr best) tile-width tile-height best-cost distance sample-mask)))
  )
#|-------------------------------------------------------------------------------------------------------------------------------------------
 | There is some room for improvement here, namely in that it would benefit from being able to pass the whole chunk of the image
 | to a higher order function. Example use cases for this change include:
 |
 | 1. distance based off of Edge detection
 |    Cannot be made to reasonably work without having access to the entire tiles at once
 | 2. Matching tiles based on a specific subset of the pixels in each tile, eg, the pixels on the diagonal lines/the edges
 | 3. 
 |
 | At the same time, we tend to feel that this is a rather fragile functionality, and that honestly the degree to which it is optimized
 | may present difficulties if other implementations handle the specific typing differently.
 |------------------------------------------------------------------------------------------------------------------------------------------|#
(defun mosaify(src dest tile-width tile-height &key (save-intermediate t) (distance #'color-diff) (sample-mask nil) (shuffle-tiles t))
  (declare (optimize speed)
           (type (simple-array (unsigned-byte 8) (* * 3)) src dest)
           (type fixnum tile-width tile-height))
  (let ((result (make-image (array-dimension src 1) (array-dimension src 0))))
    (loop
      with tile-count = (* (floor (array-dimension src 0) tile-height) (floor (array-dimension src 1) tile-width))
      with tiles = (if shuffle-tiles (alexandria:shuffle (tile-coordinates tile-width tile-height (array-dimension src 1) (array-dimension src 0)))
                       (tile-coordinates tile-width tile-height (array-dimension src 1) (array-dimension src 0)))
      with jobz = (loop for chunk in (split-n-length tiles (ceiling tile-count (pcall:thread-pool-size)))
                        collecting(let ((chunk chunk))
                                    (pcall:pexec (loop for i in chunk
                                                       for x fixnum = (car i)
                                                       for y fixnum = (cdr i)
                                                       do(let ((best (most-similar-tiles src x y dest (array-dimension dest 1) (array-dimension dest 0) tile-width tile-height :distance distance :sample-mask sample-mask)))
                                                           (copy-tile result x y dest (car best) (cdr best) tile-width tile-height))
                                                       ))))
      for i in jobz
      do(pcall:join i))
    result
  ))
(defun central-pixel-sort (image cx cy
                           &key
                            (comparison #'compare-colors-bytewise)
                             (segment-length 20))
  (declare (optimize (speed 2))
           (type fixnum cx cy segment-length)
           (type (simple-array (unsigned-byte 8) (* * *)) image)
           (inline line-index-interpolator))
  (let ((buffer (make-array 30 :adjustable t :fill-pointer 0)))
    (loop for y from 0 below (array-dimension image 0)
          do(loop for i in (split-n-length (line-index-interpolator 0 y cx cy buffer) segment-length)
                  do(sort-along-line image i comparison)
                  )
          do(loop for i in (split-n-length
                            (line-index-interpolator (1- (array-dimension image 1))
                                                     y cx cy buffer)
                            segment-length)
                  do(sort-along-line image i comparison))
          )
    (loop for x from 0 below (array-dimension image 1)
          do(loop for i in (split-n-length (line-index-interpolator x 0 cx cy buffer)
                                           segment-length)
                  do(sort-along-line image i comparison)
                  )
          do(loop for i in (split-n-length
                            (line-index-interpolator x (1- (array-dimension image 0))
                                                     cx cy buffer)
                                           segment-length)
                  do(sort-along-line image i comparison)
                  )
          )
    ))
(defun fuck-it-up-pixel-sort (image cx cy
                           &key
                             (comparison #'compare-colors-bytewise)
                             (segment-length 20))
  (declare (type fixnum cx cy segment-length)
           (type (simple-array (unsigned-byte 8) (* * *)) image)
           (optimize (speed 2)))
  (loop for y from 0 below (array-dimension image 0)
        do(loop for x from 0 below (array-dimension image 1)
                do(loop for i in (split-n-length (line-index-interpolator x y cx cy) segment-length)
                        do(sort-along-line image i comparison)
                        ))
        )
  )
(defun swap-tiles(image tile-width tile-height x1 y1 x2 y2)
  "Swap a segment of an image consisting of tile-width by tile-height pixels, the first starting at x1,y1 and the second starting at x2,y2"
  (declare (type (simple-array (unsigned-byte 8) (* * 3)) image)
           (type fixnum tile-width tile-height x1 y1 x2 y2)
           (optimize speed)
           (inline swap-pixel))
  (dotimes (y tile-height)
    (dotimes (x tile-width)
      (declare (type fixnum x y))
      (swap-pixel image (the fixnum (+ x1 x))
                  (the fixnum (+ y1 y))
                  (the fixnum (+ x2 x))
                  (the fixnum (+ y2 y))))))
(defun swap-tiles-2(tile-width tile-height image1 x1 y1 image2 x2 y2)
  (declare (type fixnum tile-width tile-height x1 y1 x2 y2)
           (type (simple-array (unsigned-byte 8) (* * 3)) image1 image2))
  (dotimes (y tile-height)
    (dotimes (x tile-width)
      (declare (type fixnum x y))
      (swap-pixel-2 image1 (+ x x1) (+ y y1)
                    image2 (+ x x2) (+ y y2))))
  )
(defun range-vector(start end)
  (loop with r = (make-array (- end start) :element-type 'fixnum :fill-pointer 0)
        for i from start below end do(vector-push i r)
        finally (return r)))
(defun scramble-vector(r)
  "Take a vector r and scramble it using the \"random\" function. Destructively modifies r"
  ;Fisher Yates/Knuth Shuffle implementation
  (loop for i from (1- (fill-pointer r)) above 1
        for j = (random i) then (random i)
        do(psetf (aref r i) (aref r j)
                 (aref r j) (aref r i))
        finally (return r)
        ))
(defun scramble-image(image tile-width tile-height)
  "Swap tiles of (tile-width x tile-height) in the image."
  (declare (type (simple-array (unsigned-byte 8) (* * 3)) image)
           (type fixnum tile-width tile-height)
           (optimize speed))
  (let* ((columns (floor  (array-dimension image 1) tile-width))
        (rows (floor  (array-dimension image 0) tile-height))
        (tile-vec (scramble-vector (range-vector 0 (* (the (integer 0 1000000000000) columns) (the (integer 1 100000) rows))))))
    (declare (type fixnum columns rows))
    (flet ((tile-x (index)
             (declare (optimize speed)
                      (type fixnum index))
             (* tile-width (the (values fixnum) (mod index columns))))
           (tile-y (index)
             (declare (optimize speed)
                      (type fixnum index))
             (* tile-height (the fixnum (floor index columns)))))
      (loop for i fixnum = 0 then (1+ i)
            for j fixnum across tile-vec
            do(swap-tiles image tile-width tile-height
                          (tile-x i) (tile-y i)
                          (tile-x j) (tile-y j))))))
(defun scramble-image-2(tile-width tile-height image1 image2)
  "Scramble two images into each other with a specified tile size
It is an error to specify images that are of different dimensions"
  (declare (type fixnum tile-width tile-height)
           (type (simple-array (unsigned-byte 8) (* * 3)) image1 image2))
  (when (not (and (= (array-dimension image1 0) (array-dimension image2 0))
                  (= (array-dimension image1 1) (array-dimension image1 1))))
      (error "Image1 and image2 have differing sizes. This is not supported"))
  (let* ((columns (floor  (array-dimension image1 1) tile-width))
         (rows (floor  (array-dimension image1 0) tile-height))
         (tile-vec (scramble-vector
                    (loop with r = (make-array 1 :adjustable t :fill-pointer 0 :element-type 'list :initial-element nil)
                          for i across (range-vector 0 (* columns rows))
                          do(progn (vector-push-extend (list image1 i) r)
                                   (vector-push-extend (list image2 i) r))
                          finally (return r)))))
    (declare (type fixnum columns rows))
    (flet ((tile-x (index)
             (* tile-width (mod index columns)))
           (tile-y (index)
             (declare (optimize speed)
                      (type fixnum index))
             (* tile-height (floor index columns))))
      (print (aref tile-vec 0))
      (loop for idx from 1 below (length tile-vec)
            for j = (aref tile-vec (1- idx)) then (aref tile-vec (1- idx))
            for i = (aref tile-vec idx) then (aref tile-vec idx)

            do(destructuring-bind (im1 tile1) i
                (destructuring-bind (im2 tile2) j
                (swap-tiles-2 tile-width tile-height
                            im1 (tile-x tile1) (tile-y tile1)
                            im2 (tile-x tile2) (tile-y tile2)))))
    )
    ))
(defun intensify-blur(image offset)
  "Performs a simple linear blur from left to right on the specified interval"
  (declare (optimize (speed 2))
           (type (simple-array (unsigned-byte 8) (* * *)) image)
           (type fixnum offset))
  (loop for y fixnum from 0 below (array-dimension image 0)
        with start-x = (whenz (< offset 0) (abs offset))
        with end-x = (- (array-dimension image 1)(whenz (> offset 0) offset))
        do(loop for x fixnum from start-x below end-x
                for x-off fixnum = (+ x offset)
                do(loop for c fixnum from 0 below (array-dimension image 2)
                        do(setf (aref image y x c)
                                (floor (+ (aref image y x c)
                                          (aref image y x-off c))
                                       2))
                        )
                )
          finally (return image)
        )
  )

(defun intensify-blur-nd(im offset)
  "Performs a simple linear blur from left to right on the specified interval. Non-destructive, different than intensify-blur"
  (declare (optimize (speed 2))
           (type (simple-array (unsigned-byte 8) (* * *)) im)
           (type fixnum offset))
  (loop with image = (the (simple-array (unsigned-byte 8) (* * *)) (copy-image im))
        for y fixnum from 0 below (array-dimension im 0)
        with start-x = (whenz (< offset 0) (abs offset))
        with end-x = (+ (array-dimension image 1)(whenz (< offset 0) offset))
        do(loop for x fixnum from start-x below end-x
                for x-off fixnum = (+ x offset)
                do(loop for c fixnum from 0 below (array-dimension image 2)
                        do(setf (aref image y x c)
                                (floor (+ (aref im y x c)
                                          (aref im y x-off c))
                                       2))
                        )
                )
        finally (return image)
        ))
(defun set-pixel-rgb(image x y r g b)
  (declare (type fixnum x y)
           (type (unsigned-byte 8) r g b)
           (type (simple-array (unsigned-byte 8) (* * 3)) image)
           (optimize speed))
  (setf (aref image y x 0) r
        (aref image y x 1) g
        (aref image y x 2) b))
(defun rgb-to-hsl(r g b)
  (declare (optimize speed)
           (type (unsigned-byte 8) r g b))
  (let* ((r (/ r 255.0))
         (g (/ g 255.0))
         (b (/ b 255.0))
         (mx (max r g b))
         (mn (min r g b))
         (l (/ (+ mx mn) 2.0))
         (h 0.0)
         (s 0.0))
    (if (= mx mn)
        (setf s 0.0 h 0.0)
        (let ((d (- mx mn)))
          (setf s (if (> l 0.5) (/ d (- 2 mx mn)) (/ d (+ mn mx))))
          (setf h
                (cond
                  ((= r mx) (+ (/ (- g b) d)
                        (if (< g b) 6 0)))
                  ((= g mx) (+ 2 (/ (- b r) d)))
                  ((= b mx) (+ 4 (/ (- r g) d)))))
          ))
    (make-array 3 :element-type 'single-float :initial-contents  `(,h ,s ,l))))

(defun apply-vector(function vector)
  (apply function (coerce vector 'list)))
(defun map-region(image x y width height func)
  (declare (type (simple-array (unsigned-byte 8) (* * 3)) image)
           (type fixnum x y width height)
           (type (function ) func))
  (loop for ix from x below (+ width x)
        do(loop for iy from y below (+ height y)
                for r1 = (aref image iy ix 0)
                for g1 = (aref image iy ix 1)
                for b1 = (aref image iy ix 2)
                do(multiple-value-bind (r g b)
                      (funcall func r1 g1 b1)
                    (set-pixel-rgb image ix iy r g b))))
  )

(defun to-fractional-color(r g b)
  (map 'vector (lambda (a) (/ a 255.0)) (list r g b)))
(defun from-fractional-color(r g b)
  (map 'vector (lambda (a) (floor (* a 255))) (list r g b)))

(export '(compare-colors-bytewise sort-along-line compare-colors-magnitude ordinal-pixel-sort
          central-pixel-sort fuck-it-up-pixel-sort scramble-image scramble-image-2 intensify-blur
          intensify-blur-nd rgb-to-hsl mosaify))
