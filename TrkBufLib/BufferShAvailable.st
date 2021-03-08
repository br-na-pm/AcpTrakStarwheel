
FUNCTION tbBufferShAvailable

    tbBufferShAvailable := Buffer.ReadIdx <> Buffer.WriteIdx;
    RETURN;
    
END_FUNCTION
