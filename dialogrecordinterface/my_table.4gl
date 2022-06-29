&include "wrapper_include.4gl"
IMPORT reflect

PUBLIC TYPE tabType RECORD
    id INTEGER,
    desc STRING,
    dmy DATE,
    num INTEGER,
    amt DECIMAL(11, 2)
END RECORD



-- Row Functions

PUBLIC FUNCTION row_default(rec tabType INOUT)

    LET rec.id = 1
    LET rec.desc = ""
    LET rec.dmy = TODAY
    LET rec.num = 0
    #LET rec.amt = 123.45
END FUNCTION


PUBLIC FUNCTION row_valid(rec tabType) RETURNS (BOOLEAN, STRING, STRING)

    IF rec.amt * rec.num < 1000 THEN
        RETURN FALSE, "Amount * Price > 1000", "num"
    END IF

    RETURN TRUE, NULL, NULL
END FUNCTION


-- Field Functions

PUBLIC FUNCTION dmy_valid(dmy DATE) RETURNS (BOOLEAN, STRING)

    IF dmy IS NULL THEN
        RETURN FALSE, "Date Must Be Entered"
    END IF
    IF dmy > TODAY THEN
        # Date is OK
    ELSE
        RETURN FALSE, "Date Must Be In The Future"
    END IF

    RETURN TRUE, NULL
END FUNCTION



PUBLIC FUNCTION num_valid(num INTEGER) RETURNS (BOOLEAN, STRING)

    IF num IS NULL THEN
        RETURN FALSE, "Number Must Be Entered"
    END IF
    IF num > 0 THEN
        # Date is OK
    ELSE
        RETURN FALSE, "Number Must Be Greater Than Zero"
    END IF

    RETURN TRUE, NULL
END FUNCTION



PUBLIC FUNCTION amt_valid(amt DECIMAL(11,2)) RETURNS (BOOLEAN, STRING)

    IF amt IS NULL THEN
        RETURN FALSE, "Amount Must Be Entered"
    END IF
    IF amt > 0 THEN
        # Date is OK
    ELSE
        RETURN FALSE, "Amount Must Be Greater Than Zero"
    END IF

    RETURN TRUE, NULL
END FUNCTION

WRAP_FUNCTION_T1_0(row_default, rec, tabType)
WRAP_FUNCTION_T1_FV(dmy_valid, dmy, DATE)
WRAP_FUNCTION_T1_FV(num_valid, num, DATE)
WRAP_FUNCTION_T1_FV(amt_valid, amt, DATE)
WRAP_FUNCTION_T1_RV(row_valid, rec, tabType)




