
FUNCTION_BLOCK slStarBuffer

    CASE Internal.State OF
        
        slSTAR_BUF_STATE_IDLE:
            
            IF Enable THEN
                Busy := 1;
                Internal.TrgPointEnable.ProcessPoint := ADR(ProcessPoint);
                Internal.TrgPointEnable.Enable := 1;
                Internal.TrgPointGetInfo.ProcessPoint := ADR(ProcessPoint);
                Internal.ElasticMoveAbs.Axis := ADR(Internal.TrgPointGetInfo.TrgPointInfo.Axis);
                Internal.State := slSTAR_BUF_STATE_ENABLE_TRIG;
            END_IF
            
        slSTAR_BUF_STATE_ENABLE_TRIG:
            
            IF NOT Enable THEN
                Internal.State := slSTAR_BUF_STATE_RESET_FB;
            ELSIF Internal.TrgPointEnable.Error THEN
                Error := 1;
                ErrorID := Internal.TrgPointEnable.ErrorID;
                Internal.State := slSTAR_BUF_STATE_RESET_FB;
            ELSIF Internal.TrgPointEnable.Valid AND (Internal.TrgPointEnable.EventCount > 0) THEN
                Internal.TrgPointGetInfo.Execute := 1;
                Internal.State := slSTAR_BUF_STATE_GET_INFO;
            END_IF
            
        slSTAR_BUF_STATE_GET_INFO:
            
            IF NOT Enable THEN
                Active := 0;
                Internal.State := slSTAR_BUF_STATE_RESET_FB;
            ELSIF Internal.TrgPointGetInfo.Error THEN
                Active := 0;
                Error := 1;
                ErrorID := Internal.TrgPointGetInfo.ErrorID;
                Internal.State := slSTAR_BUF_STATE_RESET_FB;
            ELSIF Internal.TrgPointGetInfo.Done THEN
                Internal.ShInBuffer := 0;
                Internal.i := Buffer.ReadIdx;
                WHILE Internal.i <> Buffer.WriteIdx DO
                    IF brsmemcmp(ADR(Buffer.Shuttles[Internal.i]), ADR(Internal.TrgPointGetInfo.TrgPointInfo.Axis), SIZEOF(Buffer.Shuttles[Internal.i])) = 0 THEN
                        Internal.ShInBuffer := 1;
                        EXIT;
                    END_IF
                    Internal.i := (Internal.i + 1) MOD (slMAX_SH_IDX_IN_SEC + 1);
                END_WHILE
                IF NOT Internal.ShInBuffer THEN
                    //Continue adding the shuttle to the buffer
                    Internal.ElasticMoveAbs.Position := Parameters.StagingPosition;
                    Internal.ElasticMoveAbs.Velocity := Parameters.StagingVelocity;
                    Internal.ElasticMoveAbs.Acceleration := Parameters.StagingAcceleration;
                    Internal.ElasticMoveAbs.Deceleration := Parameters.StagingDeceleration;
                    Internal.ElasticMoveAbs.Execute := 1;
                    Internal.State := slSTAR_BUF_STATE_MOVE_STAGING;
                ELSE
                    Internal.TrgPointGetInfo.Execute := 0;
                    Internal.State := slSTAR_BUF_STATE_ENABLE_TRIG;
                END_IF
            END_IF
            
        slSTAR_BUF_STATE_MOVE_STAGING:
            
            IF NOT Enable THEN
                Active := 0;
                Internal.State := slSTAR_BUF_STATE_RESET_FB;
            ELSIF Internal.ElasticMoveAbs.Error THEN
                Active := 0;
                Error := 1;
                ErrorID := Internal.ElasticMoveAbs.ErrorID;
                Internal.State := slSTAR_BUF_STATE_RESET_FB;
            ELSIF Internal.ElasticMoveAbs.Active THEN
                Internal.TrgPointGetInfo.Execute := 0;
                Internal.ElasticMoveAbs.Execute := 0;
                IF ((Buffer.WriteIdx + 1) MOD (slMAX_SH_IDX_IN_SEC + 1)) = Buffer.ReadIdx THEN
                    Active := 0;
                    Error := 1;
                    ErrorID := slERR_MAX_STAR_SH_IDX;
                    Internal.State := slSTAR_BUF_STATE_RESET_FB;
                ELSE
                    //Add the shuttle to the buffer
                    brsmemcpy(ADR(Buffer.Shuttles[Buffer.WriteIdx]), ADR(Internal.TrgPointGetInfo.TrgPointInfo.Axis), SIZEOF(Buffer.Shuttles[Buffer.WriteIdx]));
                    Buffer.WriteIdx := (Buffer.WriteIdx + 1) MOD (slMAX_SH_IDX_IN_SEC + 1);
                    Internal.State := slSTAR_BUF_STATE_ENABLE_TRIG;
                END_IF
            END_IF
            
        slSTAR_BUF_STATE_RESET_FB:
            
            Internal.TrgPointEnable.Enable := 0;
            Internal.TrgPointGetInfo.Execute := 0;
            Internal.ElasticMoveAbs.Execute := 0;
            IF Error THEN
                Internal.State := slSTAR_BUF_STATE_ERROR;
            ELSE
                Internal.State := slSTAR_BUF_STATE_WAIT_NOT_BUSY;
            END_IF
            
        slSTAR_BUF_STATE_WAIT_NOT_BUSY:
            
            IF NOT (Internal.TrgPointEnable.Busy OR Internal.TrgPointGetInfo.Busy OR Internal.ElasticMoveAbs.Busy) THEN
                Busy := 0;
                Internal.State := slSTAR_BUF_STATE_IDLE;
            END_IF
            
        slSTAR_BUF_STATE_ERROR:
        
            IF NOT Enable THEN
                Error := 0;
                ErrorID := ERR_OK;
                Internal.State := slSTAR_BUF_STATE_WAIT_NOT_BUSY;
            END_IF
            
    END_CASE
    
    Internal.TrgPointEnable();
    Internal.TrgPointGetInfo();
    Internal.ElasticMoveAbs();
    
END_FUNCTION_BLOCK