
FUNCTION_BLOCK slStarSync
	
	
    
    //Check for an error on a pocket
    Internal.PocketSyncError := 0;
    Internal.PocketSyncErrorID := ERR_OK;
    FOR Internal.i := 0 TO slMAX_TARGET_IDX DO
        Internal.PocketSync[Internal.i].StarwheelPosition := StarwheelPosition;
        Internal.PocketSync[Internal.i].StarwheelVelocity := StarwheelVelocity;
        IF Internal.PocketSync[Internal.i].Error THEN
            Internal.PocketSyncError := 1;
            Internal.PocketSyncErrorID := Internal.PocketSync[Internal.i].ErrorID;
            EXIT;
        END_IF
    END_FOR
    
    IF Enable AND Busy THEN
        // Continuously watch for calculated Track Sync Positions to overtake the Sync Threshold, and update the NextSyncTarget selector
        // Also monitor for completion
        FOR Internal.i := 0 TO Internal.MaxTargetIndex DO
            IF Internal.PocketSync[Internal.i].TargetPosition >= Parameters.ProcessPointStartPosition + Parameters.StartOffset AND
                Internal.LastTargetPosition[Internal.i] < Parameters.ProcessPointStartPosition + Parameters.StartOffset AND
                Internal.PocketSync[Internal.i].TargetPosition < Parameters.SyncPar.StarCalcTarget.SectorTangentPos AND 
                Internal.PocketSync[Internal.i].Active AND
                NOT Internal.PocketSync[Internal.i].Sync 
                AND Internal.RecoveryDone THEN
    			
                Internal.PocketDisabled := 0;
                IF DisablePockets AND (Parameters.Skip.NumDisabled > 0) THEN
					FOR Internal.n := 0 TO MIN(Parameters.Skip.NumDisabled - 1, slMAX_DISABLE_POCKET_IDX) DO
                        IF Parameters.Skip.DisabledIdx[Internal.n] = (Internal.i MOD (Parameters.SyncPar.StarCalcTarget.StarwheelPocketCount)) THEN
                            Internal.PocketDisabled := 1;
                            EXIT;
                        END_IF
                    END_FOR
				END_IF
				
				IF Internal.PocketDisabled THEN
					Internal.NewDisabledOvertake	:= TRUE;
				ELSE
					Internal.NextSyncTarget			:= Internal.i;
					Internal.NewOvertakeDetected	:= TRUE;
				END_IF;
				
    			
            END_IF
            IF Internal.PocketSync[Internal.i].Done THEN
                Internal.PocketSync[Internal.i].Sync := 0;
            END_IF
        END_FOR
    ELSE
        Internal.NextSyncTarget := 0;
        Internal.NewOvertakeDetected := FALSE;
    END_IF

    CASE Internal.State OF
        
        slSTAR_STATE_IDLE:
            
            IF Enable THEN
                
                Busy := 1;
                
                Handle := ADR(Internal);
                Internal.TypeID := slSTAR_INTERNAL_TYPE_ID;
                
                // Calculate how many periods of starwheel rotation we should calculate track positions for,
                // in order to cover the area from SyncPP TO ReleasePP
                Internal.PeriodCount := 0;
                FOR Internal.i := 0 TO slMAX_PERIOD_IDX DO
                    IF Internal.i * brmTWOPI * Parameters.SyncPar.StarCalcTarget.StarwheelRadius > (Parameters.SyncPar.StarCalcTarget.SectorTangentPos - Parameters.StartOffset) THEN
                        Internal.PeriodCount := UINT_TO_USINT(Internal.i + 1);
                        EXIT;
                    END_IF
                END_FOR
                
                Internal.MaxTargetIndex := Parameters.SyncPar.StarCalcTarget.StarwheelPocketCount * Internal.PeriodCount - 1;
                
                IF Internal.MaxTargetIndex > slMAX_TARGET_IDX THEN
                    
                    Error := 1;
                    ErrorID := slERR_MAX_TARGET_IDX;
                    Internal.State := slSTAR_STATE_RESET_FB;
                    
                ELSE
                
                    Internal.PocketWidth        := 2 * slPI * Parameters.SyncPar.StarCalcTarget.StarwheelRadius / USINT_TO_REAL(Parameters.SyncPar.StarCalcTarget.StarwheelPocketCount);
                    Internal.MeshZoneStartPos   := Parameters.SyncPar.StarCalcTarget.SectorTangentPos - Internal.PocketWidth*0.75;
                    Internal.MeshZoneEndPos     := Parameters.SyncPar.StarCalcTarget.SectorTangentPos + Internal.PocketWidth;
                    
                    Internal.TrgPointEnable.ProcessPoint := ADR(ProcessPointStart);
                    
                    Internal.TrgPointGetInfo.ProcessPoint := ADR(ProcessPointStart);
                    
                    Internal.BarrierCommand.ProcessPoint := ADR(ProcessPointStart);
                    Internal.BarrierCommand.AdvancedParameters.TicketCount := 0;
                    Internal.BarrierCommand.Command := mcACPTRAK_BARRIER_CLOSE;
                    Internal.BarrierCommand.Execute := 1;
                    
					Internal.BarrierReadInfo.ProcessPoint := ADR(ProcessPointStart);
					                    
                    FOR Internal.i := 0 TO slMAX_TARGET_IDX  DO
                        Internal.PocketSync[Internal.i].TargetIndex := UINT_TO_USINT(Internal.i);
                        Internal.PocketSync[Internal.i].PeriodCount := Internal.PeriodCount;
						Internal.PocketSync[Internal.i].Parameters := ADR(Parameters.SyncPar);
						Internal.PocketSync[Internal.i].CalcData := ADR(Internal.StarCalcData);
                        Internal.PocketSync[Internal.i].Enable := (Internal.i <= Internal.MaxTargetIndex);
                    END_FOR
                
                    Internal.State := slSTAR_STATE_CLOSE_BARRIER;
                    
                END_IF
                
            END_IF
            
        slSTAR_STATE_CLOSE_BARRIER:
            
            IF NOT Enable THEN
                Internal.State := slSTAR_STATE_RESET_FB;
            ELSIF Internal.BarrierCommand.Error THEN
                Error := 1;
                ErrorID := Internal.BarrierCommand.ErrorID;
                Internal.State := slSTAR_STATE_RESET_FB;
            ELSIF Internal.BarrierCommand.Done THEN
                Internal.BarrierCommand.Execute := 0;
                Internal.State := slSTAR_STATE_RECOVER;
            END_IF
            
        slSTAR_STATE_RECOVER:
            
            Internal.RecoveryPar.MeshZoneStartPos   := Internal.MeshZoneStartPos;
            Internal.RecoveryPar.SyncFurtherInEnabled   := Parameters.Recovery.SyncFurtherInEnabled;
            Internal.RecoveryPar.MeshZoneEndPos     := Internal.MeshZoneEndPos;
            Internal.RecoveryPar.SectorTangentPos   := Parameters.SyncPar.StarCalcTarget.SectorTangentPos;
            Internal.RecoveryPar.ShExtentToFront        := Parameters.ShExtentToFront;
            Internal.RecoveryPar.ProcessPointStartPosition := Parameters.ProcessPointStartPosition;
            Internal.RecoveryPar.StartOffset := Parameters.StartOffset;
            Internal.RecoveryPar.ResizeStart := Parameters.SyncPar.ResizeStart;
            Internal.RecoveryPar.ResizeEnd := Parameters.SyncPar.ResizeEnd;
            Internal.RecoveryPar.Release.Position := Parameters.SyncPar.Release.Position;
            Internal.RecoveryPar.Release.DestinationSector := Parameters.Recovery.Release.DestinationSector;
            Internal.RecoveryPar.Release.Velocity := Parameters.Recovery.Release.Velocity;
            Internal.RecoveryPar.Release.Acceleration := Parameters.Recovery.Release.Acceleration;
            Internal.RecoveryPar.Release.Deceleration := Parameters.Recovery.Release.Deceleration;
            Internal.RecoveryPar.UserData := Parameters.Recovery.UserData;
            Internal.RecoveryPar.PocketErrorTolerance := Parameters.Recovery.PocketErrorTolerance;
            Internal.RecoveryPar.Backup.ProcessPointStart := ProcessPointStart;
            Internal.RecoveryPar.Backup.BackupTolerance := Parameters.Recovery.BackupTolerance;
            Internal.RecoveryPar.Backup.MoveToBarVelocity   := Parameters.Recovery.MoveToBarVelocity;
            Internal.RecoveryPar.Backup.MoveToBarAcceleration   := Parameters.Recovery.MoveToBarAcceleration;
            Internal.RecoveryPar.Backup.MoveToBarDeceleration   := Parameters.Recovery.MoveToBarDeceleration;
            
            Internal.Recovery.Parameters := ADR(Internal.RecoveryPar);
            Internal.Recovery.Sector := ADR(Sector);
            Internal.Recovery.Handle := Handle;
            Internal.Recovery.Assembly  := ADR(Assembly);
            Internal.Recovery.Enable := 1;
            
            IF Internal.Recovery.ReadyForStart THEN
                ReadyForStart := 1;
            END_IF;
            
            IF NOT Enable THEN
                Internal.State := slSTAR_STATE_RESET_FB;
            ELSIF Internal.Recovery.Error THEN
                Error := 1;
                ErrorID := Internal.Recovery.ErrorID;
                Internal.State := slSTAR_STATE_RESET_FB;
            ELSIF Internal.Recovery.Done THEN
                ReadyForStart := 1;
                Internal.RecoveryDone   := TRUE;
                Internal.Recovery.Enable := 0;
                Internal.TrgPointEnable.Enable := 1;
                Active := 1;
                
                Internal.NextSyncFITarget   := ClosestSyncPocket(Internal.MeshZoneStartPos, Parameters.ProcessPointStartPosition + Parameters.StartOffset, Handle);
                IF Parameters.Recovery.SyncFurtherInEnabled AND Internal.NextSyncFITarget <> slNO_CLOSEST_POCKET_FOUND THEN
                    Internal.BarrierReadInfo.Enable := 1;
                    Internal.State := slSTAR_STATE_SYNCFI_TICKET_COUNT;
                ELSE
                    Internal.SyncFurtherInDone  := TRUE;
                    Internal.State := slSTAR_STATE_WAIT_TARGET;
                END_IF;
            END_IF
        
        slSTAR_STATE_SYNCFI_TICKET_COUNT:
     
            IF NOT Enable THEN
                Internal.State := slSTAR_STATE_RESET_FB;
            ELSIF Internal.BarrierReadInfo.BarrierInfo.RemainingTickets = 0 THEN
            
                Internal.BarrierCommand.AdvancedParameters.TicketCount := 1;
                Internal.BarrierCommand.Command := mcACPTRAK_BARRIER_ADD_TICKETS;
                Internal.BarrierCommand.Execute := 1;
                Internal.State := slSTAR_STATE_ADD_TICKET;
            ELSE
                Internal.State := slSTAR_STATE_WAIT_SHUTTLE;
            END_IF;
            
        slSTAR_STATE_SYNCFI_ADD_TICKET:
                    
            IF NOT Enable THEN
                Internal.State := slSTAR_STATE_RESET_FB;
            ELSIF Internal.BarrierCommand.Error THEN
                Error := 1;
                ErrorID := Internal.BarrierCommand.ErrorID;
                Internal.State := slSTAR_STATE_RESET_FB;
            ELSIF Internal.BarrierCommand.Done THEN
                Internal.BarrierCommand.Execute := 0;
                Internal.State := slSTAR_STATE_WAIT_SHUTTLE;
            END_IF
            
        slSTAR_STATE_WAIT_TARGET:
            
            IF NOT Enable THEN
                Internal.State := slSTAR_STATE_RESET_FB;
            ELSIF Internal.TrgPointEnable.Error THEN
                Error := 1;
                ErrorID := Internal.TrgPointEnable.ErrorID;
                Internal.State := slSTAR_STATE_RESET_FB;
            ELSIF Internal.PocketSyncError THEN
                Error := 1;
                ErrorID := Internal.PocketSyncErrorID;
                Internal.State := slSTAR_STATE_RESET_FB;
                //Check for new pocket
            ELSIF Internal.NewOvertakeDetected THEN
                IF SkipPockets THEN
                    IF Internal.SkipCount < Parameters.Skip.NumSkips THEN
                        Internal.NewOvertakeDetected := 0;
                        Internal.SkipCount := Internal.SkipCount + 1;
                    ELSE
                        Internal.BarrierReadInfo.Enable := 1;
                        Internal.State := slSTAR_STATE_TICKET_COUNT;
                        Internal.SkipCount := 0;
                    END_IF
                ELSE
                    Internal.BarrierReadInfo.Enable := 1;
                    Internal.State := slSTAR_STATE_TICKET_COUNT;
				END_IF
			ELSIF Internal.NewDisabledOvertake THEN
				Internal.BarrierReadInfo.Enable := 1;
				Internal.State := slSTAR_STATE_TICKET_COUNT;
            END_IF
        
        slSTAR_STATE_TICKET_COUNT:
            
            IF NOT Enable THEN
                Internal.State := slSTAR_STATE_RESET_FB;
            ELSIF Internal.BarrierReadInfo.Error THEN
                Error := 1;
                ErrorID := Internal.BarrierReadInfo.ErrorID;
                Internal.State := slSTAR_STATE_RESET_FB;
            ELSIF Internal.BarrierReadInfo.Valid THEN
                Internal.BarrierReadInfo.Enable := 0;
                IF Internal.BarrierReadInfo.BarrierInfo.RemainingTickets = 0 AND Internal.NewOvertakeDetected THEN
                    Internal.BarrierCommand.AdvancedParameters.TicketCount := 1;
                    Internal.BarrierCommand.Command := mcACPTRAK_BARRIER_ADD_TICKETS;
                    Internal.BarrierCommand.Execute := 1;
					Internal.State := slSTAR_STATE_ADD_TICKET;
				ELSIF Internal.BarrierReadInfo.BarrierInfo.RemainingTickets >= 1 AND Internal.NewDisabledOvertake THEN
					Internal.BarrierCommand.AdvancedParameters.TicketCount := -1 * UDINT_TO_DINT(Internal.BarrierReadInfo.BarrierInfo.RemainingTickets);
					Internal.BarrierCommand.Command := mcACPTRAK_BARRIER_ADD_TICKETS;
					Internal.BarrierCommand.Execute := 1;
					Internal.State := slSTAR_STATE_REMOVE_TICKETS;
				ELSIF Internal.BarrierReadInfo.BarrierInfo.RemainingTickets = 0 AND Internal.NewDisabledOvertake THEN
					Internal.NewDisabledOvertake := 0;
					Internal.State := slSTAR_STATE_WAIT_TARGET;
				ELSE
                    Internal.State := slSTAR_STATE_WAIT_SHUTTLE;
                END_IF
            END_IF
            
        slSTAR_STATE_ADD_TICKET:
            
            IF NOT Enable THEN
                Internal.State := slSTAR_STATE_RESET_FB;
            ELSIF Internal.BarrierCommand.Error THEN
                Error := 1;
                ErrorID := Internal.BarrierCommand.ErrorID;
                Internal.State := slSTAR_STATE_RESET_FB;
            ELSIF Internal.BarrierCommand.Done THEN
                Internal.BarrierCommand.Execute := 0;
                Internal.State := slSTAR_STATE_WAIT_SHUTTLE;
			END_IF
			
		slSTAR_STATE_REMOVE_TICKETS:
			
			IF NOT Enable THEN
				Internal.State := slSTAR_STATE_RESET_FB;
			ELSIF Internal.BarrierCommand.Error THEN
				Error := 1;
				ErrorID := Internal.BarrierCommand.ErrorID;
				Internal.State := slSTAR_STATE_RESET_FB;
			ELSIF Internal.BarrierCommand.Done THEN
				Internal.BarrierCommand.Execute := 0;
				Internal.NewDisabledOvertake := 0;
				Internal.State := slSTAR_STATE_WAIT_TARGET;
			END_IF;			
            
        slSTAR_STATE_WAIT_SHUTTLE:
            
            IF NOT Enable THEN
                Internal.State := slSTAR_STATE_RESET_FB;
            ELSIF Internal.TrgPointEnable.Error THEN
                Error := 1;
                ErrorID := Internal.TrgPointEnable.ErrorID;
                Internal.State := slSTAR_STATE_RESET_FB;
            ELSIF Internal.TrgPointEnable.Valid AND Internal.TrgPointEnable.EventCount > 0 THEN
                Internal.TrgPointGetInfo.Execute := 1;
                Internal.State := slSTAR_STATE_EVENT_INFO;
            END_IF
        
        slSTAR_STATE_EVENT_INFO:
            
            IF NOT Enable THEN
                Internal.State := slSTAR_STATE_RESET_FB;
            ELSIF Internal.TrgPointGetInfo.Error THEN
                Error := 1;
                ErrorID := Internal.TrgPointGetInfo.ErrorID;
                Internal.State := slSTAR_STATE_RESET_FB;
            ELSIF Internal.TrgPointGetInfo.Done THEN
                Internal.TrgPointGetInfo.Execute := 0;
                IF Parameters.Recovery.SyncFurtherInEnabled AND NOT Internal.SyncFurtherInDone THEN
                    IF Internal.TrgPointGetInfo.TrgPointInfo.Event = mcACPTRAK_TP_PASSED_POSITIVE THEN
                        Internal.PocketSync[Internal.NextSyncFITarget].Axis := Internal.TrgPointGetInfo.TrgPointInfo.Axis;
                        Internal.PocketSync[Internal.NextSyncFITarget].Sync := 1;
                    END_IF
                    Internal.NextSyncFITarget   := ClosestSyncPocket(Internal.MeshZoneStartPos, Parameters.ProcessPointStartPosition + Parameters.StartOffset, Handle);
                    IF Internal.NextSyncFITarget <> slNO_CLOSEST_POCKET_FOUND THEN
                        Internal.State := slSTAR_STATE_SYNCFI_TICKET_COUNT;
                    ELSE
                        Internal.SyncFurtherInDone  := TRUE;
                        Internal.NewOvertakeDetected := 0;
                        Internal.State := slSTAR_STATE_WAIT_TARGET;
                    END_IF;
                ELSE
                    IF Internal.TrgPointGetInfo.TrgPointInfo.Event = mcACPTRAK_TP_PASSED_POSITIVE THEN
                        Internal.PocketSync[Internal.NextSyncTarget].Axis := Internal.TrgPointGetInfo.TrgPointInfo.Axis;
                        Internal.PocketSync[Internal.NextSyncTarget].Sync := 1;
                    END_IF
                    Internal.NewOvertakeDetected := 0;
                    Internal.State := slSTAR_STATE_WAIT_TARGET;
                END_IF;
            END_IF
            
        slSTAR_STATE_RESET_FB:
            
            Active := 0;
            ReadyForStart := 0;
            Internal.NextSyncTarget := 0;
            Internal.NewOvertakeDetected := 0;
            Internal.TrgPointEnable.Enable := 0;
            Internal.TrgPointGetInfo.Execute := 0;
            Internal.BarrierCommand.Execute := 0;
            Internal.BarrierReadInfo.Enable := 0;
            Internal.Recovery.Enable := 0;
            Internal.SyncFurtherInDone  := FALSE;
            Internal.RecoveryDone   := FALSE;
            Internal.ErrorID := ErrorID;
            FOR Internal.i := 0 TO slMAX_TARGET_IDX DO
                Internal.PocketSync[Internal.i].Sync := 0;
                Internal.PocketSync[Internal.i].Enable := 0;
            END_FOR
            IF Error THEN
                Internal.State := slSTAR_STATE_ERROR;
            ELSE
                //We only get here if the enable has been dropped
                Internal.State := slSTAR_STATE_OPEN_BARRIER;
            END_IF
        
        slSTAR_STATE_OPEN_BARRIER:
            
            //We should only open the barrier if the enable has been dropped
            Internal.BarrierCommand.Command := mcACPTRAK_BARRIER_OPEN;
            Internal.BarrierCommand.Execute := 1;
            IF Internal.BarrierCommand.Error THEN
                Internal.BarrierCommand.Execute := 0;
                Error := 1;
                ErrorID := Internal.BarrierCommand.ErrorID;
                Internal.State := slSTAR_STATE_WAIT_NOT_BUSY;
            ELSIF Internal.BarrierCommand.Done THEN
                Internal.BarrierCommand.Execute := 0;
                Internal.State := slSTAR_STATE_WAIT_NOT_BUSY;
            END_IF
        
        slSTAR_STATE_WAIT_NOT_BUSY:
            
            Internal.PocketSyncBusy := 0;
            FOR Internal.i := 0 TO slMAX_TARGET_IDX DO
                IF Internal.PocketSync[Internal.i].Busy THEN
                    Internal.PocketSyncBusy := 1;
                END_IF
            END_FOR
            
            IF NOT (Internal.PocketSyncBusy OR Internal.TrgPointEnable.Busy OR Internal.TrgPointGetInfo.Busy OR
                    Internal.BarrierCommand.Busy OR Internal.BarrierReadInfo.Busy OR Internal.Recovery.Busy) THEN
                
                Error := 0;
                ErrorID := ERR_OK;
                Busy := 0;
                Internal.State := slSTAR_STATE_IDLE;
                
            END_IF
        
        slSTAR_STATE_ERROR:
        
            IF NOT Enable THEN
                Error := 0;
                ErrorID := ERR_OK;
                Internal.State := slSTAR_STATE_OPEN_BARRIER;
            END_IF
        
	END_CASE
	
		
	IF Enable THEN
		IF Parameters.SyncPar.StarCalcTarget.StarwheelPeriod <> 0 THEN			
			//Calculate latency compensation
			Internal.StarCalcData.StarPosPredict := StarwheelPosition + StarwheelVelocity * TIME_TO_REAL(Parameters.SyncPar.StarCalcTarget.DeltaT) / 1000.0;
			Internal.StarCalcData.StarPosPredict := EuclideanModuloFLT(Internal.StarCalcData.StarPosPredict, Parameters.SyncPar.StarCalcTarget.StarwheelPeriod);
		END_IF
		
		//Detect starwheel position rollover
		IF (Internal.StarCalcData.StarPosPredict - Internal.OldStarPosPredict) > (Parameters.SyncPar.StarCalcTarget.StarwheelPeriod / 4.0) THEN //Rollover backwards
			Internal.StarCalcData.CurrentStarwheelPeriod := Internal.StarCalcData.CurrentStarwheelPeriod - 1;
		ELSIF (Internal.OldStarPosPredict - Internal.StarCalcData.StarPosPredict) > (Parameters.SyncPar.StarCalcTarget.StarwheelPeriod / 4.0) THEN //Rollover forwards
			Internal.StarCalcData.CurrentStarwheelPeriod := Internal.StarCalcData.CurrentStarwheelPeriod + 1;
		END_IF
        
		// Constrain CurrentStarwheelPeriod to {0..Sector.Par.PeriodCount-1}, EuclideanModulo deals with negatives correctly versus standard truncated form 
		Internal.StarCalcData.CurrentStarwheelPeriod := EuclideanModuloINT(Internal.StarCalcData.CurrentStarwheelPeriod, Internal.PeriodCount);
		Internal.StarCalcData.MultiturnPosition := Internal.StarCalcData.StarPosPredict + (INT_TO_REAL(Internal.StarCalcData.CurrentStarwheelPeriod) * Parameters.SyncPar.StarCalcTarget.StarwheelPeriod);	
	END_IF
	
	//Capture old starwheel predict position
	Internal.OldStarPosPredict := Internal.StarCalcData.StarPosPredict;
    
    Internal.TrgPointEnable();
    Internal.TrgPointGetInfo();
    Internal.BarrierCommand();
    Internal.BarrierReadInfo();
    Internal.Recovery();
    FOR Internal.i := 0 TO slMAX_TARGET_IDX DO
        Internal.LastTargetPosition[Internal.i] := Internal.PocketSync[Internal.i].TargetPosition;
        Internal.PocketSync[Internal.i]();
        //Initialize the last target position so that the system
        //does not think that targets have just passed the sync point
        IF Internal.PocketSync[Internal.i].Active AND NOT Internal.LastPocketActiveState[Internal.i] THEN
            Internal.LastTargetPosition[Internal.i] := Internal.PocketSync[Internal.i].TargetPosition;
        END_IF
        Internal.LastPocketActiveState[Internal.i] := Internal.PocketSync[Internal.i].Active;
    END_FOR
    
END_FUNCTION_BLOCK
