; floor division
(define (// a b) (inexact->exact (floor (/ a b))))
; floor halve fixnum (i.e. arithmetic shift right once)
(define (/2 x) (/ (if (odd? x) (- x 1) x) 2))

; calculate random fixnum [0;65535) for world location x,y
(define (tileHash x y)
	(let (
			; load the image that has the precalculated hash. it will stay in memory until gimp shuts down
			(layer (vector-ref (cadr (gimp-image-get-layers (car (file-png-load RUN-NONINTERACTIVE (string-append gimp-directory "/scripts/images/hash512.png") "hash512.png")))) 0))
		)
		; replace this function with and immediately call the real tile hash function that uses the image above
		((set! tileHash (lambda (x y)
			; the image is formatted weirdly. each pixel is 32-bit rgba
			; the high 16 bits refer to x, the low 16 bits refer to x+1
			(let ((pixel (cadr (gimp-drawable-get-pixel layer (/2 x) y)))) ; vector of 4 bytes in rgba order
				(+     (vector-ref pixel (if (odd? x) 3 1))
				    (* (vector-ref pixel (if (odd? x) 2 0)) 256)
				)
			)
		)) x y)
	)
)

(define (script-fu-tile-randomly inImage inLayer)
	(or
		(if (= (car (gimp-selection-is-empty inImage)) TRUE) (gimp-message "Selection is empty") #f)
		
		(let*
			(
				(size 16)  ; output width and height in tiles
				(presScale 6.25) ; scale of presentation. 6.25 = 50/8, 50 is the size of one 8x8 tile
				(presAngle (* 2 (acos 0) (/ 15 180))) ; angle that the presentation is skewed to, in radians. 2*acos(0) is pi
				
				(sel  (cdr (gimp-selection-bounds inImage))) ; original selection as list
				(selX    (car    sel)      ) ; original selection as individual coords
				(selY    (cadr   sel)      )
				(selW (- (caddr  sel) selX))
				(selH (- (cadddr sel) selY))
				
				(selL (max selW selH)) ; long  edge of selection
				(selS (min selW selH)) ; short edge (i.e. edge length of tile)
				(selXD (if (> selW selH) selS 0))
				(selYD (if (> selW selH) 0 selS))
				(tileN (// selL selS)) ; amount of sprites in the selection
				
				(presSize (* size selS presScale))
				(presCanvas (/
					presSize
					(+
						(sin presAngle)
						(cos presAngle)
					)
				))
				
				(hashOffX (- (random (- 512 size)) 1))
				(hashOffY (- (random (- 512 size)) 1))
				
				(outImage (car (gimp-image-new size size RGB))) ; output image
				(noiseLayer (car (gimp-layer-new outImage size size RGB-IMAGE  "Noise" 100 NORMAL-MODE))) ; layer for random noise
				(outLayer   (car (gimp-layer-new outImage size size RGBA-IMAGE "Tiles" 100 NORMAL-MODE))) ; layer for output
				
				(bytes (make-vector 3 0)) ; don't remember, probably an array of 3 bytes (r, g, b)
			)
			
			(gimp-image-undo-freeze inImage) ; freezes undo stack
			(gimp-image-undo-disable outImage)
			
			(gimp-image-add-layer outImage noiseLayer 0) ; put the layers into the image
			(gimp-image-add-layer outImage outLayer  -1)
			
			; fill noiseLayer with noise in interval [0; tileN)
			(if (= tileN 1)
				#t ; don't bother if there's only one tile
				(let loop ((x 0)
						   (y 0))
					(if (>= y size)
						#t ; stop when y is outside the image (all pixels have been painted)
						(begin
							; create a rgb color ([0;tileN), 0, 0)
							; (vector-set! bytes 0 (- (random tileN) 1))
							(vector-set! bytes 0 (modulo (tileHash (+ x hashOffX) (+ y hashOffY)) tileN))
							; paint a pixel with it
							(gimp-drawable-set-pixel noiseLayer x y 3 bytes) ; paint a pixel in the image with the above color
							; go to the next pixel
							(if (< (+ x 1) size)
								(loop (+ x 1) y) ; go right
								(loop 0 (+ y 1)) ; go to the next row
							)
						)
					)
				)
			)
			
			; scale noiseLayer such that each pixel in it can fit a sprite
			(gimp-image-scale-full outImage (* size selS) (* size selS) INTERPOLATION-NONE)
			
			; replace each distinct color in noiseLayer with the corresponding tile from source image
			(gimp-context-set-pattern "Clipboard Image") ; best way of filling an area with a tiled pattern
			(let loop ((selX selX)
			           (selY selY)
			           (selL selL)
			           (index 0  ))
				(if (>= selL selS)
					(begin
						; set the selection
						(gimp-rect-select inImage selX selY selS selS CHANNEL-OP-REPLACE FALSE 0)
						
						; copy a tile from the source image
						(gimp-edit-copy inLayer)
						
						; select the areas to apply the tile to
						(gimp-by-color-select noiseLayer (list index 0 0) 0 CHANNEL-OP-REPLACE FALSE FALSE 0 FALSE)
						
						; fill part of output with the tile
						(gimp-edit-bucket-fill outLayer PATTERN-BUCKET-FILL NORMAL-MODE 100 0 FALSE 0 0)
						
						(loop (+ selX selXD) (+ selY selYD) (- selL selS) (+ index 1))
					)
				)
			)
			
			; restore the initial selection and clean up
			(gimp-rect-select inImage selX selY selW selH CHANNEL-OP-REPLACE FALSE 0)
			(gimp-image-undo-thaw inImage)
			; ---
			(gimp-selection-none outImage)
			(gimp-image-remove-layer outImage noiseLayer)
			(gimp-image-undo-enable outImage)
			
			; for presentation, scale and rotate. allow this operation to be undone to reveal the original grid
			(gimp-image-undo-group-start outImage)
			(gimp-image-scale-full outImage presSize presSize INTERPOLATION-NONE)
			(gimp-image-undo-group-end outImage)
			(gimp-image-undo-group-start outImage)
			(gimp-item-transform-rotate outLayer presAngle TRUE 0 0)
			(gimp-image-undo-group-end outImage)
			(gimp-image-undo-group-start outImage)
			(gimp-image-resize outImage presCanvas presCanvas (* 0.5 (- presCanvas presSize)) (* 0.5 (- presCanvas presSize)))
			(gimp-image-undo-group-end outImage)
			
			; display result
			(gimp-image-clean-all outImage)
			(gimp-display-new outImage)
			(gimp-displays-flush)
			
			; this procedure succeeded
			#t
		)
	)
)

(script-fu-register
	"script-fu-tile-randomly"
	"Tile randomly"
	"Create a random pattern with specified sprites"
	"Wist"
	""
	"2018-07-18"
	""
	SF-IMAGE    "Image"    0
	SF-DRAWABLE "Drawable" 0
)

(script-fu-menu-register "script-fu-tile-randomly"
	"<Image>")
