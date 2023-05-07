
; !  n chop horizontal strip from current layer
; ! +n splice horizontal strip into current layer
; !  m chop vertical strip from current layer
; ! +m splice vertical strip into current layer

; layer, copy, lw, lh: layer itself, a copy of it, its width and height
; pos: position in layer space (not canvas space)
; clip: size of strip to chop/splice
(define (split-x layer copy lw lh pos clip)
	(gimp-layer-resize layer pos lh 0 0)
	(if (< clip 0)
		; Negative: remove strip
		(gimp-layer-resize copy (+ (- lw pos) clip) lh (- clip pos) 0)
		; Positive: add strip of empty space (don't cut anything extra)
		(gimp-layer-resize copy (- lw pos) lh (- pos) 0))
	(gimp-item-transform-translate copy clip 0)
	copy)

(define (split-y layer copy lw lh pos clip)
	(gimp-layer-resize layer lw pos 0 0)
	(if (< clip 0)
		; Negative: remove strip
		(gimp-layer-resize copy lw (+ (- lh pos) clip) 0 (- clip pos))
		; Positive: add strip of empty space
		(gimp-layer-resize copy lw (- lh pos) 0 (- pos)))
	(gimp-item-transform-translate copy 0 clip)
	copy)

(define (copy-layer image layer)
	(let ((copy (car (gimp-layer-copy layer 0))))
		(gimp-image-insert-layer image copy 0 (car (gimp-image-get-item-position image layer)))
		copy))

; Todo factor this thing the hell out now that there's copy-layer)
(define (with-cwh image layer fn pos clip)
	(fn
		layer
		(copy-layer image layer)
		(car (gimp-drawable-width layer))
		(car (gimp-drawable-height layer))
		pos clip))

(define (trim-x layer lw lh clip)
	(if (> clip 0) ; Positive: remove from near end (not far end)
		(gimp-layer-resize layer (- lw clip) lh (- clip) 0)
		(gimp-layer-resize layer (+ lw clip) lh 0 0))
	-1) ; No new layer created

; selection xy canvas-space, layer whxy -> selection xy layer-space, layer xy
(define (owhxy->xywh fn scx scy lw lh lx ly)
	(fn (- scx lx) (- scy ly) lw lh lx ly))

(define (chop-vertical image layer scx scy sw sh)
	(apply owhxy->xywh (append
		; how inconvenient that this loose stuff needs to be put in a list for append
		(list (lambda (slx sly lw lh lx ly)
			(if (> slx 0)
				(if (< slx (- lw sw))
					; Selection is entirely in the layer's bounds - split it and return new layer
					(with-cwh image layer split-x slx (- sw))
					; On far end or overshooting
					(if (< slx lw)
						; Cut off a little from the far end
						(trim-x layer lw lh (- slx lw))
						; Selection does not touch layer, do nothing
						-1))
				; On near end or behind
				(if (> sw (- slx))
					; Cut off a little from the near end
					(trim-x layer lw lh (+ sw slx))
					; Selection does not touch layer, do nothing
					-1))) scx scy)
		; how convenient that append unwraps these
		(gimp-drawable-width layer)
		(gimp-drawable-height layer)
		; vvv all this trouble just to unpack these offsets
		(gimp-drawable-offsets layer))))

(define (splice-vertical image layer x y w h)
	(with-cwh image layer split-x x w))

(define (chop-horizontal image layer x y w h)
	(with-cwh image layer split-y y (- h)))

(define (splice-horizontal image layer x y w h)
	(with-cwh image layer split-y y h))

(define (xyxy->xywh x1 y1 x2 y2)
	(list x1 y1 (- x2 x1) (- y2 y1)))

; (with-selection image fn <args>) -> (fn <args> x y w h)
(define (with-selection image fn . args)
	(let ((sel (gimp-selection-bounds image))) ; non-empty x1 y1 x2 y2
		(if (= 0 (car sel))
			(gimp-message "Selection is empty")
			(apply fn (append args (apply xyxy->xywh (cdr sel)))))))

; Merge down if layer exists, otherwise do nothing
(define (merge? image layer mode)
	(if (= layer -1)
		0
		(gimp-image-merge-down image layer mode)))

; Call function inside an undo group and merge down the created layer
(define (stitch image fn . args)
	(gimp-image-undo-group-start image)
	(merge? image (apply fn args) 0) ; 0 EXPAND-AS-NECESSARY
	(gimp-image-undo-group-end image)
	(gimp-displays-flush))

(define (script-fu-chop-vertical image layer)
	(with-selection image stitch image chop-vertical image layer))

(define (script-fu-splice-vertical image layer)
	(with-selection image stitch image splice-vertical image layer))

(define (script-fu-chop-horizontal image layer)
	(with-selection image stitch image chop-horizontal image layer))

(define (script-fu-splice-horizontal image layer)
	(with-selection image stitch image splice-horizontal image layer))

(define (register name desc)
	(script-fu-register
		name
		desc
		""
		"Wist"
		""
		"2023-05-07"
		""
		SF-IMAGE    "Image"    0
		SF-DRAWABLE "Drawable" 0))

(register "script-fu-chop-vertical" "Chop vertical strip")
(register "script-fu-splice-vertical" "Splice vertical strip")
(register "script-fu-chop-horizontal" "Chop horizontal strip")
(register "script-fu-splice-horizontal" "Splice horizontal strip")
