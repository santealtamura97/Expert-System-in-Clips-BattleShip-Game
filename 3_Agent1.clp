;  ---------------------------------------------
;  --- Definizione del modulo e dei template ---
;  ---------------------------------------------
(defmodule AGENT (import MAIN ?ALL) (import ENV ?ALL))

;---Template utilizzato per memorizzare l'ultima posizione verificata dai meccanismi di left-to-right right-to-left top-to-bot e bot-to-top
(deftemplate last-position
	(slot x)
	(slot y)
)

(deftemplate computed-cell
	(slot x)
	(slot y)
	(slot prob)
)


;---Rappresenta una cella già analizzata (cambiare nome in cell-analyzed)
(deftemplate cell-discovered
	(slot x)
	(slot y)
)

;---Rappresenta una cella-boat per la quale è stato già analizzato l'intorno di acqua
(deftemplate cell-around-water
	(slot x)
	(slot y)
)


;---Rappresenta il numero di celle water per una determinata riga
(deftemplate k-water-per-row
	(slot row)
	(slot num)
)

;---Rappresenta il numero di celle water per una determinata colonna
(deftemplate k-water-per-col
	(slot col)
	(slot num)
)


;---Rappresenta una cella di acqua
(deftemplate water
	(slot x)
	(slot y)
)

;---Rappresenta una cella water già contata per una riga o colonna
(deftemplate counted-water-cell
	(slot x)
	(slot y)
)

;---Rappresenta una fase
(deftemplate phase
	(slot phase (allowed-values left-to-right right-to-left bot-to-top top-to-bot hor-guesses-middle
	 ver-guesses-middle execute-hor-guesses execute-ver-guesses set-guesses))
	(slot x)
	(slot y)
	(multislot row)
	(multislot col)
)

(deftemplate counted-discovered-cell
	(slot x)
	(slot y)
)

(deftemplate guess-on-middle
	(slot x)
	(slot y)
)

(deftemplate guessed-hor-ver
	(slot x)
	(slot y)
)


(defrule modify-k-per-row-col
	(k-cell (x ?x) (y ?y) (content ?con &~water))
	(not (counted-discovered-cell (x ?x) (y ?y)))
	?r <- (k-per-row (row ?x) (num ?numr))
	?c <- (k-per-col (col ?y) (num ?numc))
=>
	(bind ?newnumr (- ?numr 1))
	(bind ?newnumc (- ?numc 1))
	(modify ?r (row ?x) (num ?newnumr))
	(modify ?c (col ?y) (num ?newnumc))
	(assert (counted-discovered-cell (x ?x) (y ?y)))
)



; --- Asserisce vero l'intorno di acqua di un pezzo di nave noto che sia stato già analizzato---
(defrule set-around-water (declare (salience 5))
	(not (phase (phase ?phase)))
	(k-cell (x ?x) (y ?y) (content ?c))
	(cell-discovered (x ?x) (y ?y))
	(not (cell-around-water (x ?x) (y ?y)))
	(not (k-cell (x ?x) (y ?y) (content water)))
=>
	(bind ?row_up (- ?x 1))
	(bind ?row_down (+ ?x 1))
	(bind ?column_left (- ?y 1))
	(bind ?column_right (+ ?y 1))
	(assert (water (x ?x) (y ?column_left)))
	(assert (water (x ?x) (y ?column_right)))
	(assert (water (x ?row_up) (y ?y)))
	(assert (water (x ?row_down) (y ?y)))
	(assert (water (x ?row_down) (y ?column_left)))
	(assert (water (x ?row_down) (y ?column_right)))
	(assert (water (x ?row_up) (y ?column_left)))
	(assert (water (x ?row_up) (y ?column_right)))
	(assert (cell-around-water (x ?x) (y ?y)))		
)

(defrule set-water-intersection-row
	(k-per-row (row ?row) (num 0))
	(k-per-col (col ?col) (num ?num))
	(not (k-cell (x ?row) (y ?col) (content ?c)))
=>
	(assert(water (x ?row) (y ?col)))
)

