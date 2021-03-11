
(* Finds the closest pocket to the start of the mesh zone of the starwheel that a shuttle can sync to *)
FUNCTION ClosestSyncPocket
    
    StarInternal ACCESS Handle;
    
    FOR i := 0 TO StarInternal.MaxTargetIndex DO
        
        FirstSyncPocketLocationErrorNew := StarInternal.PocketSync[i].TargetPosition - StartPos;
        LastSyncPocketLocationErrorNew := StarInternal.PocketSync[i].TargetPosition - EndPos;
        IF i = 0 THEN
            FirstSyncPocketLocationError    := FirstSyncPocketLocationErrorNew;
            LastSyncPocketLocationError := LastSyncPocketLocationErrorNew;
        END_IF;
        
        IF ABS(FirstSyncPocketLocationErrorNew) < ABS(FirstSyncPocketLocationError) AND StarInternal.PocketSync[i].TargetPosition >= StartPos THEN
            FirstSyncPocketIndex := i;
            FirstSyncPocketLocationError := FirstSyncPocketLocationErrorNew;
        END_IF
        
        IF ABS(LastSyncPocketLocationErrorNew) < ABS(LastSyncPocketLocationError) AND (StarInternal.PocketSync[i].TargetPosition <= EndPos) THEN
            LastSyncPocketIndex := i;
            LastSyncPocketLocationError := LastSyncPocketLocationErrorNew;
        END_IF
        
    END_FOR
    
    CurrentEvalPocket   := FirstSyncPocketIndex;
    PrevEvalPocket      := FirstSyncPocketIndex;
    FOR i := 0 TO StarInternal.MaxTargetIndex DO
        IF StarInternal.PocketSync[CurrentEvalPocket].Sync THEN
            CurrentEvalPocket   := PrevEvalPocket;
            EXIT;
        ELSE 
            CurrentEvalPocketValid  := TRUE;
            ClosestSyncPocket   := CurrentEvalPocket;
        END_IF;
        
        PrevEvalPocket  := CurrentEvalPocket;
        IF CurrentEvalPocket = 0 THEN
            CurrentEvalPocket   := StarInternal.MaxTargetIndex;
        ELSE
            CurrentEvalPocket   := CurrentEvalPocket - 1;
        END_IF;
    END_FOR;
    
    IF NOT CurrentEvalPocketValid THEN
        ClosestSyncPocket   := slNO_CLOSEST_POCKET_FOUND;
    END_IF;
    
END_FUNCTION
