
{REDUND_ERROR} FUNCTION EuclideanModuloFLT : REAL (*Implements Euclidean Modulo*)
	VAR_INPUT
		Dividend : REAL; (*Modulo Dividend*)
		Divisor : REAL; (*Modulo Divisor*)
	END_VAR
END_FUNCTION

{REDUND_ERROR} FUNCTION EuclideanModuloINT : INT (*Implements Euclidean Modulo*) (*$GROUP=User,$CAT=User,$GROUPICON=User.png,$CATICON=User.png*)
	VAR_INPUT
		Dividend : INT; (*Modulo Dividend*)
		Divisor : INT; (*Modulo Divisor*)
	END_VAR
END_FUNCTION

{REDUND_ERROR} FUNCTION ClosestSyncPocket : UINT (*Finds the closest pocket to the tangent point of the starwheel that a shuttle can sync to*) (*$GROUP=User,$CAT=User,$GROUPICON=User.png,$CATICON=User.png*)
	VAR_INPUT
		MeshZoneStartPos : LREAL; (*Tangent point of the starwheel*)
		SyncZoneStartPos : LREAL; (*Start of the sync zone on the starwheel sector*)
		Handle : UDINT; (*Starwheel internal data handle*)
	END_VAR
	VAR
		StarInternal : REFERENCE TO slStarSyncInternalType; (*Star Internal Data*)
		TangentPocketLocationError : LREAL; (*Error of the current evaluation pocket*)
		TangentPocketLocationErrorNew : LREAL;
		FirstSyncPocketLocationError : LREAL; (*Error of the current evaluation pocket*)
		FirstSyncPocketLocationErrorNew : LREAL;
		TangentPocketIndex : UINT;
		FirstSyncPocketIndex : UINT;
		CurrentEvalPocket : UINT;
		PrevEvalPocket : UINT;
		CurrentEvalPocketValid : BOOL;
		i : USINT;
	END_VAR
END_FUNCTION

{REDUND_ERROR} FUNCTION PocketOvertakeDetect : UINT (*Returns the pocket index of pocket that has crossed a point input to the function*) (*$GROUP=User,$CAT=User,$GROUPICON=User.png,$CATICON=User.png*)
	VAR_INPUT
		Handle : UDINT; (*Starwheel internal data handle*)
		Position : LREAL; (*Position that is being monitored for an overtake*)
	END_VAR
	VAR
		StarInternal : REFERENCE TO slStarSyncInternalType;
		i : UINT;
	END_VAR
END_FUNCTION

{REDUND_ERROR} FUNCTION FindClosestPocketSyncZone : UINT (*Finds the closest pocket to a shuttle that is in the sync zone*) (*$GROUP=User,$CAT=User,$GROUPICON=User.png,$CATICON=User.png*)
	VAR_INPUT
		Handle : UDINT;
	END_VAR
	VAR
		StarInternal : REFERENCE TO slStarSyncInternalType;
		ClosestPocketIndex : UINT;
		NextClosestPocketIndex : UINT;
		ShuttleError : LREAL;
		ShuttleErrorNew : LREAL;
		i : UINT;
	END_VAR
END_FUNCTION

FUNCTION_BLOCK slStarCalcTarget (*Synchronous function block that calculates the position of the sync positions*)
	VAR_INPUT
		TargetIndex : USINT; (*Index to generate a position for*)
		PeriodCount : USINT; (*Number of periods to monitor*)
		Enable : BOOL; (*Calculate when true*)
		StarwheelPosition : {REDUND_UNREPLICABLE} REAL; (*Position of the starwheel in degrees*)
		StarwheelVelocity : {REDUND_UNREPLICABLE} REAL; (*Velocity of the starwheel in degrees per second*)
		Parameters : REFERENCE TO slStarCalcTargetParType; (*Calculation parameters*)
	END_VAR
	VAR_OUTPUT
		Valid : BOOL; (*Position is valid*)
		TrakPos : REAL; (*Position on the trak*)
		Error : BOOL; (*An error occurred*)
		ErrorID : DINT; (*ID of the error that occurred*)
	END_VAR
	VAR
		Internal : slStarCalcTargetInternalType; (*Internal data*)
	END_VAR
