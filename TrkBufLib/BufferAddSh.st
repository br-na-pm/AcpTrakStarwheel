
FUNCTION tbBufferAddSh

    IF ((Buffer.WriteIdx + 1) MOD (tbMAX_BUF_IDX + 1)) = Buffer.ReadIdx THEN
       tbBufferAddSh := tbERR_MAX_BUF_IDX;
    ELSE
        //Add the shuttle to the buffer
        brsmemcpy(ADR(Buffer.Shuttles[Buffer.WriteIdx]), ADR(Shuttle), SIZEOF(Buffer.Shuttles[Buffer.WriteIdx]));
        Buffer.WriteIdx := (Buffer.WriteIdx + 1) MOD (tbMAX_BUF_IDX + 1);
        tbBufferAddSh := ERR_OK;
    END_IF
    RETURN;
    
END_FUNCTION
