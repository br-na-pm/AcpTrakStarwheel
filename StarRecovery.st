
FUNCTION_BLOCK slStarRecovery
    
    CASE Internal.State OF
        
        slREC_STATE_IDLE:
            // ----------------------------------------------------------------------- disabled
            
            IF Enable THEN
                Busy := 1;
                Internal.OldRemainingCount := 0;
                IF Handle = 0 THEN
                    Error := 1;
                    ErrorID := slERR_INVALID_HANDLE;
                    Internal.State := slREC_STATE_ERROR;
                ELSE
                    Internal.Handle := Handle;
                    StarInternal ACCESS Internal.Handle;
                    IF StarInternal.TypeID <> slSTAR_INTERNAL_TYPE_ID THEN
                        Error := 1;
                        ErrorID := slERR_INVALID_HANDLE;
                        Internal.State := slREC_STATE_ERROR;
                    ELSE
                        brsmemset(ADR(Internal.Data), 0, SIZEOF(Internal.Data));
                        Internal.AsmGetInfo.Assembly    := ADR(Assembly);
                        Internal.AsmGetInfo.Execute     := TRUE;
                        Internal.State := slREC_STATE_CHECK_SECTOR_SIM;    
                    END_IF
                END_IF
            END_IF
        
        slREC_STATE_CHECK_SECTOR_SIM:
            
            IF Internal.AsmGetInfo.Done THEN
                Internal.SecGetShuttle.Sector := ADR(Sector);
                Internal.SecGetShuttle.Mode := mcACPTRAK_SEARCH_BACKWARD;
                Internal.SecGetShuttle.Enable := TRUE;
                Internal.State := slREC_STATE_GET_SHUTTLES;
            ELSIF Internal.AsmGetInfo.Error THEN
                Internal.AsmGetInfo.Execute := FALSE;
                Error   := TRUE;
                ErrorID := Internal.AsmGetInfo.ErrorID;
                Internal.State := slREC_STATE_ERROR;
            END_IF;
            
        slREC_STATE_GET_SHUTTLES:
            // ----------------------------------------------------------------------- Get shuttles in sector
                
            IF NOT Enable THEN
                Internal.SecGetShuttle.Next := 0;
                Internal.SecGetShuttle.Enable := 0;
                Internal.State := slREC_STATE_WAIT_NOT_BUSY;
            ELSIF Internal.SecGetShuttle.Error THEN
                Internal.SecGetShuttle.Next := 0;
                Internal.SecGetShuttle.Enable := 0;
                Error := 1;
                ErrorID := Internal.SecGetShuttle.ErrorID;
                Internal.State := slREC_STATE_ERROR;
            ELSIF Internal.SecGetShuttle.Valid AND ((Internal.SecGetShuttle.RemainingCount <> Internal.OldRemainingCount) OR (Internal.SecGetShuttle.TotalCount <= 1)) THEN
                Internal.SecGetShuttle.Next := 0;
                IF Internal.SecGetShuttle.TotalCount > 0 THEN
                    Internal.Data.Init.ShuttlePos[Internal.Data.Init.NumShuttles] := Internal.SecGetShuttle.AdditionalInfo.Position;
                    Internal.Data.Init.ShuttleAxis[Internal.Data.Init.NumShuttles] := Internal.SecGetShuttle.Axis;
                    Internal.Data.Init.NumShuttles := Internal.Data.Init.NumShuttles + 1;
                    IF Internal.AsmGetInfo.AssemblyInfo.SimulationOnPlcMode = mcACPTRAK_SIM_STATE_OFF THEN
                        Internal.State := slREC_STATE_GET_SHUTTLES_NEXT;
                    ELSIF Internal.AsmGetInfo.AssemblyInfo.SimulationOnPlcMode = mcACPTRAK_SIM_STATE_ON THEN
                        Internal.RoutedMoveAbs.Sector   := ADR(Sector);
                        Internal.RoutedMoveAbs.Axis     := ADR(Internal.SecGetShuttle.Axis);
                        Internal.RoutedMoveAbs.Position := Internal.SecGetShuttle.AdditionalInfo.Position;
                        Internal.RoutedMoveAbs.Velocity := 1.0;
                        Internal.RoutedMoveAbs.Acceleration := 20.0;
                        Internal.RoutedMoveAbs.Deceleration := 20.0;
                        Internal.RoutedMoveAbs.AdvancedParameters.StartDirection    := mcDIR_UNDEFINED;
                        Internal.RoutedMoveAbs.AdvancedParameters.EndDirection      := mcDIR_UNDEFINED;
                        Internal.RoutedMoveAbs.AdvancedParameters.ShuttleOrientation    := mcDIR_UNDEFINED;
                        Internal.RoutedMoveAbs.AdvancedParameters.PosRelativeTo     := mcACPTRAK_SEC_START;
                        Internal.RoutedMoveAbs.Execute  := TRUE;
                        
                        Internal.State  := slREC_STATE_ATTACH_TO_SECTOR;
                    END_IF;
                ELSE //No shuttles on the sector
                    Internal.SecGetShuttle.Enable := FALSE;
                    Internal.State := slREC_STATE_DONE;
                END_IF
            END_IF
          
        slREC_STATE_ATTACH_TO_SECTOR:
            
            IF Internal.RoutedMoveAbs.Done THEN
                Internal.RoutedMoveAbs.Execute  := FALSE;
                Internal.State  := slREC_STATE_GET_SHUTTLES_NEXT;
            ELSIF Internal.RoutedMoveAbs.Error THEN
                Internal.RoutedMoveAbs.Execute  := FALSE;
                Error   := TRUE;
                ErrorID := Internal.RoutedMoveAbs.ErrorID;
                Internal.State := slREC_STATE_ERROR;
            END_IF;
            
        slREC_STATE_GET_SHUTTLES_NEXT:
            // -----------------------------------------------------------------------
            
            IF NOT Enable THEN
                Internal.SecGetShuttle.Enable := 0;
                Internal.State := slREC_STATE_WAIT_NOT_BUSY;
            ELSIF Internal.SecGetShuttle.Error THEN
                Internal.SecGetShuttle.Enable := 0;
                Error := 1;
                ErrorID := Internal.SecGetShuttle.ErrorID;
                Internal.State := slREC_STATE_ERROR;
            ELSIF Internal.SecGetShuttle.Valid THEN
                IF Internal.SecGetShuttle.RemainingCount > 0 THEN
                    Internal.OldRemainingCount := Internal.SecGetShuttle.RemainingCount;
                    Internal.SecGetShuttle.Next := TRUE;
                    Internal.State := slREC_STATE_GET_SHUTTLES;
                ELSE
                    Internal.SecGetShuttle.Enable := FALSE;
                    Internal.State := slREC_STATE_RELEASE_ZONE_CHECK;
                END_IF
            END_IF
            
        slREC_STATE_RELEASE_ZONE_CHECK:
            // ----------------------------------------------------------------------- Find shuttles in the release zone
            
            IF Enable THEN
                IF Internal.Data.Init.ShuttlePos[Internal.Data.Init.ShuttleEvalCount] >= Parameters.Release.Position THEN
                    Internal.State := slREC_STATE_RELEASE_ZONE_RESIZE;
                ELSE //Go to next section
                    Internal.State := slREC_STATE_SYN_ZONE_CHECK;
                END_IF;
            ELSE
                Internal.State := slREC_STATE_WAIT_NOT_BUSY;
            END_IF
            
        slREC_STATE_RELEASE_ZONE_RESIZE:
            // ----------------------------------------------------------------------- 
                        
            IF Enable THEN
                Internal.ShResize.Axis := ADR(Internal.Data.Init.ShuttleAxis[Internal.Data.Init.ShuttleEvalCount]);
                Internal.ShResize.Command := mcACPTRAK_RESIZE_DIMENSIONS;
                Internal.ShResize.ResizeParameter := Parameters.ResizeEnd;
                Internal.ShResize.Execute := TRUE;
                Internal.State := slREC_STATE_RELEASE_ZONE_SEND; 
            ELSE
                Internal.State := slREC_STATE_WAIT_NOT_BUSY;
            END_IF
                
        slREC_STATE_RELEASE_ZONE_SEND:
            // ----------------------------------------------------------------------- 
    			
            IF NOT Enable THEN
                Internal.ShResize.Execute := 0;
                Internal.State := slREC_STATE_WAIT_NOT_BUSY;
            ELSIF Internal.ShResize.Error THEN
                Internal.ShResize.Execute := 0;
                Error := 1;
                ErrorID := Internal.ShResize.ErrorID;
                Internal.State := slREC_STATE_ERROR;
            ELSIF Internal.ShResize.Done THEN
                Internal.RoutedMoveVel.Axis := ADR(Internal.Data.Init.ShuttleAxis[Internal.Data.Init.ShuttleEvalCount]);
                Internal.RoutedMoveVel.Sector := ADR(Parameters.Release.DestinationSector);
                Internal.RoutedMoveVel.Velocity := Parameters.Release.Velocity;
                Internal.RoutedMoveVel.Acceleration := Parameters.Release.Acceleration;
                Internal.RoutedMoveVel.Deceleration := Parameters.Release.Deceleration;
                Internal.RoutedMoveVel.Execute := TRUE;
                Internal.Data.Init.ShuttleEvalCount := Internal.Data.Init.ShuttleEvalCount + 1;     
                Internal.State := slREC_STATE_RELEASE_ZONE_NEXT;
            END_IF;
                
        slREC_STATE_RELEASE_ZONE_NEXT:
            // ----------------------------------------------------------------------- See if there are anymore shuttles to recover
               
            IF NOT Enable THEN
                Internal.RoutedMoveVel.Execute := 0;
                Internal.State := slREC_STATE_WAIT_NOT_BUSY;
            ELSIF Internal.RoutedMoveVel.Error THEN
                Internal.RoutedMoveVel.Execute := 0;
                Error := 1;
                ErrorID := Internal.RoutedMoveVel.ErrorID;
                Internal.State := slREC_STATE_ERROR;
            ELSIF Internal.RoutedMoveVel.Active THEN
                Internal.RoutedMoveVel.Execute := FALSE;
                IF Internal.Data.Init.ShuttleEvalCount < Internal.Data.Init.NumShuttles THEN
                    Internal.State := slREC_STATE_RELEASE_ZONE_CHECK;
                ELSE
                    Internal.State := slREC_STATE_GET_USERDATA;
                END_IF;
            END_IF
            
        slREC_STATE_SYN_ZONE_CHECK:
            // ----------------------------------------------------------------------- Find shuttles in the sync zone
            
            IF Enable THEN
                IF Internal.Data.Init.ShuttlePos[Internal.Data.Init.ShuttleEvalCount] < Parameters.Release.Position AND 
                   Internal.Data.Init.ShuttlePos[Internal.Data.Init.ShuttleEvalCount] >= (Parameters.ProcessPointStartPosition + Parameters.StartOffset - 0.01) THEN
                    Internal.State := slREC_STATE_SYN_ZONE_TARGET;
                ELSE
                    Internal.State := slREC_STATE_BACKUP_ZONE_CHECK;
                END_IF
            ELSE
                Internal.State := slREC_STATE_WAIT_NOT_BUSY;
            END_IF
                
        slREC_STATE_SYN_ZONE_TARGET:
            // ----------------------------------------------------------------------- Find the closest pocket to it and see if it is in tolerance 
                
            //Find the closest pocket to to the shuttle
            StarInternal ACCESS Internal.Handle;
            IF StarInternal.MaxTargetIndex > 0 THEN
                FOR Internal.i := 0 TO StarInternal.MaxTargetIndex DO
                    Internal.Data.Sync.ShuttleErrorNew := StarInternal.PocketSync[Internal.i].TargetPosition - Internal.Data.Init.ShuttlePos[Internal.Data.Init.ShuttleEvalCount];
                    IF Internal.i > 0 THEN
                        IF ABS(Internal.Data.Sync.ShuttleErrorNew) < ABS(Internal.Data.Sync.ShuttleError) THEN
                            Internal.Data.Sync.PocketEvalIndex := Internal.i;
                            Internal.Data.Sync.ShuttleError := Internal.Data.Sync.ShuttleErrorNew;
                        END_IF
                    ELSE
                        Internal.Data.Sync.PocketEvalIndex := Internal.i;
                        Internal.Data.Sync.ShuttleError := Internal.Data.Sync.ShuttleErrorNew;
                    END_IF
                END_FOR
            ELSE
                Error := 1;
                ErrorID := slERR_NO_TARGET;
                Internal.State := slREC_STATE_ERROR;
            END_IF
            
            //Check that a shuttle is not already synced with the pocket
            IF Internal.Data.Sync.PocketEvalCount > 0 THEN
                FOR Internal.i := 0 TO Internal.Data.Sync.PocketEvalCount - 1 DO
                    IF Internal.Data.Sync.PocketIndices[Internal.i] = Internal.Data.Sync.PocketEvalIndex THEN
                        IF NOT Error THEN
                            Error := 1;
                            ErrorID := slERR_TARGET_ALREADY_SYNCED;
                            Internal.State := slREC_STATE_ERROR;
                        END_IF
                    END_IF
                END_FOR
            END_IF
                
            IF NOT Error THEN
                //Check to see if the pocket is within tolerance and that the pocket index has not already been used
                IF ABS(Internal.Data.Sync.ShuttleError) <= Parameters.PocketErrorTolerance THEN
                    Internal.Data.Sync.Axes[Internal.Data.Sync.PocketEvalCount] := Internal.Data.Init.ShuttleAxis[Internal.Data.Init.ShuttleEvalCount];
                    Internal.State := slREC_STATE_SYN_ZONE_RESIZE;         
                ELSE //Throw error- Closest pocket too far away 
                    Error := 1;
                    ErrorID := slERR_TARGET_OUT_OF_TOL;
                    Internal.State := slREC_STATE_ERROR;
                END_IF;
            END_IF
                
        slREC_STATE_SYN_ZONE_RESIZE:
            // -----------------------------------------------------------------------             
            
            IF Enable THEN
                Internal.Data.Sync.PocketIndices[Internal.Data.Sync.PocketEvalCount] := Internal.Data.Sync.PocketEvalIndex;
        
                Internal.ShResize.Axis := ADR(Internal.Data.Sync.Axes[Internal.Data.Sync.PocketEvalCount]);
                Internal.ShResize.Command := mcACPTRAK_RESIZE_DIMENSIONS;
                Internal.ShResize.ResizeParameter := Parameters.ResizeStart;
                Internal.ShResize.Execute := TRUE;
                
                Internal.Data.Sync.PocketEvalCount := Internal.Data.Sync.PocketEvalCount + 1;
                Internal.Data.Init.ShuttleEvalCount := Internal.Data.Init.ShuttleEvalCount + 1;
                
                Internal.State := slREC_STATE_SYN_ZONE_NEXT;
            ELSE
                Internal.State := slREC_STATE_WAIT_NOT_BUSY;
            END_IF
             
        slREC_STATE_SYN_ZONE_NEXT:
            // ----------------------------------------------------------------------- 
                
            IF NOT Enable THEN
                Internal.ShResize.Execute := 0;
                Internal.State := slREC_STATE_WAIT_NOT_BUSY;
            ELSIF Internal.ShResize.Error THEN
                Internal.ShResize.Execute := 0;
                Error := 1;
                ErrorID := Internal.ShResize.ErrorID;
                Internal.State := slREC_STATE_ERROR;
            ELSIF Internal.ShResize.Done THEN
                Internal.ShResize.Execute := FALSE;
                   
                IF Internal.Data.Init.ShuttleEvalCount < Internal.Data.Init.NumShuttles THEN
                    Internal.State := slREC_STATE_SYN_ZONE_CHECK;
                ELSE
                    Internal.State := slREC_STATE_SYN_ZONE_SYNC;
                END_IF;
                
            END_IF;
         
        slREC_STATE_BACKUP_ZONE_CHECK:
            // ----------------------------------------------------------------------- Look for shuttles in backup zone
            
            IF NOT Enable THEN
                Internal.State := slREC_STATE_WAIT_NOT_BUSY;
            ELSIF Internal.Data.Init.ShuttlePos[Internal.Data.Init.ShuttleEvalCount] < Parameters.ProcessPointStartPosition + Parameters.StartOffset - Parameters.PocketErrorTolerance AND Internal.Data.Init.ShuttlePos[Internal.Data.Init.ShuttleEvalCount] >= Parameters.ProcessPointStartPosition - Parameters.Backup.BackupTolerance THEN 
                IF Internal.Data.Init.ShuttlePos[Internal.Data.Init.ShuttleEvalCount] < Parameters.ProcessPointStartPosition AND Internal.Data.Init.ShuttlePos[Internal.Data.Init.ShuttleEvalCount] >= Parameters.ProcessPointStartPosition - Parameters.Backup.BackupTolerance THEN
	                Internal.Data.Backup.IsBeforeBarrier[Internal.Data.Backup.EvalCount]    := TRUE;
                END_IF;          
                Internal.Data.Backup.Axes[Internal.Data.Backup.EvalCount] := Internal.Data.Init.ShuttleAxis[Internal.Data.Init.ShuttleEvalCount];
                Internal.Data.Backup.EvalCount := Internal.Data.Backup.EvalCount + 1;
                Internal.Data.Init.ShuttleEvalCount := Internal.Data.Init.ShuttleEvalCount + 1;
                IF Internal.Data.Init.ShuttleEvalCount >= Internal.Data.Init.NumShuttles THEN
                    Internal.State := slREC_STATE_SYN_ZONE_SYNC;
                END_IF;
            ELSE //Go to final recovery sequence
                Internal.State := slREC_STATE_PBACKUP_ZONE_RSIZE;
            END_IF;
                
        slREC_STATE_PBACKUP_ZONE_RSIZE:
            
            Internal.ShResize.Axis := ADR(Internal.Data.Init.ShuttleAxis[Internal.Data.Init.ShuttleEvalCount]);
            Internal.ShResize.Command := mcACPTRAK_RESIZE_DIMENSIONS;
            Internal.ShResize.ResizeParameter := Parameters.ResizeEnd;
            Internal.ShResize.Execute := TRUE;
            
            IF NOT Enable THEN
                Internal.ShResize.Execute := 0;
                Internal.State := slREC_STATE_WAIT_NOT_BUSY;
            ELSIF Internal.ShResize.Error THEN
                Internal.ShResize.Execute := 0;
                Error := 1;
                ErrorID := Internal.ShResize.ErrorID;
                Internal.State := slREC_STATE_ERROR;
            ELSIF Internal.ShResize.Done THEN
                Internal.ShResize.Execute := 0;
                Internal.State := slREC_STATE_PBACKUP_ZONE_SEND;
            END_IF
            
        slREC_STATE_PBACKUP_ZONE_SEND:
            // ----------------------------------------------------------------------- 
                
            IF Enable THEN
                Internal.ElasticMoveVel.Axis := ADR(Internal.Data.Init.ShuttleAxis[Internal.Data.Init.ShuttleEvalCount]);
                Internal.ElasticMoveVel.Velocity := Parameters.Backup.MoveToBarVelocity;
                Internal.ElasticMoveVel.Acceleration := Parameters.Backup.MoveToBarAcceleration;
                Internal.ElasticMoveVel.Deceleration := Parameters.Backup.MoveToBarDeceleration;
                Internal.ElasticMoveVel.Execute := TRUE;
                Internal.State := slREC_STATE_PBACKUP_ZONE_NEXT;
            ELSE
                Internal.State := slREC_STATE_WAIT_NOT_BUSY;
            END_IF

        slREC_STATE_PBACKUP_ZONE_NEXT:
            // ----------------------------------------------------------------------- 
                
            IF NOT Enable THEN
                Internal.ElasticMoveVel.Execute := FALSE;
                Internal.State := slREC_STATE_WAIT_NOT_BUSY;
            ELSIF Internal.ElasticMoveVel.Error THEN
                Internal.ElasticMoveVel.Execute := FALSE;
                Error := 1;
                ErrorID := Internal.ElasticMoveVel.ErrorID;
                Internal.State := slREC_STATE_ERROR;
            ELSIF Internal.ElasticMoveVel.Active THEN
                Internal.ElasticMoveVel.Execute := FALSE;
                Internal.Data.Init.ShuttleEvalCount := Internal.Data.Init.ShuttleEvalCount + 1;
                IF Internal.Data.Init.ShuttleEvalCount < Internal.Data.Init.NumShuttles THEN
                    Internal.State := slREC_STATE_PBACKUP_ZONE_RSIZE;
                ELSE
                    Internal.State := slREC_STATE_SYN_ZONE_SYNC;
                END_IF
            END_IF
                
        slREC_STATE_SYN_ZONE_SYNC:
            // ----------------------------------------------------------------------- Sync all of the shuttles 
            
            StarInternal ACCESS Internal.Handle; 
                
            IF NOT Enable THEN
                Internal.State := slREC_STATE_WAIT_NOT_BUSY;
            ELSIF Internal.Data.Sync.RecoveredCount < Internal.Data.Sync.PocketEvalCount THEN
                IF NOT StarInternal.PocketSync[Internal.Data.Sync.PocketIndices[Internal.Data.Sync.RecoveredCount]].Sync THEN
                    StarInternal.PocketSync[Internal.Data.Sync.PocketIndices[Internal.Data.Sync.RecoveredCount]].Axis := Internal.Data.Sync.Axes[Internal.Data.Sync.RecoveredCount];
                    StarInternal.PocketSync[Internal.Data.Sync.PocketIndices[Internal.Data.Sync.RecoveredCount]].Sync := 1;
                    Internal.Data.Sync.RecoveredCount := Internal.Data.Sync.RecoveredCount + 1;
                ELSE
                    Error := 1;
                    ErrorID := slERR_TARGET_ALREADY_SYNCED;
                    Internal.State := slREC_STATE_ERROR;
                END_IF 
            ELSIF Internal.Data.Backup.EvalCount = 0 THEN
                Internal.State := slREC_STATE_GET_USERDATA;
            ELSE
                Internal.State := slREC_STATE_BACKUP_ZONE_TARGET; 
            END_IF
                
        slREC_STATE_BACKUP_ZONE_TARGET:
            // ----------------------------------------------------------------------- wait for pocket to come by
                
            StarInternal ACCESS Internal.Handle; 
            ReadyForStart := 1;
            
            IF NOT Enable THEN
                Internal.State := slREC_STATE_WAIT_NOT_BUSY;
            ELSIF Internal.Data.Backup.IsBeforeBarrier[Internal.Data.Backup.RecoveredCount] AND NOT Internal.Data.Backup.MovedToBarrier[Internal.Data.Backup.RecoveredCount] THEN 
                Internal.BarrierCmd.Command := mcACPTRAK_BARRIER_OPEN;
                Internal.BarrierCmd.ProcessPoint    := ADR(Parameters.Backup.ProcessPointStart);
                Internal.BarrierCmd.Execute := TRUE;
                Internal.State  := slREC_STATE_BACKUP_ZONE_BAROPEN;
            ELSIF StarInternal.NewOvertakeDetected THEN
                StarInternal.NewOvertakeDetected := 0;
                Internal.ShResize.Axis := ADR(Internal.Data.Backup.Axes[Internal.Data.Backup.RecoveredCount]);
                Internal.ShResize.Command := mcACPTRAK_RESIZE_DIMENSIONS;
                Internal.ShResize.ResizeParameter := Parameters.ResizeStart;
                Internal.ShResize.Execute := TRUE;
                Internal.State := slREC_STATE_BACKUP_ZONE_SYNC;
            END_IF;
            
        slREC_STATE_BACKUP_ZONE_BAROPEN:
            
            IF NOT Enable THEN 
                Internal.State := slREC_STATE_WAIT_NOT_BUSY;
            ELSIF Internal.BarrierCmd.Done THEN
                Internal.BarrierCmd.Execute := FALSE;
                Internal.ElasticMoveAbs.Axis    := ADR(Internal.Data.Backup.Axes[Internal.Data.Backup.RecoveredCount]);
                Internal.ElasticMoveAbs.Position    := Parameters.ProcessPointStartPosition;
                Internal.ElasticMoveAbs.Velocity    := Parameters.Backup.MoveToBarVelocity;
                Internal.ElasticMoveAbs.Acceleration    := Parameters.Backup.MoveToBarAcceleration;
                Internal.ElasticMoveAbs.Deceleration    := Parameters.Backup.MoveToBarDeceleration;
                Internal.ElasticMoveAbs.Execute := TRUE;
                Internal.State  := slREC_STATE_BACKUP_ZONE_MOVBAR;
            ELSIF Internal.BarrierCmd.Error THEN
                Internal.BarrierCmd.Execute := FALSE;
                Error := 1;
                ErrorID := Internal.BarrierCmd.ErrorID;
                Internal.State := slREC_STATE_ERROR;
            END_IF;
        
        slREC_STATE_BACKUP_ZONE_MOVBAR:
            
            IF NOT Enable THEN
                Internal.ElasticMoveAbs.Execute := FALSE;
                Internal.State := slREC_STATE_WAIT_NOT_BUSY;
            ELSIF Internal.ElasticMoveAbs.Done THEN
                Internal.ElasticMoveAbs.Execute := FALSE;
                Internal.BarrierCmd.Command := mcACPTRAK_BARRIER_CLOSE;
                Internal.BarrierCmd.ProcessPoint    := ADR(Parameters.Backup.ProcessPointStart);
                Internal.BarrierCmd.Execute := TRUE;
                Internal.State  := slREC_STATE_BACKUP_ZONE_BARCLOSE;
            ELSIF Internal.ElasticMoveAbs.CommandAborted THEN
                Internal.ElasticMoveAbs.Execute := FALSE;
                Error := 1;
                ErrorID := Internal.ElasticMoveAbs.ErrorID;
                Internal.State := slREC_STATE_ERROR;
            ELSIF Internal.ElasticMoveAbs.Error THEN
                Internal.ElasticMoveAbs.Execute := FALSE;
                Error := 1;
                ErrorID := slERR_RECOV_MOVEMNT_ABORTED;
                Internal.State := slREC_STATE_ERROR;
            END_IF;
            
        slREC_STATE_BACKUP_ZONE_BARCLOSE: 
            
            IF NOT Enable THEN 
                Internal.BarrierCmd.Execute := FALSE;
                Internal.State := slREC_STATE_WAIT_NOT_BUSY;
            ELSIF Internal.BarrierCmd.Done THEN
                Internal.BarrierCmd.Execute := FALSE;
                Internal.Data.Backup.MovedToBarrier[Internal.Data.Backup.RecoveredCount]    := TRUE;
                Internal.State  := slREC_STATE_BACKUP_ZONE_TARGET;
            ELSIF Internal.BarrierCmd.Error THEN
                Internal.BarrierCmd.Execute := FALSE;
                Error := 1;
                ErrorID := Internal.BarrierCmd.ErrorID;
                Internal.State := slREC_STATE_ERROR;
            END_IF;
            
        slREC_STATE_BACKUP_ZONE_SYNC:
            // ----------------------------------------------------------------------- 
                
            StarInternal ACCESS Internal.Handle; 
            
            IF NOT Enable THEN
                Internal.ShResize.Execute := FALSE;
                Internal.State := slREC_STATE_WAIT_NOT_BUSY;
            ELSIF Internal.ShResize.Error THEN
                Internal.ShResize.Execute := 0;
                Error := 1;
                ErrorID := Internal.ShResize.ErrorID;
                Internal.State := slREC_STATE_ERROR;
            ELSIF Internal.ShResize.Done THEN
                Internal.ShResize.Execute := 0;
                IF StarInternal.PocketSync[StarInternal.NextSyncTarget].Sync THEN
                    Error := 1;
                    ErrorID := slERR_TARGET_ALREADY_SYNCED;
                    Internal.State := slREC_STATE_ERROR;
                ELSE
                    StarInternal.PocketSync[StarInternal.NextSyncTarget].Axis := Internal.Data.Backup.Axes[Internal.Data.Backup.RecoveredCount];
                    StarInternal.PocketSync[StarInternal.NextSyncTarget].Sync := 1;
                    Internal.Data.Backup.RecoveredCount := Internal.Data.Backup.RecoveredCount + 1;
                    IF Internal.Data.Backup.RecoveredCount < Internal.Data.Backup.EvalCount THEN
                        Internal.State := slREC_STATE_BACKUP_ZONE_TARGET;
                    ELSE
                        Internal.State := slREC_STATE_GET_USERDATA;
                    END_IF
                END_IF
            END_IF
            
        slREC_STATE_GET_USERDATA:
            
            // populates buffer so USERDATA_SET doesn't overwrite other parameters			
            Internal.ShCopyUserData.Axis := ADR(Internal.Data.Init.ShuttleAxis[Internal.Data.UserData.UserDataWriteCount]);
            Internal.ShCopyUserData.DataAddress := Parameters.UserData.UserDataAddress;
            Internal.ShCopyUserData.DataSize := Parameters.UserData.UserDataSize;
            Internal.ShCopyUserData.Mode := mcACPTRAK_USERDATA_GET;
            Internal.ShCopyUserData.Execute := TRUE;
    			
            IF Internal.ShCopyUserData.Error THEN
                Internal.ShCopyUserData.Execute := FALSE;
                Error := 1;
                ErrorID := Internal.ShCopyUserData.ErrorID;
                Internal.State := slREC_STATE_ERROR;
            ELSIF Internal.ShCopyUserData.Done THEN
                Internal.ShCopyUserData.Execute	:= FALSE;
                
                IF Parameters.UserData.UserDataAddress = 0 OR
                    Parameters.UserData.UserDataSize = 0 OR
                    Parameters.UserData.SrcUserDataWriteAddress = 0 OR
                    Parameters.UserData.DstUserDataWriteAddress = 0 OR
                    Parameters.UserData.UserDataWriteSize = 0 THEN
                    
                    Error := 1;
                    ErrorID := slERR_INVALID_USER_DATA;
                    Internal.State := slREC_STATE_ERROR;
                    
                ELSE
                
                    brsmemcpy(Parameters.UserData.DstUserDataWriteAddress, Parameters.UserData.SrcUserDataWriteAddress, Parameters.UserData.UserDataWriteSize);
                    Internal.State := slREC_STATE_SET_USERDATA;
                    
                END_IF
                
            END_IF
            
        slREC_STATE_SET_USERDATA:
            
            StarInternal ACCESS Internal.Handle; 
    			
            Internal.ShCopyUserData.Axis := ADR(Internal.Data.Init.ShuttleAxis[Internal.Data.UserData.UserDataWriteCount]);
            Internal.ShCopyUserData.DataAddress := Parameters.UserData.UserDataAddress;
            Internal.ShCopyUserData.DataSize := Parameters.UserData.UserDataSize;
            Internal.ShCopyUserData.Mode := mcACPTRAK_USERDATA_SET;
            Internal.ShCopyUserData.Execute := TRUE;
    			
            IF Internal.ShCopyUserData.Error THEN
                Internal.ShCopyUserData.Execute := FALSE;
                Error := 1;
                ErrorID := Internal.ShCopyUserData.ErrorID;
                Internal.State := slREC_STATE_ERROR;
            ELSIF Internal.ShCopyUserData.Done THEN
                Internal.ShCopyUserData.Execute	:= FALSE;  
                Internal.Data.UserData.UserDataWriteCount := Internal.Data.UserData.UserDataWriteCount + 1;
                IF Internal.Data.UserData.UserDataWriteCount < Internal.Data.Init.NumShuttles THEN
                    Internal.State := slREC_STATE_GET_USERDATA;
                ELSE
                    Internal.State := slREC_STATE_DONE;
                END_IF
                    
            END_IF
            
        slREC_STATE_DONE:
            
            Done := 1;
            ReadyForStart := 1;
            
            IF NOT Enable THEN
                ReadyForStart := 0;
                Done:= 0;
                Internal.State := slREC_STATE_WAIT_NOT_BUSY;
            END_IF
            
        slREC_STATE_WAIT_NOT_BUSY:
            
            IF NOT Internal.SecGetShuttle.Busy OR Internal.ShResize.Busy OR Internal.RoutedMoveVel.Busy OR Internal.ElasticMoveVel.Busy OR Internal.ShCopyUserData.Busy THEN
                Busy := 0;
                Internal.State := slREC_STATE_IDLE;
            END_IF
        
        slREC_STATE_ERROR:
        
            ReadyForStart := 0;
            
            IF NOT Enable THEN
                Error := 0;
                ErrorID := ERR_OK;
                Internal.State := slREC_STATE_WAIT_NOT_BUSY;
            END_IF
            
    END_CASE
    
    Internal.SecGetShuttle();
    Internal.ShResize();
    Internal.RoutedMoveVel();
    Internal.ElasticMoveVel();
    Internal.ElasticMoveAbs();
    Internal.ShCopyUserData();
    Internal.BarrierCmd();
    Internal.AsmGetInfo();
    Internal.RoutedMoveAbs();
    
END_FUNCTION_BLOCK