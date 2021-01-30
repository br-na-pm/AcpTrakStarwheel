
(* Finds the closest pocket to the start of the mesh zone of the starwheel that a shuttle can sync to *)
FUNCTION ClosestSyncPocket
    
    StarInternal ACCESS Handle;
    
    FOR i := 0 TO StarInternal.MaxTargetIndex DO
        TangentPocketLocationErrorNew := StarInternal.PocketSync[i].TargetPosition - MeshZoneStartPos;
        FirstSyncPocketLocationErrorNew := StarInternal.PocketSync[i].TargetPosition - SyncZoneStartPos;
        IF i = 0 THEN
            TangentPocketLocationError := TangentPocketLocationErrorNew;
            FirstSyncPocketLocationError    := FirstSyncPocketLocationErrorNew;
        END_IF;
        
        IF ABS(TangentPocketLocationErrorNew) < ABS(TangentPocketLocationError) AND (StarInternal.PocketSync[i].TargetPosition <= MeshZoneStartPos) THEN
            TangentPocketIndex := i;
            TangentPocketLocationError := TangentPocketLocationErrorNew;
        END_IF
        
        IF ABS(FirstSyncPocketLocationErrorNew) < ABS(FirstSyncPocketLocationError) AND StarInternal.PocketSync[i].TargetPosition >= SyncZoneStartPos THEN
            FirstSyncPocketIndex := i;
            FirstSyncPocketLocationError := FirstSyncPocketLocationErrorNew;
        END_IF
    END_FOR
    
    CurrentEvalPocket   := FirstSyncPocketIndex;
    PrevEvalPocket      := FirstSyncPocketIndex;
    FOR i := 0 TO StarInternal.MaxTargetIndex DO
        IF (CurrentEvalPocket = TangentPocketIndex) OR (StarInternal.PocketSync[CurrentEvalPocket].Sync) THEN
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
