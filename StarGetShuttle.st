
FUNCTION_BLOCK slStarGetShuttle
            
    IF Enable THEN
        //Check for pointer validity
        IF Handle = 0 THEN
            Valid := 0;
            brsmemset(ADR(Axis), 0, SIZEOF(Axis));
            Position := 0.0;
            Error := 1;
            ErrorID := slERR_INVALID_HANDLE;
        ELSE
            StarInternal ACCESS Handle;
            IF StarInternal.TypeID <> slSTAR_INTERNAL_TYPE_ID THEN
                Valid := 0;
                brsmemset(ADR(Axis), 0, SIZEOF(Axis));
                Position := 0.0;
                Error := 1;
                ErrorID := slERR_INVALID_HANDLE;
            ELSIF StarInternal.MaxTargetIndex > slMAX_TARGET_IDX THEN
                Valid := 0;
                brsmemset(ADR(Axis), 0, SIZEOF(Axis));
                Position := 0.0;
                Error := 1;
                ErrorID := slERR_MAX_TARGET_IDX;
            ELSE
                Error := 0;
                ErrorID := ERR_OK;
                Internal.Present := 0;
                brsmemset(ADR(Internal.Axis), 0, SIZEOF(Internal.Axis));
                Internal.Position := 0.0;
                FOR Internal.i := 0 TO StarInternal.MaxTargetIndex DO
                    
                    IF StarInternal.PocketSync[Internal.i].TargetPosition - TrakPositionStart >= 0 AND
                       StarInternal.PocketSync[Internal.i].TargetPosition - TrakPositionEnd <= 0 THEN
                        
                        IF StarInternal.PocketSync[Internal.i].Sync THEN
                            Internal.Present := 1;
                            Internal.Axis := StarInternal.PocketSync[Internal.i].Axis;
                            Internal.Position := StarInternal.PocketSync[Internal.i].TargetPosition;
                            EXIT;
                        END_IF
                        
                    END_IF
                    
                END_FOR
                ShuttlePresent := Internal.Present;
                Axis := Internal.Axis;
                Position := Internal.Position;
                Valid := 1;
            END_IF
        END_IF
    ELSE
        Valid := 0;
        Error := 0;
        ErrorID := ERR_OK;
        brsmemset(ADR(Axis), 0, SIZEOF(Axis));
        Position := 0.0;
    END_IF
    
END_FUNCTION_BLOCK