(defrule unset-computed-fired-cell
	(exec (step ?st) (action fire) (x ?x) (y ?y))
	?c <- (computed-cell (x ?x) (y ?y))
=>
	(retract ?c)
)


(defrule unset-computed-guessed-cell
	(exec (step ?st) (action guess) (x ?x) (y ?y))
	?c <- (computed-cell (x ?x) (y ?y))
=>
	(retract ?c)
)

(defrule set-water-intersection-col
	(k-per-col (col ?col) (num 0))
	(k-per-row (row ?row) (num ?num))
	(not (k-cell (x ?row) (y ?col) (content ?c)))
=>
	(assert (water (x ?row) (y ?col)))
)

(defrule unset-water-guessed-cell
	(status (step ?s)(currently running))
	(water (x ?x) (y ?y))
	(exec (step ?st) (action guess) (x ?x) (y ?y))
=>
	(assert (exec (step ?s) (action unguess) (x ?x) (y ?y)))
)

(defrule unset-water-computed-cell
	(water (x ?x) (y ?y))
	?c <- (computed-cell (x ?x) (y ?y))
=>
	(retract ?c)
)


(defrule unset-fired-guessed-cell
	(status (step ?s)(currently running))
	(exec (step ?st) (action fire) (x ?x) (y ?y))
	?g <- (exec (step ?sts) (action guess) (x ?x) (y ?y))
=>
	(assert (exec (step ?s) (action unguess) (x ?x) (y ?y)))
	(retract ?g)
	(pop-focus)
)

	
;---Elimina i fatti errati per quanto riguarda le posizioni dell'acqua
(defrule unset-around-water (declare (salience 10))
	?w <- (water (x ?x) (y ?y))
	(k-cell (x ?x) (y ?y) (content ?c))
=>
	(retract ?w)
)

(defrule counter-water-cell (declare (salience -5))
	(or (water (x ?x) (y ?y)) (k-cell (x ?x) (y ?y) (content water)))
	(not (counted-water-cell (x ?x) (y ?y)))
	(not (k-cell (x ?x) (y ?y) (content ~water)))
	?r <- (k-water-per-row (row ?x) (num ?n1))
	?c <- (k-water-per-col (col ?y) (num ?n2))
=>
	(modify ?r (row ?x) (num(+ ?n1 1)))
	(modify ?c (col ?y) (num(+ ?n2 1)))
	(assert (counted-water-cell (x ?x) (y ?y)))
)	

;--- Regola che fa scattare il meccanismo di left-to-right quando scopro una nuova left boat
(defrule discovered-left
	(k-cell (x ?x) (y ?y) (content left))
	(not (cell-discovered (x ?x) (y ?y)))
	(not (phase (phase ?p)))
=>
	(assert (phase (phase left-to-right)))
	(assert (cell-discovered (x ?x) (y ?y)))
	(assert (last-position (x ?x) (y ?y)))
)

(defrule discovered-sub
	(k-cell (x ?x) (y ?y) (content sub))
	(not (cell-discovered (x ?x) (y ?y)))
=>
	(assert (cell-discovered (x ?x) (y ?y)))
)


;---Regola che fa scattare il meccanismo di right-to-left quando scopro una nuova right boat
(defrule discovered-right
	(k-cell (x ?x) (y ?y) (content right))
	(not (cell-discovered (x ?x) (y ?y)))
	(not (phase (phase ?p)))
=>
	(assert (phase (phase right-to-left)))
	(assert (cell-discovered (x ?x) (y ?y)))
	(assert (last-position (x ?x) (y ?y)))
)


;---Regola che fa scattare il meccanismo di top-to-boat quando scopro una nuova top boat
(defrule discovered-top
	(moves (fires ~0) (guesses ?g))
	(k-cell (x ?x) (y ?y) (content top))
	(not (cell-discovered (x ?x) (y ?y)))
	(not (phase (phase ?p)))
=>
	(assert (phase (phase top-to-bot)))
	(assert (cell-discovered (x ?x) (y ?y)))
	(assert (last-position (x ?x) (y ?y)))
)

