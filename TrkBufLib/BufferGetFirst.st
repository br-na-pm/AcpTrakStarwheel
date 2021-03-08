
FUNCTION tbBufferGetFirst

    IF tbBufferShAvailable(ADR(Buffer)) THEN
        brsmemcpy(ADR(Shuttle), ADR(Buffer.Shuttles[Buffer.ReadIdx]), SIZEOF(Shuttle));
        tbBufferGetFirst := ERR_OK;
    ELSE
        tbBufferGetFirst := tbERR_NO_SH_IN_BUFFER;
    END_IF
    RETURN;
    
END_FUNCTION
