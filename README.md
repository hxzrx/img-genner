# Img-Genner

## Violet White

Lightweightish, but (not ergonomic) set of routines for manipulating or
generating images.

To get started, you'll need to clone a copy of cl-png from a non-master branch,
the one in quicklisp has a dependency that you shouldn't try to satisfy(an
ancient version of libpng).

```bash
cd ~/quicklisp/local-projects
git clone -b vl-anyversion clone https://github.com/ljosa/cl-png
```

Then clone this project to the same location

```bash
cd ~/quicklisp/local-projects
git clone https://power.lua-mu.org/wurtzite/img-genner
```

After that, you should be able to run the quicklisp command to load the library.

```lisp
(ql:quickload :img-genner)
```

## Working with images

img-genner is meant to work with rgb images with a color depth of 8 bits. If you
want to make a new one, you use a common lisp native function

```lisp
(defvar *image* (make-array (<height> <width> 3) :element-type '(unsigned-byte 8)))
```

That's not ergonomic enough, even for us.

Let's try a wrapper(we wrote it just now because writing this documentation made
us realize how unfun that is).

```lisp
(defvar *image* (img-genner:make-image <width> <height> #(255 255 255)))
```

Perfect, we have a nice little image.

Let's draw a line.

```lisp
(img-genner:stroke-line 0 0 30 30 *image* 
                        (img-genner:static-color-stroker #(255 255 255)))
```

The `static-color-stroker` is the most basic 'stroker' option, it returns a
closure that sets each pixel it is called on according to the position and
fraction of the line stroked(for other drawing routines such as filling shapes
it is not used). The static color stroker does not use the fraction input, but
the `gradient-color-stroker` does.

The other stroker that is available is the `radial-gradient-stroker`, which
takes two colors to interpolate, a center position, and a radius over which it
fades from the first to the second, and an optional distance function, in case
you want, for instance, some Manhattan distance instead.
