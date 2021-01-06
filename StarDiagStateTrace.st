
FUNCTION_BLOCK slStarDiagStateTrace

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
                        brsmemset(ADR(StateData), 0, SIZEOF(StateData));
                        StateData.StarSync.State[0] := StarInternal.State;
                        StateData.StarRecovery.State[0] := StarInternal.Recovery.Internal.State;
                        FOR Internal.i := 0 TO slMAX_TARGET_IDX DO
                            StateData.StarPocket[Internal.i].State[0] := StarInternal.PocketSync[Internal.i].Internal.State;
                            StateData.StarCalc[Internal.i].State[0] := StarInternal.PocketSync[Internal.i].Internal.StarCalcTarget.Internal.State;
                        END_FOR
                        Valid := 1;
                        Internal.State := slSTAR_DIAG_STATE_RUNNING;
                    END_IF
                END_IF
            END_IF
        
        slSTAR_DIAG_STATE_RUNNING:
            
            StarInternal ACCESS Internal.Handle;
            
            IF Enable THEN
                //Get the star sync state
                IF StarInternal.State <> StateData.StarSync.State[StateData.StarSync.LastIndex] THEN
                    StateData.StarSync.LastIndex := StateData.StarSync.LastIndex + 1;
                    IF StateData.StarSync.LastIndex > slMAX_STATE_TRACE_IDX THEN
                        StateData.StarSync.LastIndex := 0;
                    END_IF
                    StateData.StarSync.State[StateData.StarSync.LastIndex] := StarInternal.State;
                END_IF
                //Get the star recovery state
                IF StarInternal.Recovery.Internal.State <> StateData.StarRecovery.State[StateData.StarRecovery.LastIndex] THEN
                    StateData.StarRecovery.LastIndex := StateData.StarRecovery.LastIndex + 1;
                    IF StateData.StarRecovery.LastIndex > slMAX_STATE_TRACE_IDX THEN
                        StateData.StarRecovery.LastIndex := 0;
                    END_IF
                    StateData.StarRecovery.State[StateData.StarRecovery.LastIndex] := StarInternal.Recovery.Internal.State;
                END_IF
                FOR Internal.i := 0 TO slMAX_TARGET_IDX DO
                    //Get the pocket state
                    IF StarInternal.PocketSync[Internal.i].Internal.State <> StateData.StarPocket[Internal.i].State[StateData.StarPocket[Internal.i].LastIndex] THEN
                        StateData.StarPocket[Internal.i].LastIndex := StateData.StarPocket[Internal.i].LastIndex + 1;
                        IF StateData.StarPocket[Internal.i].LastIndex > slMAX_STATE_TRACE_IDX THEN
                            StateData.StarPocket[Internal.i].LastIndex := 0;
                        END_IF
                        StateData.StarPocket[Internal.i].State[StateData.StarPocket[Internal.i].LastIndex] := StarInternal.PocketSync[Internal.i].Internal.State;
                    END_IF
                    //Get the calc state
                    IF StarInternal.PocketSync[Internal.i].Internal.StarCalcTarget.Internal.State <> StateData.StarCalc[Internal.i].State[StateData.StarCalc[Internal.i].LastIndex] THEN
                        StateData.StarCalc[Internal.i].LastIndex := StateData.StarCalc[Internal.i].LastIndex + 1;
                        IF StateData.StarCalc[Internal.i].LastIndex > slMAX_STATE_TRACE_IDX THEN
                            StateData.StarCalc[Internal.i].LastIndex := 0;
                        END_IF
                       StateData.StarCalc[Internal.i].State[StateData.StarCalc[Internal.i].LastIndex] := StarInternal.PocketSync[Internal.i].Internal.StarCalcTarget.Internal.State;
                    END_IF
                END_FOR
            ELSE
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
