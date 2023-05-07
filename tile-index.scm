; -------------------------------------------------
; Dec -> hex conversion
; https://stackoverflow.com/a/58659355

; For all the operations below, this is the order of respectable digits:
(define conversion-digits (list
  "0" "1" "2" "3" "4" "5" "6" "7" "8" "9"
  "a" "b" "c" "d" "e" "f" "g" "h" "i" "j" "k"
  "l" "m" "n" "o" "p" "q" "r" "s" "t" "u" "v"
  "w" "x" "y" "z"))

; Converts a decimal number to another base. The returned number is a string
(define (convert-decimal-to-base num base)
  (if (< num base)
    (list-ref conversion-digits num) 
    (let loop ((val num)
               (order (inexact->exact (truncate (/ (log num)
                                                   (log base)))))
               (result ""))
      (let* ((power (expt base order))
             (digit (quotient val power)))
        (if (zero? order)
          (string-append result (list-ref conversion-digits digit))
          (loop (- val (* digit power))
                (pred order)
                (string-append result (list-ref conversion-digits digit))))))))

; -------------------------------------------------

; floor division
; copied from random-tiling
(define (// a b) (inexact->exact (floor (/ a b))))

(define (script-fu-tile-index inImage)
	(or
		(if (= (car (gimp-selection-is-empty inImage)) TRUE) (gimp-message "Selection is empty") #f)
		(let*
			(
				(sel (cdr (gimp-selection-bounds inImage))) ; original selection as list
				(selX    (car    sel)      ) ; original selection as individual coords
				(selY    (cadr   sel)      )
				(selW (- (caddr  sel) selX))
				(selH (- (cadddr sel) selY))
				(posX (// selX selW))
				(posY (// selY selH))
				(stride (// (car (gimp-image-width inImage)) selW))
				(posN (+ (* posY stride) posX))
			)
			
			(gimp-message (string-append
				"0x" (convert-decimal-to-base posN 16) "\n" (number->string posX) "," (number->string posY)
			))
		)
	)
)

(script-fu-register
	"script-fu-tile-index"
	"Selection to tile index"
	"Find the tile index and x,y position of the selection, assuming it covers exactly one tile"
	"Wist"
	""
	"2023-04-27 12:33:07"
	""
	SF-IMAGE    "Image"    0
)
