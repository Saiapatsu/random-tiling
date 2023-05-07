; Wist 2018-06-28
; Version 3 2018-07-03
; Now runs faster

(define (script-fu-flair-rotmg-sprite image scale zoom tilewidth tileheight hspacing vspacing padding shadowcolor outlinecolor merge autocrop safety)
	; work on copy if requested
	; broken
	;(if (= work-on-copy 1) (set! image (car (gimp-image-duplicate image))))

	(if
		(and
			(= safety 0)
			(> (+ (/ (car (gimp-image-width image)) tilewidth) (/ (car (gimp-image-height image)) tileheight)) 50)
		)
		(gimp-message "Image is too large, you have been prevented from doing this for your own safety.
Zoom out as far as possible and disable the safety to continue.")
		(begin (gimp-image-undo-group-start image)
		(let*
			(
				; add spacing between layers
				(layer (script-fu-respace-expand image tilewidth tileheight hspacing vspacing 0))
				(scale scale)
				(width (* (car (gimp-image-width image)) scale))
				(height (* (car (gimp-image-height image)) scale))
				(shadow-layer 0)
			)
			
			; scale layer and image, adding padding to accommodate the shadow
			(gimp-image-scale-full image width height 0)
			(set! width (+ width padding padding))
			(set! height (+ height padding padding))
			(gimp-image-resize image
				width
				height
				padding
				padding
			)
			(gimp-layer-resize-to-image-size layer)

			; add shadow layer below main layer
			(set! shadow-layer (car (gimp-layer-new image
				width
				height
				(car (gimp-drawable-type-with-alpha layer)) ; type
				"Shadow and outline"
				100
				NORMAL-MODE))
			)
			(gimp-image-add-layer image shadow-layer -1) ; add layer to image
			(gimp-drawable-fill shadow-layer TRANSPARENT-FILL) ; fill layer with transparent
			(gimp-image-lower-layer image shadow-layer)

			(gimp-context-push)

			; alpha to selection
			(gimp-selection-layer-alpha layer)
			; grow by 1 px
			(gimp-selection-grow image 1)
			; fill 81% on lower layer
			(gimp-context-set-background outlinecolor)
			(gimp-edit-bucket-fill shadow-layer BG-BUCKET-FILL NORMAL-MODE 81 0 0 0 0)
			; apply zoom
			(gimp-image-scale-full image
				(* width zoom)
				(* height zoom)
				0
			)
			(set! scale (* scale zoom))
			; alpha to selection
			(gimp-selection-layer-alpha layer)
			; grow 3*zoom pixels (float)
			(gimp-selection-grow image (* zoom 3))
			; feather 6*zoom pixels
			(gimp-selection-feather image (* zoom 6))
			; fill 27% on lower layer
			(gimp-context-set-background shadowcolor)
			(gimp-edit-bucket-fill shadow-layer BG-BUCKET-FILL NORMAL-MODE 27 0 0 0 0)
			; autocrop to lower layer
			(if (= autocrop 1) (plug-in-autocrop 0 image shadow-layer))

			(gimp-selection-none image)

			(if (= merge 1) (begin
				(gimp-context-set-background '(69 69 69))
				;(set! layer (car (gimp-image-flatten image)))
				(gimp-image-flatten image) ; layer is no longer used
			))

			;(gimp-layer-set-lock-alpha shadow-layer FALSE)

			(gimp-image-clean-all image)
			(gimp-displays-flush)
			(gimp-context-pop)
		)

		(gimp-image-undo-group-end image))
	)
)

(script-fu-register "script-fu-flair-rotmg-sprite"
	"<Image>/Filters/Artistic/_Flair RotMG Sprite"
	"Chop up and add drop shadow and outline to sprite sheets"
	"Wist"
	""
	"2018-06-29"
	""
	SF-IMAGE      "Image"                0
	SF-ADJUSTMENT "Scale"                '(5 1 16 1 2 0 0)
	SF-ADJUSTMENT "Zoom"                 '(1 1 8 1 2 0 0)
	SF-ADJUSTMENT "Tile width"           '(8 2 64 8 8 0 0)
	SF-ADJUSTMENT "Tile height"          '(8 2 64 8 8 0 0)
	SF-ADJUSTMENT "Horizontal spacing"   '(2 0 256 1 1 0 0)
	SF-ADJUSTMENT "Vertical spacing"     '(2 0 256 1 1 0 0)
	SF-ADJUSTMENT "Padding"              '(8 0 4096 1 1 0 0)
	SF-COLOR      "Shadow color"         '(0 0 0)
	SF-COLOR      "Outline color"        '(0 0 0)
	SF-TOGGLE     "Merge layers to grey" TRUE
	SF-TOGGLE     "Crop empty space"     TRUE
	SF-TOGGLE     "Work on large images" FALSE
)
