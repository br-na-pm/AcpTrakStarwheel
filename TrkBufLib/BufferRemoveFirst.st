
FUNCTION tbBufferRemoveFirst

    IF tbBufferShAvailable(ADR(Buffer)) THEN
        Buffer.ReadIdx := (Buffer.ReadIdx + 1) MOD (tbMAX_BUF_IDX + 1);
        tbBufferRemoveFirst := ERR_OK;
    ELSE
        tbBufferRemoveFirst := tbERR_NO_SH_IN_BUFFER;
    END_IF
    RETURN;
    
END_FUNCTION
