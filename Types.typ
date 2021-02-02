(*Star Target Calculations*)

TYPE
	slStarCalcTargetParType : 	STRUCT  (*Pocket sync position calculation parameters*)
		StarwheelRadius : REAL; (*Radius of the starwheel in mm*)
		StarwheelPeriod : REAL; (*Period of the starwheel in degrees*)
		StarwheelPocketCount : USINT; (*Number of pockets on the starwheel*)
		SectorTangentPos : REAL; (*Tangent position of the starwheel on the Trak sector*)
		DeltaT : TIME; (*Delay time to compensate in ms*)
	END_STRUCT;
	slStarCalcTargetInternalType : 	STRUCT  (*Internal Data*)
		TargetIndex : USINT; (*Index to generate a position for*)
		PeriodCount : INT; (*Number of periods being monitored*)
		CurrentStarwheelPeriod : INT; (*The current period of the target*)
		MultiturnPosition : REAL; (*The current multiturn position of the starwheel*)
		StarPosPredict : REAL; (*Starwheel predicted position*)
		OldStarPosPredict : REAL; (*Previously recorded predicted starwheel position*)
		AngleOffset : REAL; (*Angle offset of the starwheel compensating for pocket and period*)
		PocketAngle : REAL; (*Angle of the monitored pocket*)
		TrakSyncPosRaw : REAL; (*Raw trak position not accounting for the tangent position*)
		PerformCalculation : BOOL; (*Perform calculation while true*)
		State : slStarCalcTargetStateEnum; (*State of execution*)
	END_STRUCT;
	slStarCalcTargetStateEnum : 
		( (*State of execution*)
		slTARGET_CALC_STATE_IDLE, (*Idle state*)
		slTARGET_CALC_STATE_RUN, (*Run state*)
		slTARGET_CALC_STATE_ERROR (*Error state*)
		);
END_TYPE

(*Star Pocket Sync*)

TYPE
	slStarPocketSyncParType : 	STRUCT  (*Pocket Sync Parameters*)
		StarCalcTarget : slStarCalcTargetParType; (*Calculation parameters*)
		CycPos : slStarPocketCycPosParType; (*Cyclic position parameters*)
		ResizeStart : McAcpTrakShResizeParamType; (*Resize dimensions at start of synchronization*)
		ResizeEnd : McAcpTrakShResizeParamType; (*Resize dimensions at end of synchronization*)
		Release : slStarPocketSyncReleaseParType; (*Release Parameters*)
	END_STRUCT;
	slStarPocketCycPosParType : 	STRUCT  (*Cyclic Position parameters*)
		AdvancedParameters : McAdvMoveCycParType; (*Advanced parameters*)
		InterpolationMode : McIplModeEnum; (*Interpolation mode*)
	END_STRUCT;
	slStarPocketSyncReleaseParType : 	STRUCT  (*Release motion parameters*)
		Position : LREAL; (*Release position on trak*)
		ResizePosition : LREAL; (*Resize position on trak after release*)
		Velocity : REAL; (*Release Velocity*)
		Acceleration : REAL; (*Release Acceleration*)
		Deceleration : REAL; (*Release Deceleration*)
		Jerk : REAL; (*Release Jerk*)
		Direction : McDirectionEnum; (*Release Direction*)
		BufferMode : McBufferModeEnum; (*Release Buffer Mode*)
	END_STRUCT;
	slStarPocketSyncInternalType : 	STRUCT  (*Internal Data*)
		StarCalcTarget : slStarCalcTarget; (*Calculate the sync position*)
		CycPos : MC_BR_ElasticMoveCycPos_AcpTrak; (*Synchronize the shuttle ot the position*)
		ShReadInfo : MC_BR_ShReadInfo_AcpTrak; (*Read shuttle information for its position*)
		MoveVel : MC_BR_ElasticMoveVel_AcpTrak; (*Release the shuttle from synchronization*)
		Resize : MC_BR_ShResize_AcpTrak; (*Resize the shuttle at start*)
		State : slStarPocketSyncStateEnum; (*State of execution*)
	END_STRUCT;
	slStarPocketSyncStateEnum : 
		( (*State of execution*)
		slPOCKET_SYN_STATE_IDLE, (*Idle state*)
		slPOCKET_SYN_STATE_WAIT_SYNC, (*Wait for sync*)
		slPOCKET_SYN_STATE_RESIZE_START, (*Resize shuttle for start of sync*)
		slPOCKET_SYN_STATE_SYNC, (*Perform synchronization*)
		slPOCKET_SYN_STATE_RELEASE, (*Release shuttle*)
		slPOCKET_SYN_STATE_WAIT_RESIZE, (*Wait for the shuttle to reach the position to resize*)
		slPOCKET_SYN_STATE_RESIZE_END, (*Resize shuttle for end of sync*)
		slPOCKET_SYN_STATE_DONE, (*Star wheel operation complete*)
		slPOCKET_SYN_STATE_RESET_FB, (*Reset function blocks*)
		slPOCKET_SYN_STATE_WAIT_NOT_BUSY, (*Wait for function blocks to report not busy*)
		slPOCKET_SYN_STATE_ERROR (*Error state*)
		);
