
FUNCTION_BLOCK tbRoutedMoveVelTrgBuffer

    CASE Internal.State OF
        
        tbRTD_TRG_BUF_STATE_IDLE:
            
            IF Enable THEN
                Busy := 1;
                Internal.TrgPointEnable.ProcessPoint := ADR(ProcessPoint);
                Internal.TrgPointEnable.Enable := 1;
                Internal.TrgPointGetInfo.ProcessPoint := ADR(ProcessPoint);
                Internal.RoutedMoveVel.Sector := ADR(Sector);
                Internal.RoutedMoveVel.Axis := ADR(Internal.TrgPointGetInfo.TrgPointInfo.Axis);
                Internal.State := tbRTD_TRG_BUF_STATE_ENABLE_TRIG;
            END_IF
            
        tbRTD_TRG_BUF_STATE_ENABLE_TRIG:
            
            IF Internal.TrgPointEnable.Valid THEN
                Active := 1;
            END_IF
            IF NOT Enable THEN
                Active := 0;
                Internal.State := tbRTD_TRG_BUF_STATE_RESET_FB;
            ELSIF Internal.TrgPointEnable.Error THEN
                Active := 0;
                Error := 1;
                ErrorID := Internal.TrgPointEnable.ErrorID;
                Internal.State := tbRTD_TRG_BUF_STATE_RESET_FB;
            ELSIF Internal.TrgPointEnable.Valid AND (Internal.TrgPointEnable.EventCount > 0) THEN
                Internal.TrgPointGetInfo.Execute := 1;
                Internal.State := tbRTD_TRG_BUF_STATE_GET_INFO;
            END_IF
            
        tbRTD_TRG_BUF_STATE_GET_INFO:
            
            IF NOT Enable THEN
                Active := 0;
                Internal.State := tbRTD_TRG_BUF_STATE_RESET_FB;
            ELSIF Internal.TrgPointGetInfo.Error THEN
                Active := 0;
                Error := 1;
                ErrorID := Internal.TrgPointGetInfo.ErrorID;
                Internal.State := tbRTD_TRG_BUF_STATE_RESET_FB;
            ELSIF Internal.TrgPointGetInfo.Done THEN
                IF tbShInBuffer(ADR(Buffer), ADR(Internal.TrgPointGetInfo.TrgPointInfo.Axis)) THEN
                    //The shuttle is already in the buffer
                    Internal.TrgPointGetInfo.Execute := 0;
                    Internal.State := tbRTD_TRG_BUF_STATE_ENABLE_TRIG;
                ELSE
                    //Continue adding the shuttle to the buffer
                    Internal.RoutedMoveVel.Position := Parameters.Position;
                    Internal.RoutedMoveVel.RouteVelocity := Parameters.RouteVelocity;
                    Internal.RoutedMoveVel.Velocity := Parameters.Velocity;
                    Internal.RoutedMoveVel.Acceleration := Parameters.Acceleration;
                    Internal.RoutedMoveVel.Deceleration := Parameters.Deceleration;
                    Internal.RoutedMoveVel.AdvancedParameters := Parameters.AdvancedParameters;
                    Internal.RoutedMoveVel.Execute := 1;
                    Internal.State := tbRTD_TRG_BUF_STATE_MOVE;
                END_IF
            END_IF
            
        tbRTD_TRG_BUF_STATE_MOVE:
            
            IF NOT Enable THEN
                Active := 0;
                Internal.State := tbRTD_TRG_BUF_STATE_RESET_FB;
            ELSIF Internal.RoutedMoveVel.Error THEN
                Active := 0;
                Error := 1;
                ErrorID := Internal.RoutedMoveVel.ErrorID;
                Internal.State := tbRTD_TRG_BUF_STATE_RESET_FB;
            ELSIF Internal.RoutedMoveVel.Active THEN
                Internal.TrgPointGetInfo.Execute := 0;
                Internal.RoutedMoveVel.Execute := 0;
                Internal.Status := tbBufferAddSh(ADR(Buffer), ADR(Internal.TrgPointGetInfo.TrgPointInfo.Axis));
                IF Internal.Status = ERR_OK THEN
                    //The shuttle was successfully added to the buffer
                    Internal.State := tbRTD_TRG_BUF_STATE_ENABLE_TRIG;
                ELSE
                    Active := 0;
                    Error := 1;
                    ErrorID := Internal.Status;
                    Internal.State := tbRTD_TRG_BUF_STATE_RESET_FB;
                END_IF
            END_IF
            
        tbRTD_TRG_BUF_STATE_RESET_FB:
            
            Internal.TrgPointEnable.Enable := 0;
            Internal.TrgPointGetInfo.Execute := 0;
            Internal.RoutedMoveVel.Execute := 0;
            IF Error THEN
                Internal.State := tbRTD_TRG_BUF_STATE_ERROR;
            ELSE
                Internal.State := tbRTD_TRG_BUF_STATE_NOT_BUSY;
            END_IF
            
        tbRTD_TRG_BUF_STATE_NOT_BUSY:
            
            IF NOT (Internal.TrgPointEnable.Busy OR Internal.TrgPointGetInfo.Busy OR Internal.RoutedMoveVel.Busy) THEN
                Busy := 0;
                Internal.State := tbRTD_TRG_BUF_STATE_IDLE;
            END_IF
            
        tbRTD_TRG_BUF_STATE_ERROR:
        
            IF NOT Enable THEN
                Error := 0;
                ErrorID := ERR_OK;
                Internal.State := tbRTD_TRG_BUF_STATE_NOT_BUSY;
            END_IF
            
    END_CASE
    
    Internal.TrgPointEnable();
    Internal.TrgPointGetInfo();
    Internal.RoutedMoveVel();
    
END_FUNCTION_BLOCK