;---Regola che fa scattare il meccanismo di bot-to-top quando scopro una nuova bot boat
(defrule discovered-bot
	(k-cell (x ?x) (y ?y) (content bot))
	(not (cell-discovered (x ?x) (y ?y)))
	(not (phase (phase ?p)))
=>
	(assert (phase (phase bot-to-top)))
	(assert (cell-discovered (x ?x) (y ?y)))
	(assert (last-position (x ?x) (y ?y)))
)




;---Una serie di regole per eseguire una serie di fire sicuri partendo da una boat left nota---
(defrule start-left-to-right (declare (salience 5))
	(not (moves (fires 0) (guesses ?g)))
	(status (step ?s)(currently running))
	(phase (phase left-to-right))
	?lp <- (last-position (x ?x) (y ?y))
	(not (k-cell (x ?x) (y ?y) (content right)))
	(not (k-cell (x ?x) (y =(+ 1 ?y)) (content ?c)))
=>
	(bind ?column-right (+ ?y 1))
	(assert (exec (step ?s) (action fire) (x ?x) (y ?column-right)))
	(assert (cell-discovered (x ?x) (y ?column-right)))
	(modify ?lp (x ?x) (y ?column-right))
	(pop-focus)
)


(defrule left-to-right (declare (salience 5))
	(phase (phase left-to-right))
	?lp <- (last-position (x ?x) (y ?y))
	(not (k-cell (x ?x) (y ?y) (content right)))
	(k-cell (x ?x) (y =(+ 1 ?y)) (content ?c))
=>
	(bind ?column-right (+ ?y 1))
	(assert (cell-discovered (x ?x) (y ?column-right)))
	(modify ?lp (x ?x) (y ?column-right))
)


(defrule end-left-to-right (declare (salience 5))
	?lr <- (phase (phase left-to-right))
	?lp <- (last-position (x ?x) (y ?y))
	(or (k-cell (x ?x) (y ?y) (content right))
	(moves (fires 0) (guesses ?g))
	)
=>
	(retract ?lp)
	(retract ?lr)
)



;---Una serie di regole per eseguire una serie di fire sicuri partendo da una boat right nota---
(defrule start-right-to-left (declare (salience 5))
	(not (moves (fires 0) (guesses ?g)))
	(status (step ?s)(currently running))
	(phase (phase right-to-left))
	?lp <- (last-position (x ?x) (y ?y))
	(not (k-cell (x ?x) (y ?y) (content left)))
	(not (k-cell (x ?x) (y =(- ?y 1)) (content ?c)))
=>
	(bind ?column-left (- ?y 1))
	(assert (exec (step ?s) (action fire) (x ?x) (y ?column-left)))
	(assert (cell-discovered (x ?x) (y ?column-left)))
	(modify ?lp (x ?x) (y ?column-left))
	(pop-focus)
)


(defrule right-to-left (declare (salience 5))
	(phase (phase right-to-left))
	?lp <- (last-position (x ?x) (y ?y))
	(not (k-cell (x ?x) (y ?y) (content left)))
	(k-cell (x ?x) (y =(- ?y 1)) (content ?c))
=>
	(bind ?column-left (- ?y 1))
	(assert (cell-discovered (x ?x) (y ?column-left)))
	(modify ?lp (x ?x) (y ?column-left))
)


(defrule end-right-to-left (declare (salience 5))
	?rl <- 	(phase (phase right-to-left))
	?lp <- (last-position (x ?x) (y ?y))
	(or (k-cell (x ?x) (y ?y) (content left))
	(moves (fires 0) (guesses ?g))
	)
=>
	(retract ?lp)
	(retract ?rl)
)