END_TYPE

(*Star Recovery*)

TYPE
	slStarRecoveryParType : 	STRUCT  (*Star recovery parameters*)
		ResizeStart : McAcpTrakShResizeParamType; (*Resize dimensions at start of synchronization*)
		ResizeEnd : McAcpTrakShResizeParamType; (*Resize dimensions at end of synchronization*)
		SyncFurtherInEnabled : BOOL;
		Release : slStarRecoveryParReleaseType; (*Recovery Release Parameters*)
		ProcessPointStartPosition : LREAL; (*Position on the sector of the process point that starts the synchronization*)
		StartOffset : LREAL; (*Offset from the process point before synchronizing*)
		PocketErrorTolerance : LREAL; (*Allowed pocket error tolerance*)
		UserData : slStarRecoveryParUserDataType; (*UserData parameters*)
		Backup : slStarRecoveryParBackupType;
		ShExtentToFront : LREAL;
		SectorTangentPos : REAL;
		MeshZoneStartPos : LREAL; (*Starwheel dimensions*)
		MeshZoneEndPos : LREAL;
	END_STRUCT;
	slStarRecoveryParBackupType : 	STRUCT  (*Recovery Release Parameters*)
		BackupTolerance : LREAL;
		ProcessPointStart : McProcessPointType; (*Position on the sector of the process point that starts the synchronization*)
		MoveToBarAcceleration : REAL;
		MoveToBarDeceleration : REAL;
		MoveToBarVelocity : REAL;
	END_STRUCT;
	slStarRecoveryParUserDataType : 	STRUCT  (*UserData parameters*)
		UserDataAddress : UDINT; (*Pointer to the user data buffer*)
		UserDataSize : UDINT; (*Size of the user data buffer*)
		SrcUserDataWriteAddress : UDINT; (*Source of the data to write to the user data buffer*)
		DstUserDataWriteAddress : UDINT; (*Destination within the user data buffer to write*)
		UserDataWriteSize : UDINT; (*Size of the data to write to the user data buffer*)
	END_STRUCT;
	slStarRecoveryParReleaseType : 	STRUCT  (*Recovery Release Parameters*)
		Position : LREAL; (*Release position of the starwheel*)
		Velocity : REAL; (*Recovery Velocity*)
		Acceleration : REAL; (*Recovery Acceleration*)
		Deceleration : REAL; (*Recovery Deceleration*)
		DestinationSector : McSectorType; (*Recovery Destination Sector*)
	END_STRUCT;
	slStarRecoveryInternalType : 	STRUCT  (*Internal Data*)
		Handle : UDINT; (*Handle to the starwheel internal data*)
		SecGetShuttle : MC_BR_SecGetShuttle_AcpTrak; (*Get shuttles on the sector*)
		ShResize : MC_BR_ShResize_AcpTrak; (*Resize shuttle*)
		RoutedMoveVel : MC_BR_RoutedMoveVel_AcpTrak; (*Send shuttle*)
		RoutedMoveAbs : MC_BR_RoutedMoveAbs_AcpTrak;
		ElasticMoveVel : MC_BR_ElasticMoveVel_AcpTrak; (*Send the shuttle*)
		ElasticMoveAbs : MC_BR_ElasticMoveAbs_AcpTrak;
		ShCopyUserData : MC_BR_ShCopyUserData_AcpTrak; (*Copy user data*)
		AsmGetInfo : MC_BR_AsmGetInfo_AcpTrak; (*Used to see if sectors are being simulated*)
		BarrierCmd : MC_BR_BarrierCommand_AcpTrak;
		OldRemainingCount : UINT; (*Previously recorded remaining count*)
		Data : slStarRecoveryInternalDataType; (*Data*)
		State : slStarRecoveryStateEnum; (*State of execution*)
		i : USINT; (*Index*)
	END_STRUCT;
	slStarRecoveryInternalDataFIType : 	STRUCT 
		CurrentPocketIndex : UINT; (*Current pocket index being evaluated*)
	END_STRUCT;
	slStarRecoveryInternalDataType : 	STRUCT  (*Recovery data*)
		Init : slStarRecoverylDataInitType; (*Initial recovery data*)
		Sync : slStarRecoveryDataSyncType; (*Sync recovery data*)
		Backup : slStarRecoveryDataBackupType; (*Backup recovery data*)
		UserData : slStarRecoveryDataUserDataType;
		SyncFurtherIn : slStarRecoveryInternalDataFIType;
		PocketWidth : LREAL; (*Width of a pocket on the starwheel*)
	END_STRUCT;
	slStarRecoveryDataSyncFurInType : 	STRUCT 
		LastSyncedPocket : USINT; (*Next open pocket available to sync further in*)
		LastSyncedPocketValid : BOOL;
	END_STRUCT;
	slStarRecoveryDataUserDataType : 	STRUCT 
		UserDataWriteCount : UINT;
	END_STRUCT;
	slStarRecoverylDataInitType : 	STRUCT  (*Intial recovery data*)
		ShuttlePos : ARRAY[0..slMAX_SH_IDX_IN_SEC]OF LREAL; (*Shuttle positions found at initialization*)
		ShuttleAxis : ARRAY[0..slMAX_SH_IDX_IN_SEC]OF McAxisType; (*Shuttle axes found at initialization*)
		NumShuttles : UINT; (*Number of shuttles found at initialization*)
		ShuttleEvalCount : USINT; (*Number of shuttles found at initialization that have been evalueated*)
	END_STRUCT;
	slStarRecoveryDataSyncType : 	STRUCT  (*Sync recovery data*)
		PocketEvalIndex : UINT; (*Pocket index to evaluate*)
		PocketEvalIndexValid : BOOL;
		NextClosestPocketIndex : UINT;
		ClosestPocketTaken : BOOL;
		NextClosestPocketTaken : BOOL;
		PocketEvalCount : USINT; (*Number of pockets evaluated*)
		Axes : ARRAY[0..slMAX_SH_IDX_IN_SEC]OF McAxisType; (*Sync axes*)
		ShuttleErrors : ARRAY[0..slMAX_SH_IDX_IN_SEC]OF LREAL;
		PocketIndices : ARRAY[0..slMAX_SH_IDX_IN_SEC]OF UINT; (*Pocket indices assigned to the sync axes*)
		ShuttleError : LREAL; (*Distance from shuttle to pocket*)
		ShuttleErrorNew : LREAL; (*New distance from shuttle to pocket*)
		RecoveredCount : UINT; (*Number of shuttles recovered*)
	END_STRUCT;
	slStarRecoveryDataBackupType : 	STRUCT  (*Backup recovery data*)
		EvalCount : USINT; (*Number of shuttles evaluated*)
		Axes : ARRAY[0..slMAX_SH_IDX_IN_SEC]OF McAxisType; (*Axes found in the backup area*)
		Positions : ARRAY[0..slMAX_SH_IDX_IN_SEC]OF LREAL;
		RecoveredCount : USINT; (*Number of shuttles recovered*)
		IsBeforeBarrier : ARRAY[0..slMAX_SH_IDX_IN_SEC]OF BOOL; (*Indicates if a shuttle is in the backup zone but before the barrier (have to move to gaurantee it won't get stuck at the barrier)*)
		MovedToBarrier : ARRAY[0..slMAX_SH_IDX_IN_SEC]OF BOOL; (*Indicated if a shuttle has been moved to the barrier location*)
		SyncFurtherIn : slStarRecoveryDataBackupFIType;
		Position : LREAL;
		PocketOvertakeIndex : UINT;
	END_STRUCT;
	slStarRecoveryDataBackupFIType : 	STRUCT  (*Sync further in type for backup zone*)
		CurrentPocketIndex : UINT; (*Current pocket index being evaluated*)
		SyncFurtherInFinished : BOOL; (*All shuttles in backup zone have synced to the closest pockets possible*)
	END_STRUCT;
	slStarRecoveryStateEnum : 
		( (*State of execution*)
		slREC_STATE_IDLE, (*Idle state*)
		slREC_STATE_CHECK_SECTOR_SIM,
		slREC_STATE_GET_SHUTTLES, (*Get shuttles on the sector*)
		slREC_STATE_ATTACH_TO_SECTOR,
		slREC_STATE_GET_SHUTTLES_NEXT, (*Get the next shuttle on the sector*)
		slREC_STATE_RELEASE_ZONE_CHECK, (*Check for shuttles in the release zone*)
		slREC_STATE_RELEASE_ZONE_RESIZE, (*Resize shuttles in the release zone*)
		slREC_STATE_RELEASE_ZONE_SEND, (*Send shuttles in the release zone*)
		slREC_STATE_RELEASE_ZONE_NEXT, (*Get the next shuttle in the release zone*)
		slREC_STATE_SYN_ZONE_CHECK, (*Check for shuttles in the sync zone*)
		slREC_STATE_SYN_ZONE_TARGET, (*Assign target for sync*)
		slREC_STATE_SYN_ZONE_RESIZE, (*Resize shuttles*)
		slREC_STATE_SYN_ZONE_NEXT, (*Get the next shuttle in the sync zone*)
		slREC_STATE_BACKUP_ZONE_CHECK, (*Check for shuttles in the backup zone*)
		slREC_STATE_PBACKUP_ZONE_RSIZE, (*Resize shuttles in the backup zone*)
		slREC_STATE_PBACKUP_ZONE_SEND, (*Send shuttles in the backup zone*)
		slREC_STATE_PBACKUP_ZONE_NEXT, (*Get the next shuttle in the backup zone*)
		slREC_STATE_PBCKUP_ZNE_USR_DATAG, (*Get the next shuttle in the backup zone*)
		slREC_STATE_SYN_ZONE_SYNC, (*Sync shuttles in the sync zone*)
		slREC_STATE_SYN_GET_USERDATA, (*Get sync zone userdata*)
		slREC_STATE_SYN_SET_USERDATA, (*Set sync zone userdata*)
		slREC_STATE_BACKUP_ZONE_TARGET, (*Wait for a target for shuttle in backup zone*)
		slREC_STATE_BACKUP_ZONE_BAROPEN, (*Wait for a target for shuttle in backup zone*)
		slREC_STATE_BACKUP_ZONE_MOVBAR,
		slREC_STATE_BACKUP_ZONE_BARCLOSE,
		slREC_STATE_BACKUP_ZONE_SYNC, (*Sync shuttle in backup zone to target*)
		slREC_STATE_BACKUP_ZONE_SYNC_FI, (*Backup zone sync further in*)
		slREC_STATE_BACKUP_GET_USERDATA, (*Get backup zone userdata*)
		slREC_STATE_BACKUP_SET_USERDATA, (*Set backup zone userdata*)
		slREC_STATE_GET_USERDATA,
		slREC_STATE_SET_USERDATA,
		slREC_STATE_FI_WAIT_SHUTTLE, (*Wait for a new shuttle to come by*)
		slREC_STATE_DONE, (*Recovery is complete*)
		slREC_STATE_WAIT_NOT_BUSY, (*Wait for function blocks to report not busy*)
		slREC_STATE_ERROR (*Error state*)
		);
END_TYPE

(*Star Sync*)

TYPE
	slStarSyncParType : 	STRUCT  (*Pocket Queue Parameters*)
		ProcessPointStartPosition : LREAL; (*Position on the sector of the process point that starts the synchronization*)
		StartOffset : LREAL; (*Offset from the process point before synchronizing*)
		SyncPar : slStarPocketSyncParType; (*Synchronization parameters*)
		Recovery : slStarSyncRecoveryParType; (*Star parameters for recovery*)
		Skip : slStarSyncSkipParType; (*Skip parameters*)
		ShExtentToFront : LREAL;
	END_STRUCT;
	slStarSyncRecoveryParType : 	STRUCT  (*Star parameters for recovery*)
		Release : slStarSyncRecoveryReleaseType; (*Release parameters*)
		UserData : slStarRecoveryParUserDataType; (*User data buffer data for successful recovery*)
		SyncFurtherInEnabled : BOOL;
		PocketErrorTolerance : LREAL; (*Pocket error tolerance for resynchronization*)
		MoveToBarVelocity : REAL;
		MoveToBarAcceleration : REAL;
		MoveToBarDeceleration : REAL;
		BackupTolerance : LREAL;
	END_STRUCT;
	slStarSyncRecoveryReleaseType : 	STRUCT  (*Release parameters*)
		Velocity : REAL; (*Recovery Velocity*)
		Acceleration : REAL; (*Recovery Acceleration*)
		Deceleration : REAL; (*Recovery Deceleration*)
		DestinationSector : McSectorType; (*Recovery Destination Sector*)
	END_STRUCT;
	slStarSyncSkipParType : 	STRUCT  (*Skip parameters*)
		NumSkips : USINT; (*Number of skips if skipping is enabled*)
		NumDisabled : USINT; (*Number of disabled pockets*)
		DisabledIdx : ARRAY[0..slMAX_DISABLE_POCKET_IDX]OF USINT; (*Disabled pockets*)
	END_STRUCT;
	slStarSyncInternalType : 	STRUCT  (*Internal Data*)
		TypeID : UDINT; (*Internal data type ID*)
		ErrorID : DINT; (*Last recorded error ID*)
		TrgPointEnable : MC_BR_TrgPointEnable_AcpTrak; (*Enable process point*)
		TrgPointGetInfo : MC_BR_TrgPointGetInfo_AcpTrak; (*Get process point info*)
		BarrierCommand : MC_BR_BarrierCommand_AcpTrak; (*Command barrier to open or close*)
		BarrierReadInfo : MC_BR_BarrierReadInfo_AcpTrak; (*Read barrier info*)
		Recovery : slStarRecovery; (*Recovery process*)
		RecoveryPar : slStarRecoveryParType; (*Recovery parameters*)
		MaxTargetIndex : USINT; (*Highest pocket sync target index used*)
		PocketSync : ARRAY[0..slMAX_TARGET_IDX]OF slStarPocketSync; (*Pocket Sync Targets*)
		LastPocketActiveState : ARRAY[0..slMAX_TARGET_IDX]OF BOOL; (*Capture the last pocket sync active state*)
		LastTargetPosition : ARRAY[0..slMAX_TARGET_IDX]OF REAL; (*Last observed target position for each target*)
		NextSyncTarget : UINT; (*Next target to sync shuttle with*)
		NewDisabledOvertake : BOOL; (*A disabled target position has passed the synchronization threshold*)
		NewOvertakeDetected : BOOL; (*A target position has passed the synchronization threshold*)
		State : slStarSyncStateEnum; (*State of execution*)
		SkipCount : USINT; (*Number of pockets skipped*)
		PocketDisabled : BOOL; (*Current target pocket is disabled*)
		PeriodCount : USINT; (*Number of periods to monitor*)
		i : UINT; (*Index*)
		n : USINT; (*Index*)
		PocketSyncBusy : BOOL; (*Temporary variable to determine if a pocket sync is still busy*)
		PocketSyncError : BOOL; (*Temporary variable to determine if a pocket sync has an error*)
		PocketSyncErrorID : DINT; (*Temporary variable to determine the pocket sync error ID*)
		NextSyncFITarget : UINT; (*Next sync further in target found*)
		SyncFurtherInDone : BOOL;
		MeshZoneStartPos : LREAL;
		MeshZoneEndPos : LREAL;
		PocketWidth : LREAL;
		RecoveryDone : BOOL;
	END_STRUCT;
	slStarSyncStateEnum : 
		( (*State of execution*)
		slSTAR_STATE_IDLE, (*Idle state*)
		slSTAR_STATE_CLOSE_BARRIER, (*Close the barrier*)
		slSTAR_STATE_RECOVER, (*Recover shuttles*)
		slSTAR_STATE_WAIT_TARGET, (*Wait for the next target to arrive*)
		slSTAR_STATE_TICKET_COUNT, (*Read ticket count*)
		slSTAR_STATE_ADD_TICKET, (*Add a ticket to the barrier*)
		slSTAR_STATE_REMOVE_TICKETS,
		slSTAR_STATE_WAIT_SHUTTLE, (*Wait for the next shuttle to arrive*)
		slSTAR_STATE_EVENT_INFO, (*Get event info*)
		slSTAR_STATE_RESET_FB, (*Reset function blocks*)
		slSTAR_STATE_SYNCFI_TICKET_COUNT,
		slSTAR_STATE_SYNCFI_ADD_TICKET,
		slSTAR_STATE_SYNCFI_WAIT_SHUTTLE,
		slSTAR_STATE_OPEN_BARRIER, (*Open the barrier*)
		slSTAR_STATE_WAIT_NOT_BUSY, (*Wait for function blocks to report not busy*)
		slSTAR_STATE_ERROR (*An error occurred*)
		);
END_TYPE

(*Get Shuttle*)

TYPE
	slStarGetShuttleInternalType : 	STRUCT  (*Internal Data*)
		i : USINT; (*Index*)
		Present : BOOL; (*Temporary shuttle presence*)
		Axis : McAxisType; (*Temporary Axis Handle*)
		Position : REAL; (*Temporary Position*)
	END_STRUCT;
END_TYPE

(*Star Sync Diagnostics*)

TYPE
	slStarDiagType : 	STRUCT  (*Output starwheel diagnostics*)
		AngleOffset : ARRAY[0..slMAX_TARGET_IDX]OF REAL; (*Angle offsets of synchronization targets*)
		PocketAngle : ARRAY[0..slMAX_TARGET_IDX]OF REAL; (*Pocket angles of synchronization targets*)
		TrackSyncRaw : ARRAY[0..slMAX_TARGET_IDX]OF REAL; (*Raw synchronization positions of synchronization targets*)
		TrackSyncLast : ARRAY[0..slMAX_TARGET_IDX]OF REAL; (*Last synchronization positions of synchronization targets*)
		TrackSyncPos : ARRAY[0..slMAX_TARGET_IDX]OF REAL; (*Current synchronization positions of synchronization targets*)
		TargetAssigned : ARRAY[0..slMAX_TARGET_IDX]OF BOOL; (*A shuttle has been assigned to the synchronization target*)
		TargetInSync : ARRAY[0..slMAX_TARGET_IDX]OF BOOL; (*A shuttle is in sync with the synchronization target*)
		TargetInSyncLast : ARRAY[0..slMAX_TARGET_IDX]OF BOOL; (*Last In Sync status of synchronization target*)
	END_STRUCT;
	slStarDiagInternalType : 	STRUCT  (*Internal Data*)
		Handle : UDINT; (*Starwheel handle*)
		i : UINT; (*Index*)
		State : slStarDiagStateEnum; (*State of execution*)
	END_STRUCT;
	slStarDiagStateEnum : 
		( (*State of execution*)
		slSTAR_DIAG_STATE_IDLE, (*Idle state*)
		slSTAR_DIAG_STATE_RUNNING, (*Running state*)
		slSTAR_DIAG_STATE_ERROR (*Error state*)
		);
END_TYPE

(*Star Sync Diagnostics Last State Error*)

TYPE
	slStarDiagLastStateInternalType : 	STRUCT  (*Internal data*)
		LastStateData : slStarDiagStateType; (*Last recorded state data*)
		State : slStarDiagStateEnum; (*State of execution*)
		Handle : UDINT; (*Starwheel handle*)
		i : UINT; (*Index*)
		StarRecoveryError : BOOL; (*Last star recovery error status*)
		StarPocketSyncError : ARRAY[0..slMAX_TARGET_IDX]OF BOOL; (*Last star pocket sync error status*)
		StarCalcTargetError : ARRAY[0..slMAX_TARGET_IDX]OF BOOL; (*Last calc target error status*)
	END_STRUCT;
	slStarDiagStateType : 	STRUCT  (*States of the star function blocks*)
		StarSync : slStarSyncStateEnum; (*Star state*)
		StarSyncAtReset : slStarSyncStateEnum; (*Star state before entering reset state*)
		StarRecovery : slStarRecoveryStateEnum; (*Recovery state*)
		StarPocketSync : ARRAY[0..slMAX_TARGET_IDX]OF slStarPocketSyncStateEnum; (*Star Pocket state*)
		StarCalcTarget : ARRAY[0..slMAX_TARGET_IDX]OF slStarCalcTargetStateEnum; (*Calc target state*)
	END_STRUCT;
	slStarDiagErrorIDType : 	STRUCT  (*Error IDs at last error*)
		StarSync : DINT; (*Recorded sync error*)
		StarRecovery : DINT; (*Recorded recovery error*)
		StarPocketSync : ARRAY[0..slMAX_TARGET_IDX]OF DINT; (*Recorded pocket sync error*)
		StarCalcTarget : ARRAY[0..slMAX_TARGET_IDX]OF DINT; (*Recorded calc target error*)
	END_STRUCT;
END_TYPE

(*Star Sync Diagnostices State Trace*)

TYPE
	slStarDiagStateTraceStatesType : 	STRUCT  (*State data*)
		StarSync : slStarDiagStateTraceStarSyncType; (*Star Sync State trace data*)
		StarRecovery : slStarDiagStateTraceStarRecType; (*Star Recovery State trace data*)
		StarPocket : ARRAY[0..slMAX_TARGET_IDX]OF slStarDiagStateTraceStarPockType; (*Star Pocket State trace data*)
		StarCalc : ARRAY[0..slMAX_TARGET_IDX]OF slStarDiagStateTraceStarCalcType;
	END_STRUCT;
	slStarDiagStateTraceStarSyncType : 	STRUCT  (*Star Sync State trace data*)
		LastIndex : USINT; (*Last index with a valid state*)
		State : ARRAY[0..slMAX_STATE_TRACE_IDX]OF slStarSyncStateEnum; (*Star Sync trace data*)
	END_STRUCT;
	slStarDiagStateTraceStarRecType : 	STRUCT  (*Star Recovery State trace data*)
		LastIndex : USINT; (*Last index with a valid state*)
		State : ARRAY[0..slMAX_STATE_TRACE_IDX]OF slStarRecoveryStateEnum; (*Star Recovery trace data*)
	END_STRUCT;
	slStarDiagStateTraceStarPockType : 	STRUCT  (*Star Pocket State trace data*)
		LastIndex : USINT; (*Last index with a valid state*)
		State : ARRAY[0..slMAX_STATE_TRACE_IDX]OF slStarPocketSyncStateEnum; (*Star Pocket trace data*)
	END_STRUCT;
	slStarDiagStateTraceStarCalcType : 	STRUCT  (*Star Calc State trace data*)
		LastIndex : USINT; (*Last index with a valid state*)
		State : ARRAY[0..slMAX_STATE_TRACE_IDX]OF slStarCalcTargetStateEnum; (*Star Calc trace data*)
	END_STRUCT;
	slStarDiagStateTraceInternalType : 	STRUCT  (*Internal Data*)
		Handle : UDINT; (*Starwheel handle*)
		i : UINT; (*Index*)
		State : slStarDiagStateEnum; (*State of execution*)
	END_STRUCT;
END_TYPE
