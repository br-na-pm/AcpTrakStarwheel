
FUNCTION tbShInBuffer

    i := Buffer.ReadIdx;
    WHILE i <> Buffer.WriteIdx DO
        IF brsmemcmp(ADR(Buffer.Shuttles[i]), ADR(Shuttle), SIZEOF(Buffer.Shuttles[i])) = 0 THEN
            tbShInBuffer := 1;
            RETURN;
        END_IF
        i := (i + 1) MOD (tbMAX_BUF_IDX + 1);
    END_WHILE
    tbShInBuffer := 0;
    RETURN;
    
END_FUNCTION
