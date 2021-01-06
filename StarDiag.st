
FUNCTION_BLOCK slStarDiag

    CASE Internal.State OF
        
        slSTAR_DIAG_STATE_IDLE:
            
            IF Enable THEN
                Busy := 1;
                IF Handle = 0 THEN
                    Error := 1;
                    ErrorID := slERR_INVALID_HANDLE;
                    Internal.State := slSTAR_DIAG_STATE_ERROR;
                ELSE
                    Internal.Handle := Handle;
                    StarInternal ACCESS Internal.Handle;
                    IF StarInternal.TypeID <> slSTAR_INTERNAL_TYPE_ID THEN
                        Error := 1;
                        ErrorID := slERR_INVALID_HANDLE;
                        Internal.State := slSTAR_DIAG_STATE_ERROR;
                    ELSE
                        Internal.State := slSTAR_DIAG_STATE_RUNNING;
                    END_IF
                END_IF
            END_IF
        
        slSTAR_DIAG_STATE_RUNNING:
            
            IF Enable THEN
                StarInternal ACCESS Internal.Handle;
                FOR Internal.i := 0 TO slMAX_TARGET_IDX DO
                    Diag.AngleOffset[Internal.i] := StarInternal.PocketSync[Internal.i].Internal.StarCalcTarget.Internal.AngleOffset;
                    Diag.PocketAngle[Internal.i] := StarInternal.PocketSync[Internal.i].Internal.StarCalcTarget.Internal.PocketAngle;
                    Diag.TrackSyncRaw[Internal.i] := StarInternal.PocketSync[Internal.i].Internal.StarCalcTarget.Internal.TrakSyncPosRaw;
                    Diag.TargetInSyncLast[Internal.i] := Diag.TargetInSync[Internal.i];
                    Diag.TrackSyncPos[Internal.i] := StarInternal.PocketSync[Internal.i].TargetPosition;
                    Diag.TrackSyncLast[Internal.i] := StarInternal.LastTargetPosition[Internal.i];
                    Diag.TargetAssigned[Internal.i] := StarInternal.PocketSync[Internal.i].Sync;
                    Diag.TargetInSync[Internal.i] := StarInternal.PocketSync[Internal.i].InSync;
                END_FOR
                Valid := 1;
            ELSE
                Valid := 0;
                brsmemset(ADR(Diag), 0, SIZEOF(Diag));
                Busy := 0;
                Internal.State := slSTAR_DIAG_STATE_IDLE;
            END_IF
        
        slSTAR_DIAG_STATE_ERROR:
        
            IF NOT Enable THEN
                Error := 0;
                ErrorID := ERR_OK;
                Internal.State := slSTAR_DIAG_STATE_IDLE;
                Busy := 0;
            END_IF
        
    END_CASE
    
END_FUNCTION_BLOCK