;---Una serie di regole per eseguire una serie di fire sicuri partendo da una boat top nota---
(defrule start-top-to-bot (declare (salience 5))
	(not (moves (fires 0) (guesses ?g)))
	(status (step ?s)(currently running))
	(phase (phase top-to-bot))
	?lp <- (last-position (x ?x) (y ?y))
	(not (k-cell (x ?x) (y ?y) (content bot)))
	(not (k-cell (x =(+ 1 ?x)) (y ?y) (content ?c)))
=>
	(bind ?bot-row (+ ?x 1))
	(assert (exec (step ?s) (action fire) (x ?bot-row) (y ?y)))
	(assert (cell-discovered (x ?bot-row) (y ?y)))
	(modify ?lp (x ?bot-row) (y ?y))
	(pop-focus)
)


(defrule top-to-bot (declare (salience 5))
	(phase (phase top-to-bot))
	?lp <- (last-position (x ?x) (y ?y))
	(not (k-cell (x ?x) (y ?y) (content bot)))
	(k-cell (x =(+ 1 ?x)) (y ?y) (content ?c))
=>
	(bind ?bot-row (+ ?x 1))
	(assert (cell-discovered (x ?bot-row) (y ?y)))
	(modify ?lp (x ?bot-row) (y ?y))
)


(defrule end-top-to-bot (declare (salience 5))
	?tb <- (phase (phase top-to-bot))
	?lp <- (last-position (x ?x) (y ?y))
	(or (k-cell (x ?x) (y ?y) (content bot))
	(moves (fires 0) (guesses ?g))
	)
=>
	(retract ?lp)
	(retract ?tb)
)

;---Una serie di regole per eseguire una serie di fire sicuri partendo da una boat bot nota---
(defrule start-bot-to-top (declare (salience 5))
	(not (moves (fires 0) (guesses ?g)))
	(status (step ?s)(currently running))
	(phase (phase bot-to-top))
	?lp <- (last-position (x ?x) (y ?y))
	(not (k-cell (x ?x) (y ?y) (content top)))
	(not (k-cell (x =(- ?x 1)) (y ?y) (content ?c)))
=>
	(bind ?top-row (- ?x 1))
	(assert (exec (step ?s) (action fire) (x ?top-row) (y ?y)))
	(assert (cell-discovered (x ?top-row) (y ?y)))
	(modify ?lp (x ?top-row) (y ?y))
	(pop-focus)
)

(defrule bot-to-top (declare (salience 5))
	(phase (phase bot-to-top))
	?lp <- (last-position (x ?x) (y ?y))
	(not (k-cell (x ?x) (y ?y) (content top)))
	(k-cell (x =(- ?x 1)) (y ?y) (content ?c))
=>
	(bind ?top-row (- ?x 1))
	(assert (cell-discovered (x ?top-row) (y ?y)))
	(modify ?lp (x ?top-row) (y ?y))
)


(defrule end-bot-to-top (declare (salience 5))
	?bt <- (phase (phase bot-to-top))
	?lp <- (last-position (x ?x) (y ?y))
	(or (k-cell (x ?x) (y ?y) (content top))
	(moves (fires 0) (guesses ?g))
	)
=>
	(retract ?bt)
	(retract ?lp)
)

(defrule discovered-middle (declare (salience -10))
	(k-cell (x ?x) (y ?y) (content middle))
	(not (cell-discovered (x ?x) (y ?y)))
=>
	(assert (phase (phase hor-guesses-middle) (x ?x) (y ?y)))
	(assert (phase (phase ver-guesses-middle) (x ?x) (y ?y)))
)

(deftemplate guessed-cell
	(slot x)
	(slot y)
)

;--------------------------------------
;-----VERIFIES HOR-------------------
;--------------------------------------

(defrule fail-hor-guesses-middle (declare (salience -15))
	?p <- (phase (phase hor-guesses-middle) (x ?x) (y ?y))
	(or (k-cell (x ?x) (y =(+ 2 ?y)) (content top | bot | middle | left | right | sub))
	      (k-cell (x ?x) (y = (- ?y 2)) (content top | bot | middle | left | right | sub))
	      (k-cell (x = (- ?x 1)) (y = (+ 2 ?y)) (content top | bot | middle | left | right | sub))
	      (k-cell (x = (+ 1 ?x)) (y = (+ 2 ?y)) (content top | bot | middle | left | right | sub))
	      (k-cell (x = (- ?x 1)) (y = (- ?y 2)) (content top | bot | middle | left | right | sub))
	      (k-cell (x = (+ 1 ?x)) (y = (- ?y 2)) (content top | bot | middle | left | right | sub))
	      (k-per-col (col = (+ 1 ?y)) (num 0))
	      (k-per-col (col = (- ?y 1)) (num 0))
	      (test (eq ?y 0))
	      (test (eq ?y 9))
	      (k-per-row (row ?x) (num ?n &:(< ?n 2)))	   
	 )
=>
	(retract ?p)
)