END_FUNCTION_BLOCK

FUNCTION_BLOCK slStarPocketSync (*Synchronize a shuttle with a pocket*)
	VAR_INPUT
		TargetIndex : USINT; (*Index to generate a position for*)
		PeriodCount : USINT; (*Number of periods to monitor*)
		Enable : BOOL; (*Enable syncing to the pocket*)
		Axis : {REDUND_UNREPLICABLE} McAxisType; (*Shuttle to sync with pocket*)
		Sync : BOOL; (*Synchronize on rising edge*)
		Parameters : REFERENCE TO slStarPocketSyncParType; (*Pocket Sync Parameters*)
		StarwheelPosition : REAL; (*Position of the starwheel in degrees*)
		StarwheelVelocity : REAL; (*Velocity of the starwheel in degrees per second*)
	END_VAR
	VAR_OUTPUT
		Busy : BOOL; (*Function Block is busy and must continue to be called*)
		Active : BOOL; (*The function block is active and ready for sync*)
		InSync : BOOL; (*The shuttle is in synchronization with the target position*)
		Done : BOOL; (*The shuttle is through the starwheel*)
		TargetPosition : REAL; (*The current target position*)
		Error : BOOL; (*An error occurred*)
		ErrorID : DINT; (*ID of the error that occurred*)
	END_VAR
	VAR
		Internal : slStarPocketSyncInternalType; (*Internal Data*)
	END_VAR
END_FUNCTION_BLOCK

FUNCTION_BLOCK slStarSync (*Star synchronization*)
	VAR_INPUT
		Sector : REFERENCE TO McSectorType; (*Sector for starwheel*)
		Assembly : REFERENCE TO McAssemblyType;
		ProcessPointStart : REFERENCE TO McProcessPointType; (*Process point at the start of the sync*)
		Enable : BOOL; (*Enable starwheel*)
		SkipPockets : BOOL; (*Skip pockets when true*)
		DisablePockets : BOOL; (*Disable configured pockets when true*)
		StarwheelPosition : {REDUND_UNREPLICABLE} REAL; (*Position of the starwheel in degrees*)
		StarwheelVelocity : {REDUND_UNREPLICABLE} REAL; (*Velocity of the starwheel in degrees per second*)
		Parameters : REFERENCE TO slStarSyncParType; (*Queue parameters*)
	END_VAR
	VAR_OUTPUT
		Busy : BOOL; (*The function block is busy and must continue to be called*)
		ReadyForStart : BOOL; (*The function block is ready for starwheel movement*)
		Active : BOOL; (*Starwheel is active*)
		Handle : UDINT; (*Starwheel internal data handle*)
		Error : BOOL; (*An error occurred*)
		ErrorID : DINT; (*ID of the error that occurred*)
	END_VAR
	VAR
		Internal : slStarSyncInternalType; (*Internal Data*)
	END_VAR
END_FUNCTION_BLOCK

FUNCTION_BLOCK slStarRecovery (*Recover shuttles in the starwheel*)
	VAR_INPUT
		Sector : REFERENCE TO McSectorType; (*Sector for starwheel*)
		Assembly : REFERENCE TO McAssemblyType;
		Parameters : REFERENCE TO slStarRecoveryParType; (*Starwheel recovery parameters*)
		Handle : UDINT; (*Starwheel internal data handle*)
		Enable : BOOL; (*Enable recovery process*)
	END_VAR
	VAR_OUTPUT
		Busy : BOOL; (*The function block is busy and must continue to be called*)
		ReadyForStart : BOOL; (*The function block is ready for starwheel movement*)
		Done : BOOL; (*Recovery is complete*)
		Error : BOOL; (*An error occurred*)
		ErrorID : DINT; (*ID of the error that occurred*)
	END_VAR
	VAR
		Internal : slStarRecoveryInternalType; (*Internal Data*)
		StarInternal : REFERENCE TO slStarSyncInternalType; (*Star Internal Data*)
	END_VAR
