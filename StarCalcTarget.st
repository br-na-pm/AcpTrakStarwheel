
FUNCTION_BLOCK slStarCalcTarget
    
    IF Enable THEN
        IF Parameters.StarwheelPeriod <> 0 THEN
        
            //Calculate latency compensation
            Internal.StarPosPredict := StarwheelPosition + StarwheelVelocity * TIME_TO_REAL(Parameters.DeltaT) / 1000.0;
            Internal.StarPosPredict := EuclideanModuloFLT(Internal.StarPosPredict, Parameters.StarwheelPeriod);
        
        END_IF
    END_IF
    
    CASE Internal.State OF
        
        slTARGET_CALC_STATE_IDLE:
            
            IF Enable THEN
                
                IF Parameters.StarwheelPeriod = 0 THEN
                    Error := 1;
                    ErrorID := slERR_ZERO_PERIOD;
                    Internal.State := slTARGET_CALC_STATE_ERROR;
                ELSIF Parameters.StarwheelPocketCount = 0 THEN
                    Error := 1;
                    ErrorID := slERR_ZERO_POCKETS;
                    Internal.State := slTARGET_CALC_STATE_ERROR;
                ELSIF Parameters.StarwheelRadius = 0 THEN
                    Error := 1;
                    ErrorID := slERR_ZERO_RADIUS;
                    Internal.State := slTARGET_CALC_STATE_ERROR; 
                ELSE
                    
                    Internal.TargetIndex := TargetIndex;
                    Internal.PeriodCount := PeriodCount;
                
                    //Initialize the last predicted position so that we do not trigger a rollover
                    Internal.OldStarPosPredict := Internal.StarPosPredict;
                
                    Internal.PerformCalculation := 1;
                    Internal.State := slTARGET_CALC_STATE_RUN;
                    
				END_IF
				
			ELSE
				Internal.CurrentStarwheelPeriod	:= 0;                
            END_IF
        
        slTARGET_CALC_STATE_RUN:
            
            IF Parameters.StarwheelPeriod = 0 THEN
                Error := 1;
                ErrorID := slERR_ZERO_PERIOD;
                Internal.PerformCalculation := 0;
                Internal.State := slTARGET_CALC_STATE_ERROR;
            ELSIF Parameters.StarwheelRadius = 0 THEN
                Error := 1;
                ErrorID := slERR_ZERO_RADIUS;
                Internal.PerformCalculation := 0;
                Internal.State := slTARGET_CALC_STATE_ERROR; 
            ELSIF NOT Enable THEN
                Internal.PerformCalculation := 0;
                Internal.State := slTARGET_CALC_STATE_IDLE;
            END_IF
        
        slTARGET_CALC_STATE_ERROR:
        
            IF NOT Enable THEN
                Error := 0;
                ErrorID := ERR_OK;
                Internal.State := slTARGET_CALC_STATE_IDLE;
            END_IF
        
    END_CASE
    
    IF Internal.PerformCalculation THEN
    
        //Detect starwheel position rollover
        IF (Internal.StarPosPredict - Internal.OldStarPosPredict) > (Parameters.StarwheelPeriod / 4.0) THEN //Rollover backwards
            Internal.CurrentStarwheelPeriod := Internal.CurrentStarwheelPeriod - 1;
        ELSIF (Internal.OldStarPosPredict - Internal.StarPosPredict) > (Parameters.StarwheelPeriod / 4.0) THEN //Rollover forwards
            Internal.CurrentStarwheelPeriod := Internal.CurrentStarwheelPeriod + 1;
        END_IF
        
        // Constrain CurrentStarwheelPeriod to {0..Sector.Par.PeriodCount-1}, EuclideanModulo deals with negatives correctly versus standard truncated form 
        Internal.CurrentStarwheelPeriod := EuclideanModuloINT(Internal.CurrentStarwheelPeriod, Internal.PeriodCount);
        Internal.MultiturnPosition := Internal.StarPosPredict + (INT_TO_REAL(Internal.CurrentStarwheelPeriod) * Parameters.StarwheelPeriod);
    	
        Internal.AngleOffset := -1.0 * USINT_TO_REAL(Internal.TargetIndex) * (Parameters.StarwheelPeriod / USINT_TO_REAL(Parameters.StarwheelPocketCount));
        Internal.PocketAngle := EuclideanModuloFLT(Internal.AngleOffset + Internal.MultiturnPosition, Parameters.StarwheelPeriod * INT_TO_REAL(Internal.PeriodCount));
        Internal.PocketAngle := Internal.PocketAngle - (Parameters.StarwheelPeriod * INT_TO_REAL(Internal.PeriodCount - 1));
				
        // Pocket angle * Circumference = Raw track position (missing Sector Offset)
        Internal.TrakSyncPosRaw := Internal.PocketAngle / Parameters.StarwheelPeriod * brmTWOPI * Parameters.StarwheelRadius;
		
        // Raw track position + SectorTangentPos = Actual track position
        TrakPos := Internal.TrakSyncPosRaw + Parameters.SectorTangentPos;

        Valid := 1;
        
    ELSE
        
        Valid := 0;
        TrakPos := 0;
        
    END_IF
    
    //Capture old starwheel predict position
    Internal.OldStarPosPredict := Internal.StarPosPredict;
    
END_FUNCTION_BLOCK