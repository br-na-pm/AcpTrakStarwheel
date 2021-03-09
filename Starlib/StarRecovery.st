
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
                        Internal.SecGetShuttle.Sector := ADR(Sector);
                        Internal.SecGetShuttle.Mode := mcACPTRAK_SEARCH_BACKWARD;
                        Internal.SecGetShuttle.Enable := TRUE;
                        Internal.State := slREC_STATE_GET_SHUTTLES;  
                    END_IF
                END_IF
            END_IF
            
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
                    Internal.ShSwitchSector.Sector := ADR(Sector);
                    Internal.ShSwitchSector.Axis := ADR(Internal.SecGetShuttle.Axis);
                    Internal.ShSwitchSector.Execute := TRUE;
                    Internal.State  := slREC_STATE_ATTACH_TO_SECTOR;
                ELSE //No shuttles on the sector
                    Internal.SecGetShuttle.Enable := FALSE;
                    Internal.State := slREC_STATE_DONE;
                END_IF
            END_IF
          
        slREC_STATE_ATTACH_TO_SECTOR:
            
            IF Internal.ShSwitchSector.Done THEN
                Internal.ShSwitchSector.Execute  := FALSE;
                Internal.State  := slREC_STATE_GET_SHUTTLES_NEXT;
            ELSIF Internal.ShSwitchSector.Error THEN
                Internal.ShSwitchSector.Execute  := FALSE;
                Error   := TRUE;
                ErrorID := Internal.ShSwitchSector.ErrorID;
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
                    Internal.State := slREC_STATE_GET_USERDATA;
                END_IF
            END_IF
            
        slREC_STATE_RELEASE_ZONE_CHECK:
            // ----------------------------------------------------------------------- Find shuttles in the release zone
            
            IF Enable THEN
                IF Internal.Data.Init.ShuttlePos[Internal.Data.Init.ShuttleEvalCount] >= Parameters.MeshZoneEndPos THEN
                    Internal.State := slREC_STATE_RELEASE_ZONE_RESIZE;
                ELSE //Go to next section
                    Internal.State := slREC_STATE_MESH_ZONE_CHECK;
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
                Internal.ShResize.Execute := 0;
                Internal.RoutedMoveVel.Axis := ADR(Internal.Data.Init.ShuttleAxis[Internal.Data.Init.ShuttleEvalCount]);
                Internal.RoutedMoveVel.Sector := ADR(DestinationSector);
                Internal.RoutedMoveVel.Position := DestinationParameters.TargetPosition;
                Internal.RoutedMoveVel.Velocity := DestinationParameters.Velocity;
                Internal.RoutedMoveVel.RouteVelocity := DestinationParameters.RouteVelocity;
                Internal.RoutedMoveVel.Acceleration := DestinationParameters.Acceleration;
                Internal.RoutedMoveVel.Deceleration := DestinationParameters.Deceleration;
                Internal.RoutedMoveVel.AdvancedParameters := DestinationParameters.AdvancedParameters;
                
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
                    Internal.State := slREC_STATE_DONE;
                END_IF;
            END_IF
            
        slREC_STATE_MESH_ZONE_CHECK:
            // ----------------------------------------------------------------------- Find shuttles in the sync zone
            
            IF Enable THEN
                IF Internal.Data.Init.ShuttlePos[Internal.Data.Init.ShuttleEvalCount] < Parameters.MeshZoneEndPos AND 
                    Internal.Data.Init.ShuttlePos[Internal.Data.Init.ShuttleEvalCount] >= (Parameters.MeshZoneStartPos) THEN
                    Internal.State := slREC_STATE_MESH_ZONE_TARGET;
                ELSE            
                    //IF Parameters.SyncFurtherInEnabled THEN
                    //    Internal.Data.Sync.PocketEvalIndex    := ClosestSyncPocket(Parameters.MeshZoneStartPos, Parameters.ProcessPointStartPosition + Parameters.StartOffset, Internal.Handle);
                   // END_IF;
                    Internal.State := slREC_STATE_SYN_ZONE_CHECK;
                END_IF
            ELSE
                Internal.State := slREC_STATE_WAIT_NOT_BUSY;
            END_IF
                
        slREC_STATE_MESH_ZONE_TARGET:
            // ----------------------------------------------------------------------- Find the closest pocket to it and see if it is in tolerance 
                
            //TODO: Replace with function
            //Find the closest pocket to to the shuttle
            StarInternal ACCESS Internal.Handle;
            Internal.Data.Mesh.PocketEvalIndex  := 0;
            Internal.Data.Mesh.PocketEvalIndexValid := FALSE;
            Internal.Data.Mesh.NextClosestPocketIndex   := 0;
            IF StarInternal.MaxTargetIndex > 0 THEN
                FOR Internal.i := 0 TO StarInternal.MaxTargetIndex DO
                    Internal.Data.Mesh.ShuttleErrorNew := StarInternal.PocketSync[Internal.i].TargetPosition - Internal.Data.Init.ShuttlePos[Internal.Data.Init.ShuttleEvalCount];
                    IF Internal.i = 0 THEN
                        Internal.Data.Mesh.ShuttleError := Internal.Data.Mesh.ShuttleErrorNew;
                        Internal.Data.Mesh.NextClosestPocketError := StarInternal.PocketSync[1].TargetPosition - Internal.Data.Init.ShuttlePos[Internal.Data.Init.ShuttleEvalCount];
                        Internal.Data.Mesh.NextClosestPocketIndex   := 1;
                    END_IF;
                    //Ignore any pockets that are before the sync zone
                    IF StarInternal.PocketSync[Internal.i].TargetPosition >= StagingParameters.Position + Parameters.StartOffset THEN
                        Internal.Data.Mesh.PocketEvalIndexValid := TRUE;
                        IF ABS(Internal.Data.Mesh.ShuttleErrorNew) < ABS(Internal.Data.Mesh.ShuttleError) THEN
                            Internal.Data.Mesh.NextClosestPocketIndex   := Internal.Data.Mesh.PocketEvalIndex;
                            Internal.Data.Mesh.PocketEvalIndex := Internal.i;
                            Internal.Data.Mesh.NextClosestPocketError := Internal.Data.Mesh.ShuttleError;
                            Internal.Data.Mesh.ShuttleError := Internal.Data.Mesh.ShuttleErrorNew;
                        ELSIF ABS(Internal.Data.Mesh.ShuttleErrorNew) < ABS(Internal.Data.Mesh.NextClosestPocketError) AND Internal.i <> 0 THEN
                            Internal.Data.Mesh.NextClosestPocketIndex   := Internal.i;
                            Internal.Data.Mesh.NextClosestPocketError := Internal.Data.Mesh.ShuttleErrorNew;
                        END_IF
                    END_IF;
                END_FOR
            ELSE
                Error := 1;
                ErrorID := slERR_NO_TARGET;
                Internal.State := slREC_STATE_ERROR;
            END_IF
            
            //Check that a shuttle is not already synced with the pocket
            IF Internal.Data.Mesh.PocketEvalCount > 0 THEN
                FOR Internal.i := 0 TO Internal.Data.Mesh.PocketEvalCount - 1 DO
                    IF Internal.Data.Mesh.PocketIndices[Internal.i] = Internal.Data.Mesh.PocketEvalIndex THEN
                        Internal.Data.Mesh.ClosestPocketTaken   := TRUE;
                    ELSIF Internal.Data.Mesh.PocketIndices[Internal.i] = Internal.Data.Mesh.NextClosestPocketIndex THEN
                        Internal.Data.Mesh.NextClosestPocketTaken   := TRUE;
                    END_IF
                END_FOR
            END_IF
                
            //Check to see if there is another shuttle closer to this pocket, if so- try and sync to the next closest pocket
            IF NOT Internal.Data.Mesh.ClosestPocketTaken THEN
                IF Internal.Data.Mesh.ShuttleError < ABS(StarInternal.PocketSync[Internal.Data.Mesh.PocketEvalIndex].TargetPosition - Internal.Data.Init.ShuttlePos[Internal.Data.Init.ShuttleEvalCount + 1]) THEN
                    Internal.Data.Mesh.PocketIndices[Internal.Data.Mesh.PocketEvalCount] := Internal.Data.Mesh.PocketEvalIndex;
                    Internal.Data.Mesh.Axes[Internal.Data.Mesh.PocketEvalCount] := Internal.Data.Init.ShuttleAxis[Internal.Data.Init.ShuttleEvalCount];
                    Internal.State := slREC_STATE_MESH_ZONE_RESIZE;
                ELSIF NOT Internal.Data.Mesh.NextClosestPocketTaken AND (Internal.Data.Mesh.ShuttleError >= ABS(StarInternal.PocketSync[Internal.Data.Mesh.PocketEvalIndex].TargetPosition - Internal.Data.Init.ShuttlePos[Internal.Data.Init.ShuttleEvalCount + 1])) THEN
                    Internal.Data.Mesh.PocketIndices[Internal.Data.Mesh.PocketEvalCount] := Internal.Data.Mesh.NextClosestPocketIndex;
                    Internal.Data.Mesh.Axes[Internal.Data.Mesh.PocketEvalCount] := Internal.Data.Init.ShuttleAxis[Internal.Data.Init.ShuttleEvalCount];
                    Internal.State := slREC_STATE_MESH_ZONE_RESIZE;
                ELSE
                    Error := 1;
                    ErrorID := slERR_TARGET_ALREADY_SYNCED;
                    Internal.State := slREC_STATE_ERROR;
                END_IF;
            ELSIF NOT Internal.Data.Mesh.NextClosestPocketTaken THEN
                Internal.Data.Mesh.PocketIndices[Internal.Data.Mesh.PocketEvalCount] := Internal.Data.Mesh.NextClosestPocketIndex;
                Internal.Data.Mesh.Axes[Internal.Data.Mesh.PocketEvalCount] := Internal.Data.Init.ShuttleAxis[Internal.Data.Init.ShuttleEvalCount];
                Internal.State := slREC_STATE_MESH_ZONE_RESIZE;
            ELSIF Internal.Data.Mesh.NextClosestPocketTaken THEN
                Error := 1;
                ErrorID := slERR_TARGET_ALREADY_SYNCED;
                Internal.State := slREC_STATE_ERROR;
            END_IF;
                
        slREC_STATE_MESH_ZONE_RESIZE:
            // -----------------------------------------------------------------------             
            
            IF Enable THEN
        
                Internal.ShResize.Axis := ADR(Internal.Data.Mesh.Axes[Internal.Data.Mesh.PocketEvalCount]);
                Internal.ShResize.Command := mcACPTRAK_RESIZE_DIMENSIONS;
                Internal.ShResize.ResizeParameter := Parameters.ResizeStart;
                Internal.ShResize.Execute := TRUE;
                
                Internal.Data.Mesh.PocketEvalCount := Internal.Data.Mesh.PocketEvalCount + 1;
                Internal.Data.Init.ShuttleEvalCount := Internal.Data.Init.ShuttleEvalCount + 1;
                
                Internal.State := slREC_STATE_MESH_ZONE_NEXT;
            ELSE
                Internal.State := slREC_STATE_WAIT_NOT_BUSY;
            END_IF
             
        slREC_STATE_MESH_ZONE_NEXT:
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
                    Internal.State := slREC_STATE_MESH_ZONE_CHECK;
                ELSE
                    Internal.State := slREC_STATE_MESH_ZONE_SYNC;
                END_IF;
                
            END_IF;
         
        slREC_STATE_SYN_ZONE_CHECK:
            
            IF Enable THEN
                IF Internal.Data.Init.ShuttlePos[Internal.Data.Init.ShuttleEvalCount] < Parameters.MeshZoneStartPos AND 
                    Internal.Data.Init.ShuttlePos[Internal.Data.Init.ShuttleEvalCount] >= (StagingParameters.Position + Parameters.StartOffset) THEN
                    Internal.Data.Sync.ShuttlePos[Internal.Data.Sync.PocketEvalCount]   := Internal.Data.Init.ShuttlePos[Internal.Data.Init.ShuttleEvalCount];
                    IF NOT Internal.Data.Sync.SyncFurtherIn.ClosestPocketToMeshFound THEN
                        Internal.Data.Sync.SyncFurtherIn.ClosestPocketToMeshFound   := TRUE;
                        Internal.Data.Sync.PocketEvalIndex    := ClosestSyncPocket(Parameters.MeshZoneStartPos, StagingParameters.Position + Parameters.StartOffset, Internal.Handle);
                        IF Internal.Data.Sync.PocketEvalIndex = slNO_CLOSEST_POCKET_FOUND THEN
	                        Internal.Data.Sync.SyncFurtherIn.NoClosestPocketFound   := TRUE;
                        ELSE
                            //EDGE CASE: Handles the case where a shuttle previously synced to a pocket in the mesh zone moves to the sync zone on power off. This enables the shuttle to still sync into the mesh zone
                            IF Internal.Data.Sync.PocketEvalIndex = 0 THEN
                                Internal.Data.Sync.SyncFurtherIn.FirstPocketInMeshIndex    := StarInternal.MaxTargetIndex;
                            ELSE
                                Internal.Data.Sync.SyncFurtherIn.FirstPocketInMeshIndex    := Internal.Data.Sync.PocketEvalIndex - 1;
                            END_IF;
                            
                            IF Internal.Data.Mesh.PocketEvalCount = 0 THEN
                                //EDGE CASE: Still syncs a shuttle to a pocket 
                                Internal.Data.Sync.SyncFurtherIn.FirstShuttleInMeshError    := ABS(StarInternal.PocketSync[Internal.Data.Sync.SyncFurtherIn.FirstPocketInMeshIndex].TargetPosition - Internal.Data.Init.ShuttlePos[Internal.Data.Init.ShuttleEvalCount]);
                                Internal.Data.Sync.SyncFurtherIn.FirstSyncPocketError       := ABS(StarInternal.PocketSync[Internal.Data.Sync.PocketEvalIndex].TargetPosition - Internal.Data.Init.ShuttlePos[Internal.Data.Init.ShuttleEvalCount]);
                                IF (Internal.Data.Sync.SyncFurtherIn.FirstShuttleInMeshError < Internal.Data.Sync.SyncFurtherIn.FirstSyncPocketError) THEN
                                    Internal.Data.Sync.PocketEvalIndex  := Internal.Data.Sync.SyncFurtherIn.FirstPocketInMeshIndex;
                                END_IF;
                            ELSIF (Internal.Data.Mesh.PocketIndices[Internal.Data.Mesh.PocketEvalCount - 1] <> Internal.Data.Sync.SyncFurtherIn.FirstPocketInMeshIndex) THEN
                                //EDGE CASE: Still syncs a shuttle to a pocket 
                                Internal.Data.Sync.SyncFurtherIn.FirstShuttleInMeshError    := ABS(StarInternal.PocketSync[Internal.Data.Sync.SyncFurtherIn.FirstPocketInMeshIndex].TargetPosition - Internal.Data.Init.ShuttlePos[Internal.Data.Init.ShuttleEvalCount]);
                                Internal.Data.Sync.SyncFurtherIn.FirstSyncPocketError       := ABS(StarInternal.PocketSync[Internal.Data.Sync.PocketEvalIndex].TargetPosition - Internal.Data.Init.ShuttlePos[Internal.Data.Init.ShuttleEvalCount]);
                                IF (Internal.Data.Sync.SyncFurtherIn.FirstShuttleInMeshError < Internal.Data.Sync.SyncFurtherIn.FirstSyncPocketError) THEN
                                    Internal.Data.Sync.PocketEvalIndex  := Internal.Data.Sync.SyncFurtherIn.FirstPocketInMeshIndex;
                                END_IF;
                            END_IF;
                        END_IF;
                    END_IF;
                    IF Internal.Data.Sync.SyncFurtherIn.NoClosestPocketFound THEN
                        Internal.State := slREC_STATE_BACKUP_ZONE_CHECK;
                    ELSE
                        Internal.State := slREC_STATE_SYN_ZONE_TARGET;
                    END_IF;
                ELSE
                    Internal.State := slREC_STATE_BACKUP_ZONE_CHECK;
                END_IF;
            ELSE
                Internal.State := slREC_STATE_WAIT_NOT_BUSY;
            END_IF;
            
        slREC_STATE_SYN_ZONE_TARGET:
            // ----------------------------------------------------------------------- Find the closest pocket to it and see if it is in tolerance 
                
            IF Parameters.SyncFurtherInEnabled THEN
                IF StarInternal.PocketSync[Internal.Data.Sync.PocketEvalIndex].TargetPosition < (StagingParameters.Position + Parameters.StartOffset) THEN
                    Internal.State := slREC_STATE_BACKUP_ZONE_CHECK;
                ELSE
                    Internal.Data.Sync.PocketIndices[Internal.Data.Sync.PocketEvalCount] := Internal.Data.Sync.PocketEvalIndex;
                    IF Internal.Data.Sync.PocketEvalIndex = StarInternal.MaxTargetIndex THEN
                        Internal.Data.Sync.PocketEvalIndex := 0;
                    ELSE
                        Internal.Data.Sync.PocketEvalIndex := Internal.Data.Sync.PocketEvalIndex + 1;
                    END_IF;
                    Internal.Data.Sync.Axes[Internal.Data.Sync.PocketEvalCount] := Internal.Data.Init.ShuttleAxis[Internal.Data.Init.ShuttleEvalCount];
                    Internal.State := slREC_STATE_SYN_ZONE_RESIZE;
                END_IF;
            ELSE
                //TODO: Replace with function
                //Find the closest pocket to to the shuttle
                StarInternal ACCESS Internal.Handle;
                Internal.Data.Sync.PocketEvalIndex  := 0;
                Internal.Data.Sync.PocketEvalIndexValid := FALSE;
                Internal.Data.Sync.NextClosestPocketIndex   := 0;
                IF StarInternal.MaxTargetIndex > 0 THEN
                    FOR Internal.i := 0 TO StarInternal.MaxTargetIndex DO
                        Internal.Data.Sync.ShuttleErrorNew := StarInternal.PocketSync[Internal.i].TargetPosition - Internal.Data.Init.ShuttlePos[Internal.Data.Init.ShuttleEvalCount];
                        IF Internal.i = 0 THEN
                            Internal.Data.Sync.ShuttleError := Internal.Data.Sync.ShuttleErrorNew;
                            Internal.Data.Sync.NextClosestPocketError := StarInternal.PocketSync[1].TargetPosition - Internal.Data.Init.ShuttlePos[Internal.Data.Init.ShuttleEvalCount];
                            Internal.Data.Sync.NextClosestPocketIndex   := 1;
                        END_IF;
                        //Ignore any pockets that are before the sync zone
                        IF ABS(Internal.Data.Sync.ShuttleErrorNew) < ABS(Internal.Data.Sync.ShuttleError) THEN
                            Internal.Data.Sync.NextClosestPocketIndex   := Internal.Data.Sync.PocketEvalIndex;
                            Internal.Data.Sync.PocketEvalIndex := Internal.i;
                            Internal.Data.Sync.NextClosestPocketError := Internal.Data.Sync.ShuttleError;
                            Internal.Data.Sync.ShuttleError := Internal.Data.Sync.ShuttleErrorNew;
                        ELSIF ABS(Internal.Data.Sync.ShuttleErrorNew) < ABS(Internal.Data.Sync.NextClosestPocketError) AND Internal.i <> 0 THEN
                            Internal.Data.Sync.NextClosestPocketIndex   := Internal.i;
                            Internal.Data.Sync.NextClosestPocketError := Internal.Data.Sync.ShuttleErrorNew;
                        END_IF
                    END_FOR
                ELSE
                    Error := 1;
                    ErrorID := slERR_NO_TARGET;
                    Internal.State := slREC_STATE_ERROR;
                END_IF
            
                //Check that a shuttle is not already synced with the pocket
                IF Internal.Data.Mesh.PocketEvalCount > 0 THEN
                    FOR Internal.i := 0 TO Internal.Data.Mesh.PocketEvalCount - 1 DO
                        IF Internal.Data.Mesh.PocketIndices[Internal.i] = Internal.Data.Sync.PocketEvalIndex THEN
                            Internal.Data.Sync.ClosestPocketTaken   := TRUE;
                        ELSIF Internal.Data.Mesh.PocketIndices[Internal.i] = Internal.Data.Sync.NextClosestPocketIndex THEN
                            Internal.Data.Sync.NextClosestPocketTaken   := TRUE;
                        END_IF
                    END_FOR
                END_IF
             
                //Check that a shuttle is not already synced with the pocket
                IF Internal.Data.Sync.PocketEvalCount > 0 THEN
                    FOR Internal.i := 0 TO Internal.Data.Sync.PocketEvalCount - 1 DO
                        IF Internal.Data.Sync.PocketIndices[Internal.i] = Internal.Data.Sync.PocketEvalIndex THEN
                            Internal.Data.Sync.ClosestPocketTaken   := TRUE;
                        ELSIF Internal.Data.Sync.PocketIndices[Internal.i] = Internal.Data.Sync.NextClosestPocketIndex THEN
                            Internal.Data.Sync.NextClosestPocketTaken   := TRUE;
                        END_IF
                    END_FOR
                END_IF
            
                //Check to see if there is another shuttle closer to this pocket, if so- try and sync to the next closest pocket
                IF NOT Internal.Data.Sync.ClosestPocketTaken THEN
                    IF StarInternal.PocketSync[Internal.Data.Sync.PocketEvalIndex].TargetPosition < StagingParameters.Position + Parameters.StartOffset THEN
                        Internal.State := slREC_STATE_BACKUP_ZONE_CHECK;
                    ELSE
                        Internal.Data.Sync.PocketIndices[Internal.Data.Sync.PocketEvalCount] := Internal.Data.Sync.PocketEvalIndex;
                        Internal.Data.Sync.Axes[Internal.Data.Sync.PocketEvalCount] := Internal.Data.Init.ShuttleAxis[Internal.Data.Init.ShuttleEvalCount];
                        Internal.State := slREC_STATE_SYN_ZONE_RESIZE;
                    END_IF;
                ELSIF Internal.Data.Sync.ClosestPocketTaken AND NOT Internal.Data.Sync.NextClosestPocketTaken THEN
                    IF StarInternal.PocketSync[Internal.Data.Sync.NextClosestPocketIndex].TargetPosition < StagingParameters.Position + Parameters.StartOffset THEN
                        Internal.State := slREC_STATE_BACKUP_ZONE_CHECK;
                    ELSE
                        Internal.Data.Sync.PocketIndices[Internal.Data.Sync.PocketEvalCount] := Internal.Data.Sync.NextClosestPocketIndex;
                        Internal.Data.Sync.Axes[Internal.Data.Sync.PocketEvalCount] := Internal.Data.Init.ShuttleAxis[Internal.Data.Init.ShuttleEvalCount];
                        Internal.State := slREC_STATE_SYN_ZONE_RESIZE;
                    END_IF;
                ELSIF Internal.Data.Sync.NextClosestPocketTaken THEN
                    Internal.State := slREC_STATE_BACKUP_ZONE_CHECK;
                END_IF;
            END_IF;            
            
        slREC_STATE_SYN_ZONE_RESIZE:   
            
            IF Enable THEN
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
                    Internal.State := slREC_STATE_MESH_ZONE_SYNC;
                END_IF;
                
            END_IF;           
            
        slREC_STATE_BACKUP_ZONE_CHECK:
            // ----------------------------------------------------------------------- Look for shuttles in backup zone
            
            IF NOT Enable THEN
                Internal.State := slREC_STATE_WAIT_NOT_BUSY;
            ELSIF Internal.Data.Init.ShuttlePos[Internal.Data.Init.ShuttleEvalCount] >= StagingParameters.Position THEN    
                Internal.Data.Backup.Axes[Internal.Data.Backup.EvalCount] := Internal.Data.Init.ShuttleAxis[Internal.Data.Init.ShuttleEvalCount];
                Internal.Data.Backup.Positions[Internal.Data.Backup.EvalCount] := Internal.Data.Init.ShuttlePos[Internal.Data.Init.ShuttleEvalCount];
                Internal.Status := tbBufferAddSh(ADR(StagingBuffer), ADR(Internal.Data.Init.ShuttleAxis[Internal.Data.Init.ShuttleEvalCount]));
                IF Internal.Status = ERR_OK THEN
                    Internal.Data.Backup.EvalCount := Internal.Data.Backup.EvalCount + 1;
                    Internal.Data.Backup.RecoveredCount := Internal.Data.Backup.RecoveredCount + 1;
                    Internal.Data.Init.ShuttleEvalCount := Internal.Data.Init.ShuttleEvalCount + 1;
                    IF Internal.Data.Init.ShuttleEvalCount >= Internal.Data.Init.NumShuttles THEN
                        Internal.State := slREC_STATE_MESH_ZONE_SYNC;
                    END_IF
                ELSE
                    Error := 1;
                    ErrorID := Internal.Status;
                    Internal.State := slREC_STATE_ERROR;
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
                Internal.ElasticMoveAbs.Axis := ADR(Internal.Data.Init.ShuttleAxis[Internal.Data.Init.ShuttleEvalCount]);
                Internal.ElasticMoveAbs.Position := StagingParameters.Position;
                Internal.ElasticMoveAbs.Velocity := StagingParameters.Velocity;
                Internal.ElasticMoveAbs.Acceleration := StagingParameters.Acceleration;
                Internal.ElasticMoveAbs.Deceleration := StagingParameters.Deceleration;
                Internal.ElasticMoveAbs.Execute := TRUE;
                IF Internal.Data.Init.ShuttlePos[Internal.Data.Init.ShuttleEvalCount] >= StartingParameters.Position THEN
                    Internal.Status := tbBufferAddSh(ADR(StagingBuffer), ADR(Internal.Data.Init.ShuttleAxis[Internal.Data.Init.ShuttleEvalCount]));
                ELSE
                    Internal.Status := tbBufferAddSh(ADR(LandingBuffer), ADR(Internal.Data.Init.ShuttleAxis[Internal.Data.Init.ShuttleEvalCount]));
                END_IF
                IF Internal.Status = ERR_OK THEN
                    Internal.State := slREC_STATE_PBACKUP_ZONE_NEXT;
                ELSE
                    Internal.ElasticMoveAbs.Execute := FALSE;
                    Error := 1;
                    ErrorID := Internal.Status;
                    Internal.State := slREC_STATE_ERROR;
                END_IF
            ELSE
                Internal.State := slREC_STATE_WAIT_NOT_BUSY;
            END_IF

        slREC_STATE_PBACKUP_ZONE_NEXT:
            // ----------------------------------------------------------------------- 
                
            IF NOT Enable THEN
                Internal.ElasticMoveAbs.Execute := FALSE;
                Internal.State := slREC_STATE_WAIT_NOT_BUSY;
            ELSIF Internal.ElasticMoveAbs.Error THEN
                Internal.ElasticMoveAbs.Execute := FALSE;
                Error := 1;
                ErrorID := Internal.ElasticMoveAbs.ErrorID;
                Internal.State := slREC_STATE_ERROR;
            ELSIF Internal.ElasticMoveAbs.Active THEN
                Internal.ElasticMoveAbs.Execute := FALSE;
                Internal.Data.Init.ShuttleEvalCount := Internal.Data.Init.ShuttleEvalCount + 1;
                IF Internal.Data.Init.ShuttleEvalCount < Internal.Data.Init.NumShuttles THEN
                    Internal.State := slREC_STATE_PBACKUP_ZONE_RSIZE;
                ELSE
                    Internal.State := slREC_STATE_MESH_ZONE_SYNC;
                END_IF
            END_IF
                
        slREC_STATE_MESH_ZONE_SYNC:
            // ----------------------------------------------------------------------- Sync all of the shuttles 
            
            StarInternal ACCESS Internal.Handle; 
                
            IF NOT Enable THEN
                Internal.State := slREC_STATE_WAIT_NOT_BUSY;
            ELSIF Internal.Data.Mesh.RecoveredCount < Internal.Data.Mesh.PocketEvalCount THEN
                IF NOT StarInternal.PocketSync[Internal.Data.Mesh.PocketIndices[Internal.Data.Mesh.RecoveredCount]].Sync THEN
                    StarInternal.PocketSync[Internal.Data.Mesh.PocketIndices[Internal.Data.Mesh.RecoveredCount]].Axis := Internal.Data.Mesh.Axes[Internal.Data.Mesh.RecoveredCount];
                    StarInternal.PocketSync[Internal.Data.Mesh.PocketIndices[Internal.Data.Mesh.RecoveredCount]].Sync := TRUE;
                    Internal.Data.Mesh.RecoveredCount := Internal.Data.Mesh.RecoveredCount + 1;
                ELSE
                    Error := 1;
                    ErrorID := slERR_TARGET_ALREADY_SYNCED;
                    Internal.State := slREC_STATE_ERROR;
                END_IF 
            ELSIF Internal.Data.Sync.PocketEvalCount <> 0 THEN
                Internal.State := slREC_STATE_SYN_ZONE_SYNC; 
            ELSIF Parameters.SyncFurtherInEnabled AND NOT Internal.Data.Backup.SyncFurtherIn.SyncFurtherInFinished THEN
                Internal.State := slREC_STATE_BACKUP_ZONE_SYNC_FI;
            ELSE
                Internal.State := slREC_STATE_DONE;
            END_IF
            
        slREC_STATE_SYN_ZONE_SYNC:        
            
            ReadyForStart := 1;
            IF NOT Enable THEN
                Internal.State := slREC_STATE_WAIT_NOT_BUSY;
            ELSIF Internal.Data.Sync.RecoveredCount < Internal.Data.Sync.PocketEvalCount THEN
                FOR Internal.i := 0 TO Internal.Data.Sync.PocketEvalCount - 1 DO
                    IF StarInternal.PocketSync[Internal.Data.Sync.PocketIndices[Internal.i]].TargetPosition >= Internal.Data.Sync.ShuttlePos[Internal.i] AND NOT StarInternal.PocketSync[Internal.Data.Sync.PocketIndices[Internal.i]].Sync THEN
                        StarInternal.PocketSync[Internal.Data.Sync.PocketIndices[Internal.i]].Axis := Internal.Data.Sync.Axes[Internal.i];
                        StarInternal.PocketSync[Internal.Data.Sync.PocketIndices[Internal.i]].Sync := TRUE;
                        Internal.Data.Sync.RecoveredCount   := Internal.Data.Sync.RecoveredCount + 1;
                    END_IF;
                END_FOR;
            ELSIF Parameters.SyncFurtherInEnabled AND NOT Internal.Data.Backup.SyncFurtherIn.SyncFurtherInFinished THEN
                Internal.State := slREC_STATE_BACKUP_ZONE_SYNC_FI;
            ELSE
                Internal.State := slREC_STATE_DONE;
            END_IF
        
        slREC_STATE_BACKUP_ZONE_SYNC_FI:
            
            StarInternal ACCESS Internal.Handle; 
            
            Internal.Data.Backup.SyncFurtherIn.CurrentPocketIndex := ClosestSyncPocket(Parameters.MeshZoneStartPos, StagingParameters.Position + Parameters.StartOffset, Internal.Handle);
            IF (Internal.Data.Backup.SyncFurtherIn.CurrentPocketIndex <> slNO_CLOSEST_POCKET_FOUND) AND tbBufferShAvailable(ADR(StagingBuffer)) THEN
                Internal.Status := tbBufferGetFirst(ADR(StagingBuffer), ADR(Internal.Axis));
                IF Internal.Status = ERR_OK THEN
                    StarInternal.PocketSync[Internal.Data.Backup.SyncFurtherIn.CurrentPocketIndex].Axis := Internal.Axis;
                    StarInternal.PocketSync[Internal.Data.Backup.SyncFurtherIn.CurrentPocketIndex].Sync := TRUE;
                    Internal.Status := tbBufferRemoveFirst(ADR(StagingBuffer));
                    IF Internal.Status <> ERR_OK THEN
                        Error := 1;
                        ErrorID := Internal.Status;
                        Internal.State := slREC_STATE_ERROR;
                    END_IF
                ELSE
                    Error := 1;
                    ErrorID := Internal.Status;
                    Internal.State := slREC_STATE_ERROR;
                END_IF
            ELSE
                Internal.Data.Backup.SyncFurtherIn.SyncFurtherInFinished := TRUE;
                Internal.State := slREC_STATE_DONE;
            END_IF;
            
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
                    Internal.State := slREC_STATE_RELEASE_ZONE_CHECK;
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
            
            IF NOT (Internal.SecGetShuttle.Busy OR Internal.ShSwitchSector.Busy OR Internal.ShResize.Busy OR Internal.RoutedMoveVel.Busy OR Internal.ElasticMoveAbs.Busy OR Internal.ShCopyUserData.Busy) THEN
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
    Internal.ShSwitchSector();
    Internal.ShResize();
    Internal.RoutedMoveVel();
    Internal.ElasticMoveAbs();
    Internal.ShCopyUserData();
    
END_FUNCTION_BLOCK