; 2018-06-30 08:17:19

(define (script-fu-respace-expand inImage tileWidth tileHeight hSpacing vSpacing margin )
	(gimp-context-push)
	(gimp-image-undo-group-start inImage)

	(let* (
			(inLayer (car (gimp-image-merge-visible-layers inImage CLIP-TO-IMAGE)))
			(theWidth (car (gimp-image-width inImage)))
			(theHeight (car (gimp-image-height inImage)))
			(theFloat 0))

		(gimp-layer-resize inLayer
			; add margins on both sides, then a spacing for all but one tilesizes that fit in the layer
			; todo: fix case when dimension doesn't divide with tilesize
			(+ theWidth margin margin (* hSpacing (- (/ theWidth tileWidth) 1)))
			(+ theHeight margin margin (* vSpacing (- (/ theHeight tileHeight) 1)))
			margin
			margin)

		(gimp-image-resize-to-layers inImage)

		(letrec (
			(loopTiles 
				(lambda (theDim theMin theMax)
					(cond 
						((<= theMax 0) #t)
						((begin 
							(gimp-rect-select inImage theMin margin theMax theDim CHANNEL-OP-REPLACE 0 0)
							(set! theFloat (car (gimp-selection-float inLayer hSpacing 0)))
							(set! inLayer (car (gimp-image-merge-down inImage theFloat CLIP-TO-BOTTOM-LAYER)))
							(loopTiles theDim (+ theMin tileWidth hSpacing) (- theMax tileWidth))         
						))
					)
				)
			)
		) (loopTiles theHeight (+ margin tileWidth) (- theWidth tileWidth)))

		(letrec (
			(loopTiles 
				(lambda (theDim theMin theMax)
					(cond 
						((<= theMax 0) #t)
						((begin 
							(gimp-rect-select inImage margin theMin theDim theMax CHANNEL-OP-REPLACE 0 0)
							(set! theFloat (car (gimp-selection-float inLayer 0 vSpacing)))
							(set! inLayer (car (gimp-image-merge-down inImage theFloat CLIP-TO-BOTTOM-LAYER)))
							(loopTiles theDim (+ theMin tileHeight vSpacing) (- theMax tileHeight))         
						))
					)
				)
			)
		) (loopTiles (+ theWidth (* hSpacing (- (/ theWidth tileWidth) 1))) (+ margin tileHeight) (- theHeight tileHeight)))

		(gimp-image-undo-group-end inImage)
		(gimp-context-pop)
		(gimp-displays-flush)
		inLayer
	)
)

(script-fu-register "script-fu-respace-expand"
	_"Expand tileset"
	_"Add spacing and margin to existing tileset which has zero margin and spacing."
	"Wist"
	"LGPL"
	"2018-07-03"
	""
	SF-IMAGE    "Image"    0
	SF-ADJUSTMENT "Tile width"   '(8 2 1600 1 8 0 0)
	SF-ADJUSTMENT "Tile height"   '(8 2 1600 1 8 0 0)
	SF-ADJUSTMENT "New horizontal spacing"   '(2 0 256 1 1 0 0)
	SF-ADJUSTMENT "New vertical spacing"   '(2 0 256 1 1 0 0)
	SF-ADJUSTMENT "New margin"   '(1 0 256 1 1 0 0)
)

;(script-fu-menu-register "script-fu-respace-expand"
;	;"<Image>/Filters/Map/TileSet")
;	"<Image>")
