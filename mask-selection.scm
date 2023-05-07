(define (mask-selection inImage inLayer inMask)
	; If selection is blank, add white selection instead of the
	; black one ADD-MASK-SELECTION adds by default
	; 0 = ADD-MASK-WHITE
	; 4 = ADD-MASK-SELECTION
	(if (not (= inMask -1)) (gimp-layer-remove-mask inLayer 1)) ; MASK-DISCARD
	(gimp-layer-add-mask
		inLayer
		(car (gimp-layer-create-mask
			inLayer
			(if (= 1 (car (gimp-selection-is-empty inImage))) 0 4))))
	
	; Mask gets selected by default, select the layer again
	(gimp-layer-set-edit-mask inLayer FALSE)
	(gimp-displays-flush)
)

(define (toggle-edit-mask inImage inLayer inMask)
	; If mask is missing, create one from selection
	(if (= inMask -1) (mask-selection inImage inLayer inMask))
	; Toggle mask edit state. GIMP procedures take ints, not bools
	(gimp-layer-set-edit-mask inLayer (- 1 (car (gimp-layer-get-edit-mask inLayer))))
	(gimp-displays-flush)
)

; Figure out whether inLayer is actually a layer mask and call fn
; with image, layer, layermask (if present)
(define (layer-or-mask fn inImage inLayer)
	(if (= 1 (car (gimp-item-is-layer-mask inLayer)))
		; If selected layer is actually a layer mask, operate on its layer instead
		(fn inImage (car (gimp-layer-from-mask inLayer)) inLayer)
		; Otherwise operate on the selected layer
		(fn inImage inLayer (car (gimp-layer-get-mask inLayer))))
)

(define (script-fu-mask-selection inImage inLayer)
	(layer-or-mask mask-selection inImage inLayer))
(define (script-fu-toggle-edit-mask inImage inLayer)
	(layer-or-mask toggle-edit-mask inImage inLayer))

(script-fu-register
	"script-fu-mask-selection"
	"Mask Selected Areas Ex"
	""
	"Wist"
	""
	"2023-04-29 12:43:25"
	""
	SF-IMAGE    "Image"    0
	SF-DRAWABLE "Drawable" 0
)

(script-fu-register
	"script-fu-toggle-edit-mask"
	"Edit Layer Mask Ex"
	""
	"Wist"
	""
	"2023-05-07 15:22:51"
	""
	SF-IMAGE    "Image"    0
	SF-DRAWABLE "Drawable" 0
)

(script-fu-menu-register "script-fu-mask-selection"
	"<Image>")
