
FUNCTION_BLOCK slStarPocketSync
    
    Internal.StarCalcTarget();
    
    TargetPosition := Internal.StarCalcTarget.TrakPos;
    
    CASE Internal.State OF
        
        slPOCKET_SYN_STATE_IDLE:
            
            IF Enable THEN
                
                Busy := 1;
                
                Internal.StarCalcTarget.TargetIndex := TargetIndex;
				Internal.StarCalcTarget.PeriodCount := PeriodCount;
				Internal.StarCalcTarget.CalcData := ADR(CalcData);
                Internal.StarCalcTarget.Parameters := ADR(Parameters.StarCalcTarget);
                Internal.StarCalcTarget.Enable := 1;
                
                Internal.RoutedMoveVel.Sector := ADR(DestinationSector);
                
                Internal.State := slPOCKET_SYN_STATE_WAIT_SYNC;
                
            END_IF
            
        slPOCKET_SYN_STATE_WAIT_SYNC:
            
            IF NOT Enable THEN
                Internal.State := slPOCKET_SYN_STATE_RESET_FB;
            ELSIF Internal.StarCalcTarget.Error THEN
                Error := 1;
                ErrorID := Internal.StarCalcTarget.ErrorID;
                Internal.State := slPOCKET_SYN_STATE_RESET_FB;
            ELSIF Sync THEN
                
                Internal.CycPos.Axis := ADR(Axis);
                Internal.CycPos.AdvancedParameters := Parameters.CycPos.AdvancedParameters;
                Internal.CycPos.InterpolationMode := Parameters.CycPos.InterpolationMode;
                
                Internal.ShReadInfo.Axis := ADR(Axis);
                Internal.ShReadInfo.Enable := 1;
                
                Internal.Resize.Axis := ADR(Axis);
                Internal.Resize.Command := mcACPTRAK_RESIZE_DIMENSIONS;
                Internal.Resize.ResizeParameter := ResizeStartParameters.ResizeParameters;
                Internal.Resize.Execute := 1;
                
                Internal.ElasticMoveVel.Axis := ADR(Axis);
                Internal.ElasticMoveVel.Velocity := ReleaseParameters.Velocity;
                Internal.ElasticMoveVel.Acceleration := ReleaseParameters.Acceleration;
                Internal.ElasticMoveVel.Deceleration := ReleaseParameters.Deceleration;
                Internal.ElasticMoveVel.Direction := ReleaseParameters.Direction;
                
                Internal.RoutedMoveVel.Axis := ADR(Axis);
                
                Internal.State := slPOCKET_SYN_STATE_RESIZE_START;
                
            END_IF
            
        slPOCKET_SYN_STATE_RESIZE_START:
            
            IF NOT Enable THEN
                Internal.State := slPOCKET_SYN_STATE_RESET_FB;
            ELSIF Internal.StarCalcTarget.Error THEN
                Error := 1;
                ErrorID := Internal.StarCalcTarget.ErrorID;
                Internal.State := slPOCKET_SYN_STATE_RESET_FB;
            ELSIF Internal.ShReadInfo.Error THEN
                Error := 1;
                ErrorID := Internal.ShReadInfo.ErrorID;
                Internal.State := slPOCKET_SYN_STATE_RESET_FB;
            ELSIF Internal.Resize.Error THEN
                Error := 1;
                ErrorID := Internal.Resize.ErrorID;
                Internal.State := slPOCKET_SYN_STATE_RESET_FB;
            ELSIF Internal.Resize.Done THEN
                Internal.Resize.Execute := 0;
                Internal.State := slPOCKET_SYN_STATE_WAIT_TARGET;
            END_IF
            
        slPOCKET_SYN_STATE_WAIT_TARGET:
            
            IF NOT Enable THEN
                Internal.State := slPOCKET_SYN_STATE_RESET_FB;
            ELSIF Internal.StarCalcTarget.Error THEN
                Error := 1;
                ErrorID := Internal.StarCalcTarget.ErrorID;
                Internal.State := slPOCKET_SYN_STATE_RESET_FB;
            ELSIF Internal.ShReadInfo.Error THEN
                Error := 1;
                ErrorID := Internal.ShReadInfo.ErrorID;
                Internal.State := slPOCKET_SYN_STATE_RESET_FB;
            ELSIF Internal.ShReadInfo.Valid AND (Internal.StarCalcTarget.TrakPos >= Internal.ShReadInfo.ShuttleInfo.CurrentValues.Position) THEN
                IF Internal.StarCalcTarget.Valid THEN
                    Internal.CycPos.Enable := 1;
                    Internal.CycPos.CyclicPosition := Internal.StarCalcTarget.TrakPos;
                END_IF
                Internal.State := slPOCKET_SYN_STATE_SYNC;
            END_IF
        
        slPOCKET_SYN_STATE_SYNC:
            
            IF NOT Enable THEN
                Internal.State := slPOCKET_SYN_STATE_RESET_FB;
            ELSIF Internal.StarCalcTarget.Error THEN
                Error := 1;
                ErrorID := Internal.StarCalcTarget.ErrorID;
                Internal.State := slPOCKET_SYN_STATE_RESET_FB;
            ELSIF Internal.ShReadInfo.Error THEN
                Error := 1;
                ErrorID := Internal.ShReadInfo.ErrorID;
                Internal.State := slPOCKET_SYN_STATE_RESET_FB;
            ELSIF Internal.CycPos.Error THEN
                Error := 1;
                ErrorID := Internal.CycPos.ErrorID;
                Internal.State := slPOCKET_SYN_STATE_RESET_FB;
            //ELSIF Internal.CycPos.CommandAborted THEN
            //    Error := 1;
            //    ErrorID := slERR_SYNC_ABORTED;
            //    Internal.State := slPOCKET_SYN_STATE_RESET_FB;
            ELSIF Internal.StarCalcTarget.Valid THEN
                Internal.CycPos.Enable := 1;
                Internal.CycPos.CyclicPosition := Internal.StarCalcTarget.TrakPos;
                IF Internal.StarCalcTarget.TrakPos > ReleaseParameters.Position THEN
                    Internal.ElasticMoveVel.Execute := 1;
                    Internal.State := slPOCKET_SYN_STATE_RELEASE;
                END_IF
            ELSE
                Internal.CycPos.Enable := 0;
                Internal.CycPos.CyclicPosition := 0;
            END_IF
        
        slPOCKET_SYN_STATE_RELEASE:
            
            IF NOT Enable THEN
                Internal.State := slPOCKET_SYN_STATE_RESET_FB;
            ELSIF Internal.StarCalcTarget.Error THEN
                Error := 1;
                ErrorID := Internal.StarCalcTarget.ErrorID;
                Internal.State := slPOCKET_SYN_STATE_RESET_FB;
            ELSIF Internal.ShReadInfo.Error THEN
                Error := 1;
                ErrorID := Internal.ShReadInfo.ErrorID;
                Internal.State := slPOCKET_SYN_STATE_RESET_FB;
            ELSIF Internal.CycPos.Error THEN
                Error := 1;
                ErrorID := Internal.CycPos.ErrorID;
                Internal.State := slPOCKET_SYN_STATE_RESET_FB;
            ELSIF Internal.ElasticMoveVel.Error THEN
                Error := 1;
                ErrorID := Internal.ElasticMoveVel.ErrorID;
                Internal.State := slPOCKET_SYN_STATE_RESET_FB;
            ELSIF Internal.ElasticMoveVel.Active THEN
                Internal.State := slPOCKET_SYN_STATE_WAIT_RESIZE;
            END_IF
            
        slPOCKET_SYN_STATE_WAIT_RESIZE:
            
            IF NOT Enable THEN
                Internal.State := slPOCKET_SYN_STATE_RESET_FB;
            ELSIF Internal.ShReadInfo.Error THEN
                Error := 1;
                ErrorID := Internal.ShReadInfo.ErrorID;
                Internal.State := slPOCKET_SYN_STATE_RESET_FB;
            ELSIF Internal.ElasticMoveVel.Error THEN
                Error := 1;
                ErrorID := Internal.ElasticMoveVel.ErrorID;
                Internal.State := slPOCKET_SYN_STATE_RESET_FB;
            ELSIF Internal.ShReadInfo.Valid AND (Internal.ShReadInfo.ShuttleInfo.CurrentValues.Position > ResizeEndParameters.Position) THEN
                Internal.Resize.ResizeParameter := ResizeEndParameters.ResizeParameters;
                Internal.Resize.Execute := 1;
                Internal.State := slPOCKET_SYN_STATE_RESIZE_END;
            END_IF
            
        slPOCKET_SYN_STATE_RESIZE_END:
            
            IF NOT Enable THEN
                Internal.State := slPOCKET_SYN_STATE_RESET_FB;
            ELSIF Internal.Resize.Error THEN
                Error := 1;
                ErrorID := Internal.Resize.ErrorID;
                Internal.State := slPOCKET_SYN_STATE_RESET_FB;
            ELSIF Internal.Resize.Done THEN
                Internal.CycPos.Enable := 0;
                Internal.ElasticMoveVel.Execute := 0;
                Internal.Resize.Execute := 0;
                Internal.State := slPOCKET_SYN_STATE_WAIT_SEND;
            END_IF
            
        slPOCKET_SYN_STATE_WAIT_SEND:
                 
            IF NOT Enable THEN
                Internal.State := slPOCKET_SYN_STATE_RESET_FB;
            ELSIF Internal.ShReadInfo.Error THEN
                Error := 1;
                ErrorID := Internal.ShReadInfo.ErrorID;
                Internal.State := slPOCKET_SYN_STATE_RESET_FB;
            ELSIF Internal.ShReadInfo.Valid AND (Internal.ShReadInfo.ShuttleInfo.CurrentValues.Position > DestinationParameters.SendPosition) THEN
                Internal.RoutedMoveVel.Position := DestinationParameters.TargetPosition;
                Internal.RoutedMoveVel.RouteVelocity := DestinationParameters.RouteVelocity;
                Internal.RoutedMoveVel.Velocity := DestinationParameters.Velocity;
                Internal.RoutedMoveVel.Acceleration := DestinationParameters.Acceleration;
                Internal.RoutedMoveVel.Deceleration := DestinationParameters.Deceleration;
                Internal.RoutedMoveVel.AdvancedParameters := DestinationParameters.AdvancedParameters;
                Internal.RoutedMoveVel.Execute := 1;
                Internal.State := slPOCKET_SYN_STATE_SEND;
            END_IF
            
        slPOCKET_SYN_STATE_SEND:
            
            IF NOT Enable THEN
                Internal.State := slPOCKET_SYN_STATE_RESET_FB;
            ELSIF Internal.RoutedMoveVel.Error THEN
                Error := 1;
                ErrorID := Internal.RoutedMoveVel.ErrorID;
                Internal.State := slPOCKET_SYN_STATE_RESET_FB;
            ELSIF Internal.RoutedMoveVel.Active THEN
                Internal.RoutedMoveVel.Execute := 0;
                Internal.ShReadInfo.Enable := 0;
                Done := 1;
                Internal.State := slPOCKET_SYN_STATE_DONE;
            END_IF
        
        slPOCKET_SYN_STATE_DONE:
            
            IF NOT Sync THEN
                Done := 0;
                Internal.State := slPOCKET_SYN_STATE_WAIT_SYNC;
            END_IF
              
        slPOCKET_SYN_STATE_RESET_FB:
            
            Sync := 0;
            Internal.StarCalcTarget.Enable := 0;
            Internal.ShReadInfo.Enable := 0;
            Internal.CycPos.Enable := 0;
            Internal.ElasticMoveVel.Execute := 0;
            Internal.RoutedMoveVel.Execute := 0;
            Internal.Resize.Execute := 0;
            IF Error THEN
                Internal.State := slPOCKET_SYN_STATE_ERROR;
            ELSE
                Internal.State := slPOCKET_SYN_STATE_WAIT_NOT_BUSY;
            END_IF
            
            
        slPOCKET_SYN_STATE_WAIT_NOT_BUSY:
            
            IF NOT (Internal.ShReadInfo.Busy OR Internal.CycPos.Busy OR Internal.ElasticMoveVel.Busy OR Internal.RoutedMoveVel.Busy OR Internal.Resize.Busy) THEN
                Busy := 0;
                Internal.State := slPOCKET_SYN_STATE_IDLE;
            END_IF
        
        slPOCKET_SYN_STATE_ERROR:
        
            IF NOT Enable THEN
                Error := 0;
                ErrorID := ERR_OK;
                Internal.State := slPOCKET_SYN_STATE_RESET_FB;
            END_IF
        
    END_CASE
    
    Internal.ShReadInfo();
    Internal.CycPos();
    Internal.ElasticMoveVel();
    Internal.RoutedMoveVel();
    Internal.Resize();
    
    InSync := Internal.CycPos.InCyclicPosition;
    Active := Enable AND Internal.StarCalcTarget.Valid AND NOT Error;

END_FUNCTION_BLOCK