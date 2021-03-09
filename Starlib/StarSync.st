
FUNCTION_BLOCK slStarSync
	
    //Check for an error on a pocket
    Internal.PocketSyncError := 0;
    Internal.PocketSyncErrorID := ERR_OK;
    FOR Internal.i := 0 TO slMAX_TARGET_IDX DO
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
            IF Internal.PocketSync[Internal.i].TargetPosition >= Parameters.Staging.Position + Parameters.StartOffset AND
                Internal.LastTargetPosition[Internal.i] < Parameters.Staging.Position + Parameters.StartOffset AND
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
        
        slSTAR_STATE_INIT:
            
            Handle := ADR(Internal);
            Internal.TypeID := slSTAR_INTERNAL_TYPE_ID;
            Internal.LandingBufferMan.Buffer := ADR(Internal.LandingBuffer);
            Internal.LandingBufferMan.Parameters := ADR(Internal.LandingBufferPar);
            Internal.StagingBufferMan.BufferIn := ADR(Internal.LandingBuffer);
            Internal.StagingBufferMan.BufferOut := ADR(Internal.StagingBuffer);
            Internal.StagingBufferMan.Parameters := ADR(Internal.StagingBufferPar);
            Internal.State := slSTAR_STATE_IDLE;
            
        slSTAR_STATE_IDLE:
            
            IF Enable THEN
                
                Busy := 1;
                
                Internal.LandingBufferMan.Sector := ADR(Sector);
                Internal.LandingBufferMan.ProcessPoint := ADR(ProcessPoint);
                
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
                
                    Internal.PocketWidth        := brmTWOPI * Parameters.SyncPar.StarCalcTarget.StarwheelRadius / USINT_TO_REAL(Parameters.SyncPar.StarCalcTarget.StarwheelPocketCount);
                    Internal.MeshZoneStartPos   := Parameters.SyncPar.StarCalcTarget.SectorTangentPos - Internal.PocketWidth*0.75;
                    Internal.MeshZoneEndPos     := Parameters.SyncPar.StarCalcTarget.SectorTangentPos + Internal.PocketWidth;
                    
                    brsmemset(ADR(Internal.LandingBuffer), 0, SIZEOF(Internal.LandingBuffer));
                    brsmemset(ADR(Internal.StagingBuffer), 0, SIZEOF(Internal.StagingBuffer));
					                    
                    FOR Internal.i := 0 TO slMAX_TARGET_IDX  DO
                        Internal.PocketSync[Internal.i].TargetIndex := UINT_TO_USINT(Internal.i);
                        Internal.PocketSync[Internal.i].DestinationSector := ADR(DestinationSector);
                        Internal.PocketSync[Internal.i].PeriodCount := Internal.PeriodCount;
                        Internal.PocketSync[Internal.i].Parameters := ADR(Parameters.SyncPar);
                        Internal.PocketSync[Internal.i].ResizeStartParameters := ADR(Parameters.ResizeStart);
                        Internal.PocketSync[Internal.i].ReleaseParameters := ADR(Parameters.Release);
                        Internal.PocketSync[Internal.i].ResizeEndParameters := ADR(Parameters.ResizeEnd);
                        Internal.PocketSync[Internal.i].DestinationParameters := ADR(Parameters.Destination);
                        Internal.PocketSync[Internal.i].CalcData := ADR(Internal.StarCalcData);
                        Internal.PocketSync[Internal.i].Enable := (Internal.i <= Internal.MaxTargetIndex);
                    END_FOR
                    
                    Internal.BarrierCmd.ProcessPoint := ADR(ProcessPoint);
                    Internal.BarrierCmd.Command := mcACPTRAK_BARRIER_CLOSE;
                    Internal.BarrierCmd.Execute := 1;
                    Internal.State := slSTAR_STATE_CLOSE_BARRIER;
                    
                END_IF
                
            END_IF
            
        slSTAR_STATE_CLOSE_BARRIER:
            
            IF Internal.BarrierCmd.Error THEN
                Error := 1;
                ErrorID := Internal.BarrierCmd.ErrorID;
                Internal.State := slSTAR_STATE_RESET_FB;
            ELSIF Internal.BarrierCmd.Done THEN
                Internal.BarrierCmd.Execute := 0;
                Internal.State := slSTAR_STATE_RECOVER;
            END_IF
            
        slSTAR_STATE_RECOVER:
            
            Internal.RecoveryPar.MeshZoneStartPos   := Internal.MeshZoneStartPos;
            Internal.RecoveryPar.SyncFurtherInEnabled   := Parameters.Recovery.SyncFurtherInEnabled;
            Internal.RecoveryPar.MeshZoneEndPos     := Internal.MeshZoneEndPos;
            Internal.RecoveryPar.SectorTangentPos   := Parameters.SyncPar.StarCalcTarget.SectorTangentPos;
            Internal.RecoveryPar.StartOffset := Parameters.StartOffset;
            Internal.RecoveryPar.ResizeStart := Parameters.ResizeStart.ResizeParameters;
            Internal.RecoveryPar.ResizeEnd := Parameters.ResizeEnd.ResizeParameters;
            Internal.RecoveryPar.UserData := Parameters.Recovery.UserData;
            Internal.RecoveryPar.PocketErrorTolerance := Parameters.Recovery.PocketErrorTolerance;
            
            Internal.Recovery.Parameters := ADR(Internal.RecoveryPar);
            Internal.Recovery.StartingParameters := ADR(Parameters.Starting);
            Internal.Recovery.StagingParameters := ADR(Parameters.Staging);
            Internal.Recovery.DestinationParameters := ADR(Parameters.Destination);
            Internal.Recovery.Sector := ADR(Sector);
            Internal.Recovery.DestinationSector := ADR(DestinationSector);
            Internal.Recovery.LandingBuffer := ADR(Internal.LandingBuffer);
            Internal.Recovery.StagingBuffer := ADR(Internal.StagingBuffer);
            Internal.Recovery.Handle := Handle;
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
                Internal.LandingBufferMan.Enable := 1;
                Internal.StagingBufferMan.Enable := 1;
                Internal.NextSyncFITarget   := ClosestSyncPocket(Internal.MeshZoneStartPos, Parameters.Staging.Position + Parameters.StartOffset, Handle);
                Internal.State := slSTAR_STATE_WAIT_BUFFER_START;
            END_IF
            
        slSTAR_STATE_WAIT_BUFFER_START:
            
            IF Internal.LandingBufferMan.Error THEN
                Error := 1;
                ErrorID := Internal.LandingBufferMan.ErrorID;
                Internal.State := slSTAR_STATE_RESET_FB;
            ELSIF Internal.StagingBufferMan.Error THEN
                Error := 1;
                ErrorID := Internal.StagingBufferMan.ErrorID;
                Internal.State := slSTAR_STATE_RESET_FB;
            ELSIF Internal.LandingBufferMan.Active AND Internal.StagingBufferMan.Active THEN
                Internal.BarrierCmd.Command := mcACPTRAK_BARRIER_OPEN;
                Internal.BarrierCmd.Execute := 1;
                Internal.State := slSTAR_STATE_OPEN_BARRIER;
            END_IF
            
        slSTAR_STATE_OPEN_BARRIER:
            
            IF Internal.BarrierCmd.Error THEN
                Error := 1;
                ErrorID := Internal.BarrierCmd.ErrorID;
                Internal.State := slSTAR_STATE_RESET_FB;
            ELSIF Internal.BarrierCmd.Done THEN
                Internal.BarrierCmd.Execute := 0;
                Active := 1;
                Internal.State := slSTAR_STATE_WAIT_TARGET;
            END_IF            
            
        slSTAR_STATE_WAIT_TARGET:
            
            IF NOT Enable THEN
                Internal.State := slSTAR_STATE_RESET_FB;
            ELSIF Internal.LandingBufferMan.Error THEN
                Error := 1;
                ErrorID := Internal.LandingBufferMan.ErrorID;
                Internal.State := slSTAR_STATE_RESET_FB;
            ELSIF Internal.StagingBufferMan.Error THEN
                Error := 1;
                ErrorID := Internal.StagingBufferMan.ErrorID;
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
                        Internal.State := slSTAR_STATE_WAIT_SHUTTLE;
                        Internal.SkipCount := 0;
                    END_IF
                ELSE
                    Internal.State := slSTAR_STATE_WAIT_SHUTTLE;
				END_IF
            END_IF
            
        slSTAR_STATE_WAIT_SHUTTLE:
            
            IF NOT Enable THEN
                Internal.State := slSTAR_STATE_RESET_FB;
            ELSIF Internal.LandingBufferMan.Error THEN
                Error := 1;
                ErrorID := Internal.LandingBufferMan.ErrorID;
                Internal.State := slSTAR_STATE_RESET_FB;
            ELSIF Internal.StagingBufferMan.Error THEN
                Error := 1;
                ErrorID := Internal.StagingBufferMan.ErrorID;
                Internal.State := slSTAR_STATE_RESET_FB;
            ELSIF tbBufferShAvailable(ADR(Internal.StagingBuffer)) THEN
                Internal.State := slSTAR_STATE_SYNC;
            END_IF
        
        slSTAR_STATE_SYNC:
            
            IF Parameters.Recovery.SyncFurtherInEnabled AND NOT Internal.SyncFurtherInDone THEN
                Internal.Status := tbBufferGetFirst(ADR(Internal.StagingBuffer), ADR(Internal.PocketSync[Internal.NextSyncFITarget].Axis));
                IF Internal.Status = ERR_OK THEN
                    Internal.PocketSync[Internal.NextSyncFITarget].Sync := 1;
                    Internal.NextSyncFITarget   := ClosestSyncPocket(Internal.MeshZoneStartPos, Parameters.Staging.Position + Parameters.StartOffset, Handle);
                    IF Internal.NextSyncFITarget = slNO_CLOSEST_POCKET_FOUND THEN
                        Internal.SyncFurtherInDone  := TRUE;
                        Internal.NewOvertakeDetected := 0;
                    END_IF
                ELSE
                    Error := 1;
                    ErrorID := Internal.Status;
                    Internal.State := slSTAR_STATE_RESET_FB;
                END_IF
            ELSE
                Internal.Status := tbBufferGetFirst(ADR(Internal.StagingBuffer), ADR(Internal.PocketSync[Internal.NextSyncTarget].Axis));
                IF Internal.Status = ERR_OK THEN
                    Internal.PocketSync[Internal.NextSyncTarget].Sync := 1;
                    Internal.NewOvertakeDetected := 0;
                    Internal.State := slSTAR_STATE_WAIT_TARGET;
                ELSE
                    Error := 1;
                    ErrorID := Internal.Status;
                    Internal.State := slSTAR_STATE_RESET_FB;
                END_IF
            END_IF
            Internal.Status := tbBufferRemoveFirst(ADR(Internal.StagingBuffer));
            IF Internal.Status = ERR_OK THEN
                Internal.State := slSTAR_STATE_WAIT_TARGET;
            ELSE
                Error := 1;
                ErrorID := Internal.Status;
                Internal.State := slSTAR_STATE_RESET_FB;
            END_IF
            
        slSTAR_STATE_RESET_FB:
            
            Active := 0;
            ReadyForStart := 0;
            Internal.NextSyncTarget := 0;
            Internal.NewOvertakeDetected := 0;
            Internal.LandingBufferMan.Enable := 0;
            Internal.StagingBufferMan.Enable := 0;
            Internal.BarrierCmd.Execute := 0;
            Internal.Recovery.Enable := 0;
            Internal.SyncFurtherInDone  := FALSE;
            Internal.RecoveryDone   := FALSE;
            Internal.ErrorID := ErrorID;
            FOR Internal.i := 0 TO slMAX_TARGET_IDX DO
                Internal.PocketSync[Internal.i].Sync := 0;
                Internal.PocketSync[Internal.i].Enable := 0;
            END_FOR
            Internal.State := slSTAR_STATE_RESET_BARRIER;
            
        slSTAR_STATE_RESET_BARRIER:
            
            Internal.BarrierCmd.Command := mcACPTRAK_BARRIER_OPEN;
            Internal.BarrierCmd.Execute := 1;
            IF Internal.BarrierCmd.Error THEN
                Internal.BarrierCmd.Execute := 0;
                IF NOT Error THEN
                    Error := 1;
                    ErrorID := Internal.BarrierCmd.ErrorID;
                END_IF
                Internal.State := slSTAR_STATE_ERROR;
            ELSIF Internal.BarrierCmd.Done THEN
                Internal.BarrierCmd.Execute := 0;
                Internal.State := slSTAR_STATE_WAIT_NOT_BUSY;
            END_IF            
        
        slSTAR_STATE_WAIT_NOT_BUSY:
            
            Internal.PocketSyncBusy := 0;
            FOR Internal.i := 0 TO slMAX_TARGET_IDX DO
                IF Internal.PocketSync[Internal.i].Busy THEN
                    Internal.PocketSyncBusy := 1;
                END_IF
            END_FOR
            
            IF NOT (Internal.BarrierCmd.Busy OR Internal.PocketSyncBusy OR Internal.LandingBufferMan.Busy OR Internal.StagingBufferMan.Busy OR Internal.Recovery.Busy) THEN
                Error := 0;
                ErrorID := ERR_OK;
                Busy := 0;
                Internal.State := slSTAR_STATE_IDLE;
            END_IF
        
        slSTAR_STATE_ERROR:
        
            IF NOT Enable THEN
                Error := 0;
                ErrorID := ERR_OK;
                Internal.State := slSTAR_STATE_WAIT_NOT_BUSY;
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
    
    Internal.LandingBufferPar.Position := Parameters.Landing.Position;
    Internal.LandingBufferPar.RouteVelocity := Parameters.Landing.Velocity;
    Internal.LandingBufferPar.Velocity := Parameters.Starting.Velocity;
    Internal.LandingBufferPar.Acceleration := Parameters.Landing.Acceleration;
    Internal.LandingBufferPar.Deceleration := Parameters.Landing.Deceleration;
    Internal.LandingBufferPar.AdvancedParameters := Parameters.Landing.AdvancedParameters;
    
    Internal.StagingBufferPar.ArrivalPosition := Parameters.Starting.Position;
    Internal.StagingBufferPar.DestinationPosition := Parameters.Staging.Position;
    Internal.StagingBufferPar.DestinationVelocity := Parameters.Staging.Velocity;
    Internal.StagingBufferPar.DestinationAcceleration := Parameters.Staging.Acceleration;
    Internal.StagingBufferPar.DestinationDeceleration := Parameters.Staging.Deceleration;
    
    Internal.BarrierCmd();
    
    Internal.LandingBufferMan();
    Internal.StagingBufferMan();
    
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
