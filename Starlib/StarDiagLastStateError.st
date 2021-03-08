
FUNCTION_BLOCK slStarDiagLastStateError

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
                        brsmemset(ADR(ErrorIDs), 0, SIZEOF(ErrorIDs));
                        Internal.LastStateData.StarSync := StarInternal.State;
                        Internal.LastStateData.StarRecovery := StarInternal.Recovery.Internal.State;
                        LastStates.StarSync := slSTAR_STATE_IDLE;
                        LastStates.StarRecovery := slREC_STATE_IDLE;
                        FOR Internal.i := 0 TO slMAX_TARGET_IDX DO
                            Internal.LastStateData.StarPocketSync[Internal.i] := StarInternal.PocketSync[Internal.i].Internal.State;
                            Internal.LastStateData.StarCalcTarget[Internal.i] := StarInternal.PocketSync[Internal.i].Internal.StarCalcTarget.Internal.State;
                            LastStates.StarPocketSync[Internal.i] := slPOCKET_SYN_STATE_IDLE;
                            LastStates.StarCalcTarget[Internal.i] := slTARGET_CALC_STATE_IDLE;
                        END_FOR
                        Internal.State := slSTAR_DIAG_STATE_RUNNING;
                    END_IF
                END_IF
            END_IF
        
        slSTAR_DIAG_STATE_RUNNING:
            
            IF Enable THEN
                StarInternal ACCESS Internal.Handle;
                //Monitor the star sync state
                IF (StarInternal.State = slSTAR_STATE_RESET_FB) AND (Internal.LastStateData.StarSync <> slSTAR_STATE_RESET_FB) THEN
                    Internal.LastStateData.StarSyncAtReset := Internal.LastStateData.StarSync;
                END_IF
                IF (StarInternal.State = slSTAR_STATE_ERROR) AND (Internal.LastStateData.StarSync <> slSTAR_STATE_ERROR) THEN
                    LastStates.StarSync := Internal.LastStateData.StarSyncAtReset;
                    ErrorIDs.StarSync := StarInternal.ErrorID;
                END_IF
                Internal.LastStateData.StarSync := StarInternal.State;
                //Monitor the star recovery state
                IF StarInternal.Recovery.Error AND NOT Internal.StarRecoveryError THEN
                    LastStates.StarRecovery := Internal.LastStateData.StarRecovery;
                    ErrorIDs.StarRecovery := StarInternal.Recovery.ErrorID;
                END_IF
                Internal.LastStateData.StarRecovery := StarInternal.Recovery.Internal.State;
                Internal.StarRecoveryError := StarInternal.Recovery.Error;
                FOR Internal.i := 0 TO slMAX_TARGET_IDX DO
                    //Monitor the pocket sync states
                    IF StarInternal.PocketSync[Internal.i].Error AND NOT Internal.StarPocketSyncError[Internal.i] THEN
                        LastStates.StarPocketSync[Internal.i] := Internal.LastStateData.StarPocketSync[Internal.i];
                        ErrorIDs.StarPocketSync[Internal.i] := StarInternal.PocketSync[Internal.i].ErrorID;
                    END_IF
                    Internal.LastStateData.StarPocketSync[Internal.i] := StarInternal.PocketSync[Internal.i].Internal.State;
                    Internal.StarPocketSyncError[Internal.i] := StarInternal.PocketSync[Internal.i].Error;
                    //Monitor the target calculation states
                    IF StarInternal.PocketSync[Internal.i].Internal.StarCalcTarget.Error AND NOT Internal.StarCalcTargetError[Internal.i] THEN
                        LastStates.StarCalcTarget[Internal.i] := Internal.LastStateData.StarCalcTarget[Internal.i];
                        ErrorIDs.StarCalcTarget[Internal.i] := StarInternal.PocketSync[Internal.i].Internal.StarCalcTarget.ErrorID;
                    END_IF
                    Internal.LastStateData.StarCalcTarget[Internal.i] := StarInternal.PocketSync[Internal.i].Internal.StarCalcTarget.Internal.State;
                    Internal.StarCalcTargetError[Internal.i] := StarInternal.PocketSync[Internal.i].Internal.StarCalcTarget.Error;
                END_FOR
                Valid := 1;
            ELSE
                Internal.StarRecoveryError := 0;
                brsmemset(ADR(Internal.StarPocketSyncError), 0, SIZEOF(Internal.StarPocketSyncError));
                brsmemset(ADR(Internal.StarCalcTargetError), 0, SIZEOF(Internal.StarCalcTargetError));
                Valid := 0;
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
