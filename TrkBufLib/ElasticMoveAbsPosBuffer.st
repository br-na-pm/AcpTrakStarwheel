
FUNCTION_BLOCK tbElasticMoveAbsPosBuffer

    CASE Internal.State OF
        
        tbELA_POS_BUF_STATE_IDLE:
            
            IF Enable THEN
                Busy := 1;
                Active := 1;
                Internal.ShReadInfo.Axis := ADR(Internal.Axis);
                Internal.ElasticMoveAbs.Axis := ADR(Internal.Axis);
                Internal.State := tbELA_POS_BUF_STATE_WAIT;
            END_IF
            
        tbELA_POS_BUF_STATE_WAIT:
            
            IF NOT Enable THEN
                Active := 0;
                Internal.State := tbELA_POS_BUF_STATE_RESET_FB;
            ELSIF tbBufferShAvailable(ADR(BufferIn)) THEN
                //A shuttle is now available
                Internal.Status := tbBufferGetFirst(ADR(BufferIn), ADR(Internal.Axis));
                IF Internal.Status = ERR_OK THEN
                    //The shuttle axis was successfully obtained
                    IF tbShInBuffer(ADR(BufferOut), ADR(Internal.Axis)) THEN
                        //The shuttle already exists in the out buffer
                        Internal.Status := tbBufferRemoveFirst(ADR(BufferIn));
                        IF Internal.Status <> ERR_OK THEN
                            //An error occurred while removing the first shuttle from the buffer in
                            Active := 0;
                            Error := 1;
                            ErrorID := Internal.Status;
                            Internal.State := tbELA_POS_BUF_STATE_RESET_FB;
                        END_IF
                    ELSE
                        Internal.ShReadInfo.Enable := 1;
                        Internal.State := tbELA_POS_BUF_STATE_POS;
                    END_IF
                ELSE
                    //An error occurred while getting the shuttle axis
                    Active := 0;
                    Error := 1;
                    ErrorID := Internal.Status;
                    Internal.State := tbELA_POS_BUF_STATE_RESET_FB;
                END_IF
            END_IF
            
        tbELA_POS_BUF_STATE_POS:
            
            IF NOT Enable THEN
                Active := 0;
                Internal.State := tbELA_POS_BUF_STATE_RESET_FB;
            ELSIF Internal.ShReadInfo.Error THEN
                Active := 0;
                Error := 1;
                ErrorID := Internal.ShReadInfo.ErrorID;
                Internal.State := tbELA_POS_BUF_STATE_RESET_FB;
                
            ELSIF Internal.ShReadInfo.Valid AND 
                  (Internal.ShReadInfo.ShuttleInfo.CurrentValues.SectorType <> mcACPTRAK_SEC_INTERNAL) AND
                  (Internal.ShReadInfo.ShuttleInfo.CurrentValues.Position >= Parameters.ArrivalPosition) THEN
                
                Internal.ShReadInfo.Enable := 0;
                Internal.ElasticMoveAbs.Position := Parameters.DestinationPosition;
                Internal.ElasticMoveAbs.Velocity := Parameters.DestinationVelocity;
                Internal.ElasticMoveAbs.Acceleration := Parameters.DestinationAcceleration;
                Internal.ElasticMoveAbs.Deceleration := Parameters.DestinationDeceleration;
                Internal.ElasticMoveAbs.Execute := 1;
                Internal.State := tbELA_POS_BUF_STATE_MOVE;
                
            END_IF
            
        tbELA_POS_BUF_STATE_MOVE:
            
            IF NOT Enable THEN
                Active := 0;
                Internal.State := tbELA_POS_BUF_STATE_RESET_FB;
            ELSIF Internal.ElasticMoveAbs.Error THEN
                Active := 0;
                Error := 1;
                ErrorID := Internal.ElasticMoveAbs.ErrorID;
                Internal.State := tbELA_POS_BUF_STATE_RESET_FB;
            ELSIF Internal.ElasticMoveAbs.Active OR Internal.ElasticMoveAbs.Done THEN
                Internal.ElasticMoveAbs.Execute := 0;
                Internal.Status := tbBufferRemoveFirst(ADR(BufferIn));
                IF Internal.Status = ERR_OK THEN
                    Internal.Status := tbBufferAddSh(ADR(BufferOut), ADR(Internal.Axis));
                    IF Internal.Status = ERR_OK THEN
                        Internal.State := tbELA_POS_BUF_STATE_WAIT;
                    ELSE
                        //An error occurred while adding the shuttle to the buffer out
                        Active := 0;
                        Error := 1;
                        ErrorID := Internal.Status;
                        Internal.State := tbELA_POS_BUF_STATE_RESET_FB;
                    END_IF
                ELSE
                    //An error occurred while removing the first shuttle from the buffer in
                    Active := 0;
                    Error := 1;
                    ErrorID := Internal.Status;
                    Internal.State := tbELA_POS_BUF_STATE_RESET_FB;
                END_IF
            END_IF
            
        tbELA_POS_BUF_STATE_RESET_FB:
            
            Internal.ShReadInfo.Enable := 0;
            Internal.ElasticMoveAbs.Execute := 0;
            IF Error THEN
                Internal.State := tbELA_POS_BUF_STATE_ERROR;
            ELSE
                Internal.State := tbELA_POS_BUF_STATE_NOT_BUSY;
            END_IF
            
        tbELA_POS_BUF_STATE_NOT_BUSY:
            
            IF NOT (Internal.ShReadInfo.Busy OR Internal.ElasticMoveAbs.Busy) THEN
                Busy := 0;
                Internal.State := tbELA_POS_BUF_STATE_IDLE;
            END_IF
            
        tbELA_POS_BUF_STATE_ERROR:
        
            IF NOT Enable THEN
                Error := 0;
                ErrorID := ERR_OK;
                Internal.State := tbELA_POS_BUF_STATE_NOT_BUSY;
            END_IF
            
    END_CASE
    
    Internal.ShReadInfo();
    Internal.ElasticMoveAbs();
    
END_FUNCTION_BLOCK
