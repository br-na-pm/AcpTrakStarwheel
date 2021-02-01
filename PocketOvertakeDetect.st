
(* Returns the pocket index of pocket that has crossed a point input to the function *)
FUNCTION PocketOvertakeDetect
    
    StarInternal ACCESS Handle;
    
    FOR i := 0 TO StarInternal.MaxTargetIndex DO
        IF StarInternal.PocketSync[Internal.i].TargetPosition >= Position AND
            StarInternal.LastTargetPosition[Internal.i] < Position AND 
            StarInternal.PocketSync[Internal.i].Active AND
            NOT StarInternal.PocketSync[Internal.i].Sync THEN
    			
            PocketOvertakeDetect := i;
            RETURN
        END_IF
    END_FOR
    
    PocketOvertakeDetect    := slNO_POCKET_DETECTED;
    
END_FUNCTION
