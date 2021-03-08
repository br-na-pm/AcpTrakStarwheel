
FUNCTION_BLOCK tbRoutedMoveVelTrgBuffer (*Monitor process point and perform routed move velocity before adding shuttle to buffer*)
	VAR_INPUT
		Sector : REFERENCE TO McSectorType; (*Target sector*)
		ProcessPoint : REFERENCE TO McProcessPointType; (*Process point to monitor*)
		Buffer : REFERENCE TO tbAsyncShuttleBufferType; (*Buffer*)
		Parameters : REFERENCE TO tbRtdMvVelTrgBufferParType; (*Parameters*)
		Enable : BOOL; (*Enable shuttle buffer*)
	END_VAR
	VAR_OUTPUT
		Busy : BOOL; (*The function block is busy and must continue to be called*)
		Active : BOOL; (*The buffer is active*)
		Error : BOOL; (*An error occurred*)
		ErrorID : DINT; (*ID of the error that occurred*)
	END_VAR
	VAR
		Internal : tbRtdMvVelTrgBufferInternalType; (*Internal Data*)
	END_VAR
END_FUNCTION_BLOCK

FUNCTION_BLOCK tbElasticMoveAbsPosBuffer (*Monitor a buffer for position to be exceeded and perform elastic move absolute before adding shuttle to buffer*)
	VAR_INPUT
		BufferIn : REFERENCE TO tbAsyncShuttleBufferType; (*Input buffer to monitor*)
		BufferOut : REFERENCE TO tbAsyncShuttleBufferType; (*Output buffer to write*)
		Parameters : REFERENCE TO tbElaMvAbsPosBufferParType; (*Parameters*)
		Enable : BOOL; (*Enable shuttle buffer*)
	END_VAR
	VAR_OUTPUT
		Busy : BOOL; (*The function block is busy and must continue to be called*)
		Active : BOOL; (*The buffer is active*)
		Error : BOOL; (*An error occurred*)
		ErrorID : DINT; (*ID of the error that occurred*)
	END_VAR
	VAR
		Internal : tbElaMvAbsPosBufferInternalType; (*Internal Data*)
	END_VAR
END_FUNCTION_BLOCK

FUNCTION tbBufferAddSh : DINT (*Add shuttle to the buffer*)
	VAR_INPUT
		Buffer : REFERENCE TO tbAsyncShuttleBufferType; (*Buffer to evaluate*)
		Shuttle : REFERENCE TO McAxisType; (*Shuttle to look for*)
	END_VAR
END_FUNCTION

FUNCTION tbBufferGetFirst : DINT (*Get the first shuttle entered in the buffer*)
	VAR_INPUT
		Buffer : REFERENCE TO tbAsyncShuttleBufferType; (*Buffer to evaluate*)
		Shuttle : REFERENCE TO McAxisType; (*First shuttle in the buffer*)
	END_VAR
END_FUNCTION

FUNCTION tbBufferRemoveFirst : DINT (*Remove the first shuttle entered in the buffer*)
	VAR_INPUT
		Buffer : REFERENCE TO tbAsyncShuttleBufferType; (*Buffer to modify*)
	END_VAR
END_FUNCTION

FUNCTION tbShInBuffer : BOOL (*Specified shuttle is in the buffer*)
	VAR_INPUT
		Buffer : REFERENCE TO tbAsyncShuttleBufferType; (*Buffer to evaluate*)
		Shuttle : REFERENCE TO McAxisType; (*Shuttle to look for*)
	END_VAR
	VAR
		i : USINT; (*Index*)
	END_VAR
END_FUNCTION

FUNCTION tbBufferShAvailable : BOOL (*A shuttle is available in the buffer*)
	VAR_INPUT
		Buffer : REFERENCE TO tbAsyncShuttleBufferType; (*Buffer to evaluate*)
	END_VAR
END_FUNCTION