(defrule hor-guesses-middle (declare (salience -20))
	(moves (fires ?f) (guesses ~0))
	?p <- (phase (phase hor-guesses-middle) (x ?x) (y ?y))
	(k-per-row (row ?x) (num ?num1))
	(or 
	(k-per-row (row ?y) (num ?num2&:(>= ?num1 ?num2)))
	(or (k-cell (x =(- ?x 2)) (y ?y) (content top | bot | middle | left | right | sub))
	      (k-cell (x =(+ 2 ?x)) (y ?y) (content top | bot | middle | left | right | sub))
	      (k-cell (x =(- ?x 2)) (y = (+ 1 ?y)) (content top | bot | middle | left | right | sub))
	      (k-cell (x =(- ?x 2)) (y = (- ?y 1)) (content top | bot | middle | left | right | sub))
	      (k-cell (x =(+ 2 ?x)) (y = (+ 1 ?y)) (content top | bot | middle | left | right | sub))
	      (k-cell (x =(+ 2 ?x)) (y = (- ?y 1)) (content top | bot | middle | left | right | sub))
	      (k-per-row (row = (+ 1 ?x)) (num 0))
	      (k-per-row (row = (- ?x 1)) (num 0))
	      (test (eq ?x 0))
	      (test (eq ?x 9))
	      (k-per-col (col ?y) (num ?n &:(< ?n 2)))
	 )
	)
=>
	(bind ?column-left (- ?y 1))
	(bind ?column-right (+ ?y 1))
	(assert (phase (phase execute-hor-guesses) (x ?x) (y ?y) (row ?x) (col ?column-left ?column-right)))
	(retract ?p)
)

(defrule execute-hor-guesses (declare (salience -20))
	(moves (fires ?f) (guesses ~0))
	(status (step ?s)(currently running))
	?ehg <- (phase (phase execute-hor-guesses) (x ?x) (y ?y) (row $?row) (col $?col))
	(not (test (eq (length$ $?col) 0)))
=>
	(bind ?r1 (nth$ 1 $?row))
	(bind ?c1 (nth$ 1 $?col))
	(assert (guessed-cell (x ?r1) (y ?c1)))
	(assert (exec (step ?s) (action guess) (x ?r1) (y ?c1)))
	(modify ?ehg (phase execute-hor-guesses) (x ?x) (y ?y) (col (delete-member$ $?col ?c1)))
	(pop-focus)
)

(defrule end-hor-guesses (declare (salience -20))
	?ehg <- (phase (phase execute-hor-guesses) (x ?x) (y ?y) (row $?row) (col $?col))
	(or (test (eq (length$ $?col) 0))
	      (moves (fires ?f) (guesses 0))
	)
=>
	(retract ?ehg)
)




;--------------------------------------
;-----VERIFIES VER-------------------
;--------------------------------------

(defrule fail-ver-guesses-middle (declare (salience -15))
	?p <- (phase (phase ver-guesses-middle) (x ?x) (y ?y))
	(or (k-cell (x =(+ 2 ?x)) (y ?y) (content top | bot | middle | left | right | sub))
	      (k-cell (x =(- ?x 2)) (y ?y) (content top | bot | middle | left | right | sub))
	      (k-cell (x =(- ?x 2)) (y = (+ 1 ?y)) (content top | bot | middle | left | right | sub))
	      (k-cell (x =(- ?x 2)) (y = (- ?y 1)) (content top | bot | middle | left | right | sub))
	      (k-cell (x =(+ 2 ?x)) (y = (+ 1 ?y)) (content top | bot | middle | left | right | sub))
	      (k-cell (x =(+ 2 ?x)) (y = (- ?y 1)) (content top | bot | middle | left | right | sub))
	      (k-per-row (row = (+ 1 ?x)) (num 0))
	      (k-per-row (row = (- ?x 1)) (num 0))
	      (test (eq ?x 0))
	      (test (eq ?x 9))
	      (k-per-col (col ?y) (num ?n &:(< ?n 2)))
	 )
	(k-per-row (row = (- ?x 1)) (num ?numero))
=>
	(printout t ?numero crlf)
	(retract ?p)
)

