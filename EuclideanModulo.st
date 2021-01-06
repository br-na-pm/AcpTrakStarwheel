
(* Implements Euclidean Modulo *)
FUNCTION EuclideanModuloINT
	IF Divisor <> 0 THEN
		EuclideanModuloINT	:= Dividend - ABS(Divisor) * REAL_TO_INT(brmfloor( INT_TO_REAL(Dividend) / ABS(INT_TO_REAL(Divisor)) ));
	ELSE
		EuclideanModuloINT		:= 0;
	END_IF;	
END_FUNCTION

(* Implements Euclidean Modulo *)
FUNCTION EuclideanModuloFLT	
	IF Divisor <> 0 THEN
		EuclideanModuloFLT	:= Dividend - ABS(Divisor) * brmfloor( Dividend / ABS(Divisor) );
	ELSE
		EuclideanModuloFLT		:= 0;
	END_IF;
END_FUNCTION

