(*Buffer Base Type*)

TYPE
	tbAsyncShuttleBufferType : 	STRUCT  (*Asynchronous Buffer data*)
		ReadIdx : USINT; (*Starting index of the ring buffer*)
		WriteIdx : USINT; (*Ending index of the ring buffer*)
		Shuttles : ARRAY[0..tbMAX_BUF_IDX]OF McAxisType; (*Shuttles in the ring buffer*)
	END_STRUCT;
END_TYPE

(*Routed Move Velcity from Trigger Buffer*)

TYPE
	tbRtdMvVelTrgBufferParType : 	STRUCT  (*Parameters*)
		Position : LREAL; (*Position to send shuttle to*)
		RouteVelocity : REAL; (*Velocity of the shuttle before reaching the target position*)
		Velocity : REAL; (*Velocity of the shuttle after reaching the target position*)
		Acceleration : REAL; (*Acceleration of shuttle*)
		Deceleration : REAL; (*Deceleration of shuttle*)
		AdvancedParameters : McAcpTrakAdvRouteParType; (*Advanced move parameters*)
	END_STRUCT;
	tbRtdMvVelTrgBufferInternalType : 	STRUCT  (*Internal Data*)
		State : tbRtdTrgBufferStateEnum; (*State of execution*)
		TrgPointEnable : MC_BR_TrgPointEnable_AcpTrak; (*Enable process point*)
		TrgPointGetInfo : MC_BR_TrgPointGetInfo_AcpTrak; (*Get process point information*)
		RoutedMoveVel : MC_BR_RoutedMoveVel_AcpTrak; (*Move shuttle*)
		Status : DINT; (*Status*)
	END_STRUCT;
	tbRtdTrgBufferStateEnum : 
		( (*State of execution for routed move from trigger*)
		tbRTD_TRG_BUF_STATE_IDLE, (*Idle state*)
		tbRTD_TRG_BUF_STATE_ENABLE_TRIG, (*Enable the process point*)
		tbRTD_TRG_BUF_STATE_GET_INFO, (*Get information from the start process point*)
		tbRTD_TRG_BUF_STATE_MOVE, (*Move shuttle*)
		tbRTD_TRG_BUF_STATE_RESET_FB, (*Reset function blocks*)
		tbRTD_TRG_BUF_STATE_NOT_BUSY, (*Wait for function blocks to report not busy*)
		tbRTD_TRG_BUF_STATE_ERROR (*An error occurred*)
		);
END_TYPE

(*Elastic Move Absolute from Position Buffer*)

TYPE
	tbElaMvAbsPosBufferParType : 	STRUCT  (*Parameters*)
		ArrivalPosition : LREAL; (*Position to wait for shuttles to arrive to*)
		DestinationPosition : LREAL; (*Position to send shuttles to*)
		DestinationVelocity : REAL; (*Velocity to move to destination*)
		DestinationAcceleration : REAL; (*Acceleration to move to destination*)
		DestinationDeceleration : REAL; (*Deceleration to move to destination*)
	END_STRUCT;
	tbElaMvAbsPosBufferInternalType : 	STRUCT  (*Internal Data*)
		State : tbElaPosBufferStateEnum; (*State of execution*)
		ShReadInfo : MC_BR_ShReadInfo_AcpTrak; (*Read shuttle info*)
		ElasticMoveAbs : MC_BR_ElasticMoveAbs_AcpTrak; (*Elastic move absolute*)
		Axis : McAxisType; (*Axis to control*)
		Status : DINT; (*Status*)
	END_STRUCT;
	tbElaPosBufferStateEnum : 
		( (*State of execution*)
		tbELA_POS_BUF_STATE_IDLE, (*Idle state*)
		tbELA_POS_BUF_STATE_WAIT, (*Wait for a shuttle to be available*)
		tbELA_POS_BUF_STATE_POS, (*Wait for shuttle to reach the specified position on the sector*)
		tbELA_POS_BUF_STATE_MOVE, (*Move the shuttle to its position*)
		tbELA_POS_BUF_STATE_RESET_FB, (*Reset function blocks*)
		tbELA_POS_BUF_STATE_NOT_BUSY, (*Wait for function blocks to report not busy*)
		tbELA_POS_BUF_STATE_ERROR (*An error occurred*)
		);
END_TYPE