(defrule ver-guesses-middle (declare (salience -20))
	(moves (fires ?f) (guesses ~0))
	?p <- (phase (phase ver-guesses-middle) (x ?x) (y ?y))
	(k-per-col (col ?y) (num ?num1))
	(or 
	(k-per-row (row ?y) (num ?num2&:(>= ?num1 ?num2)))
	(or (k-cell (x ?x) (y =(+ 2 ?y)) (content top | bot | middle | left | right | sub))
	      (k-cell (x ?x) (y =(- ?y 2)) (content top | bot | middle | left | right | sub))
                 (k-cell (x = (- ?x 1)) (y = (+ 2 ?y)) (content top | bot | middle | left | right | sub))
	      (k-cell (x = (+ 1 ?x)) (y = (+ 2 ?y)) (content top | bot | middle | left | right | sub))
	      (k-cell (x = (- ?x 1)) (y = (- ?y 2)) (content top | bot | middle | left | right | sub))
	      (k-cell (x = (+ 1 ?x)) (y = (- ?y 2)) (content top | bot | middle | left | right | sub))
	      (k-per-col (col = (+ 1 ?y)) (num 0))
	      (k-per-col (col = (- ?y 1)) (num 0))
	      (test (eq ?y 0))
	      (test (eq ?y 9))
	      (k-per-row (row ?x) (num ?n &:(< ?n 2)))	
	 )
	)
=>
	(bind ?row-top (- ?x 1))
	(bind ?row-bot (+ ?x 1))
	(assert (phase (phase execute-ver-guesses) (x ?x) (y ?y) (row ?row-top ?row-bot) (col ?y ?y)))
	(retract ?p)
)

(defrule execute-ver-guesses (declare (salience -20))
	(moves (fires ?f) (guesses ~0))
	(status (step ?s)(currently running))
	?ehg <- (phase (phase execute-ver-guesses) (x ?x) (y ?y) (row $?row) (col $?col))
	(not (test (eq (length$ $?row) 0)))
=>
	(bind ?r1 (nth$ 1 $?row))
	(bind ?c1 (nth$ 1 $?col))
	(assert (guessed-cell (x ?r1) (y ?c1)))
	(assert (exec (step ?s) (action guess) (x ?r1) (y ?c1)))
	(modify ?ehg (phase execute-ver-guesses) (x ?x) (y ?y) (row (delete-member$ $?row ?r1)))
	(pop-focus)
)

(defrule end-ver-guesses (declare (salience -20))
	?ehg <- (phase (phase execute-ver-guesses) (x ?x) (y ?y) (row $?row) (col $?col))
           (or (test (eq (length$ $?row) 0))
		(moves (fires ?f) (guesses 0))
	)
=>
	(retract ?ehg)
)



(deftemplate avg
	(slot result)
)


(defrule compute-cell (declare (salience -30))
	(k-per-row (row ?x) (num ?numr))
	(k-per-col (col ?y) (num ?numc))
	(not (k-cell (x ?x) (y ?y) (content ?c)))
	(not (water (x ?x) (y ?y)))
	(not (exec (step ?st) (action guess) (x ?x) (y ?y)))
	(k-water-per-row (row ?x) (num ?numrw))
	(k-water-per-col (col ?y) (num ?numcw))
	(test (< 0 ?numr))
	(test (< 0 ?numc))
	
=>
	(bind ?difference_row (- 10 ?numrw))
	(bind ?difference_col (- 10 ?numcw))
	(bind ?prob (* (/ ?numr ?difference_row) (/ ?numc ?difference_col)))
	(assert (computed-cell (x ?x) (y ?y) (prob ?prob)))
)