END_FUNCTION_BLOCK

FUNCTION_BLOCK slStarGetShuttle (*Get the shuttle in a starwheel that is between two positions*)
	VAR_INPUT
		TrakPositionStart : REAL; (*Start position to look for the shuttle*)
		TrakPositionEnd : REAL; (*End position to look for the shuttle*)
		Handle : UDINT; (*Handle of the star sync to evaluate*)
		Enable : BOOL; (*Execute on a rising edge*)
	END_VAR
	VAR_OUTPUT
		Valid : BOOL; (*The shuttle and position are valid*)
		ShuttlePresent : BOOL; (*A shuttle is present between the two positions*)
		Axis : McAxisType; (*Shuttle Axis*)
		Position : REAL; (*Target position of the shuttle*)
		Error : BOOL; (*An error occurred*)
		ErrorID : DINT; (*ID of the error that occurred*)
	END_VAR
	VAR
		Internal : slStarGetShuttleInternalType; (*Internal Data*)
		StarInternal : REFERENCE TO slStarSyncInternalType; (*Star Internal Data*)
	END_VAR
END_FUNCTION_BLOCK

FUNCTION_BLOCK slStarDiag (*Star diagnostics*)
	VAR_INPUT
		Handle : UDINT; (*Starwheel handle*)
		Enable : BOOL; (*Enable outputting diagnostics*)
	END_VAR
	VAR_OUTPUT
		Busy : BOOL; (*The function block is busy and must continue to be called*)
		Valid : BOOL; (*The Diagnostic data is valid*)
		Diag : slStarDiagType; (*Diagnostic information*)
		Error : BOOL; (*An error occurred*)
		ErrorID : DINT; (*ID of the error that occurred*)
	END_VAR
	VAR
		Internal : slStarDiagInternalType; (*Internal Handle*)
		StarInternal : REFERENCE TO slStarSyncInternalType; (*Star Internal Data*)
	END_VAR
END_FUNCTION_BLOCK

FUNCTION_BLOCK slStarDiagLastStateError (*Get the last state before an error*)
	VAR_INPUT
		Handle : UDINT; (*Starwheel handle*)
		Enable : BOOL; (*Enable capturing the last state before an error*)
	END_VAR
	VAR_OUTPUT
		Busy : BOOL; (*The function block is busy and must continue to be called*)
		Valid : BOOL; (*The Diagnostic data is valid*)
		LastStates : slStarDiagStateType; (*Last states recorded before an error*)
		ErrorIDs : slStarDiagErrorIDType; (*Error IDs recorded on the last error*)
		Error : BOOL; (*An error occurred*)
		ErrorID : DINT; (*ID of the error that occurred*)
	END_VAR
	VAR
		Internal : slStarDiagLastStateInternalType; (*Internal Handle*)
		StarInternal : REFERENCE TO slStarSyncInternalType; (*Star Internal Data*)
	END_VAR
END_FUNCTION_BLOCK

FUNCTION_BLOCK slStarDiagStateTrace (*Trace the starwheel states*)
	VAR_INPUT
		Handle : UDINT; (*Starwheel handle*)
		Enable : BOOL; (*Enable capturing the last state before an error*)
	END_VAR
	VAR_OUTPUT
		Busy : BOOL; (*The function block is busy and must continue to be called*)
		Valid : BOOL; (*The State data is valid*)
		StateData : slStarDiagStateTraceStatesType; (*State trace*)
		Error : BOOL; (*An error occurred*)
		ErrorID : DINT; (*ID of the error that occurred*)
	END_VAR
	VAR
		Internal : slStarDiagStateTraceInternalType; (*Internal Handle*)
		StarInternal : REFERENCE TO slStarSyncInternalType; (*Star Internal Data*)
	END_VAR
END_FUNCTION_BLOCK
