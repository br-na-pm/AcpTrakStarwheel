
(* Finds the closest pocket to a shuttle that is in the sync zone *)
FUNCTION FindClosestPocketSyncZone
    
    StarInternal ACCESS Handle;
    
    IF StarInternal.MaxTargetIndex > 0 THEN
        FOR i := 0 TO StarInternal.MaxTargetIndex DO
            //ShuttleErrorNew := StarInternal.PocketSync[i].TargetPosition - Data.Init.ShuttlePos[Data.Init.ShuttleEvalCount];
            IF i = 0 THEN
                ShuttleError := ShuttleErrorNew;
            END_IF;
            //Ignore any pockets that are before the sync zone
//            IF StarInternal.PocketSync[i].TargetPosition >= Parameters.ProcessPointStartPosition + Parameters.StartOffset THEN
//                ClosestPocketIndexValid := TRUE;
//                IF ABS(ShuttleErrorNew) < ABS(ShuttleError) THEN
//                    NextClosestPocketIndex   := ClosestPocketIndex;
//                    ClosestPocketIndex := i;
//                    ShuttleError := ShuttleErrorNew;
//                END_IF
//            END_IF;
        END_FOR
    END_IF
    
END_FUNCTION