(defrule unset-computed-cell (declare (salience -30))
	?c1 <- (computed-cell (x ?x) (y ?y) (prob ?prob))
	?c2 <- (computed-cell (x ?x1) (y ?y1) (prob ?prob1))
	(test (eq ?x ?x1))
	(test (eq ?y ?y1))
	(not (test (eq ?prob ?prob1)))
=>
	(bind ?max (max ?prob ?prob1))
	(retract ?c1)
	(retract ?c2)
	(assert (computed-cell (x ?x) (y ?y) (prob ?max)))
)



(defrule fire (declare (salience -50))
	(status (step ?s)(currently running))
	(not (moves (fires 0) (guesses ?g)))
	?c <- (computed-cell (x ?x1) (y ?y1) (prob ?prob1))
	(not (computed-cell (prob ?prob2&:(> ?prob2 ?prob1))))
	(not (water (x ?x1) (y ?y1)))
=>
	(retract ?c)
	(assert (exec (step ?s) (action fire) (x ?x1) (y ?y1)))
	(printout t "Fire su " ?x1 " " ?y1 " " ?prob1 crlf)
	(pop-focus)
)

(deffunction average (?template ?slot)
	(bind ?sum 0)
	(bind ?count 0)
	(do-for-all-facts ((?f ?template)) TRUE
	      (bind ?sum (+ ?sum (fact-slot-value ?f ?slot)))
     	      (bind ?count (+ ?count 1)))
   	(if (= ?count 0)
      	  	then FALSE
     		else (/ ?sum ?count)))


(defrule assert-average (declare (salience -55))
	(not (avg (result ?r)))
=>
	(assert (avg (result (average computed-cell prob))))
)
	

(defrule guess (declare (salience -60))
	(status (step ?s)(currently running))
	(moves (fires 0) (guesses ~0))
	(avg (result ?avg))
	?c <- (computed-cell (x ?x1) (y ?y1) (prob ?prob1))
	(test (< ?avg ?prob1))
	(not (computed-cell (prob ?prob2&:(> ?prob2 ?prob1))))
	(not (k-per-row (row ?x1) (num 0)))
	(not (k-per-col (col ?y1) (num 0)))
	(not (water (x ?x1) (y ?y1)))
=>
	(retract ?c)
	(assert (exec (step ?s) (action guess) (x ?x1) (y ?y1)))
	(pop-focus)
)

(defrule save-results (declare (salience -70))
	(status (step ?s) (currently running))
=>
	(save-facts results.txt visible exec k-per-row k-per-col)
	(printout t "SAVED!" crlf)
)


(defrule solve (declare (salience -70))
	(status (step ?s)(currently running))
=>
	(assert (exec (step ?s) (action solve)))
	(pop-focus)
)

	
	


(deffacts initial-facts
	(k-water-per-row (row 0) (num 0))
	(k-water-per-row (row 1) (num 0))
	(k-water-per-row (row 2) (num 0))
	(k-water-per-row (row 3) (num 0))
	(k-water-per-row (row 4) (num 0))
	(k-water-per-row (row 5) (num 0))
	(k-water-per-row (row 6) (num 0))
	(k-water-per-row (row 7) (num 0))
	(k-water-per-row (row 8) (num 0))
	(k-water-per-row (row 9) (num 0))

	(k-water-per-col (col 0) (num 0))
	(k-water-per-col (col 1) (num 0))
	(k-water-per-col (col 2) (num 0))
	(k-water-per-col (col 3) (num 0))
	(k-water-per-col (col 4) (num 0))
	(k-water-per-col (col 5) (num 0))
	(k-water-per-col (col 6) (num 0))
	(k-water-per-col (col 7) (num 0))
	(k-water-per-col (col 8) (num 0))
	(k-water-per-col (col 9) (num 0))

)