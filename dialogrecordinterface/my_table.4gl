IMPORT reflect

PUBLIC TYPE tabType RECORD  -- would be RECORD LIKE tablename.* when incorporate dataase
    id INTEGER,
    desc STRING,
    dmy DATE,
    num INTEGER,
    amt DECIMAL(11, 2)
END RECORD

DEFINE arr DYNAMIC ARRAY OF tabType
DEFINE rec tabType




-- Row Functions

#+ Default values for a new rows
#+
#+ This function calculates the total amount of all orders for the customer identified by the cust_id number passed as parameter.
#+
#+ @param r tabType THe new row
PUBLIC FUNCTION row_default(r tabType INOUT)

    LET r.id = 1
    LET r.desc = "Lorem Ipsum"
    LET r.dmy = TODAY
    LET r.num = 1
    LET r.amt = 1.23
END FUNCTION

#+ Is the new row valid?
#+
#+ This function calculates if the row is valid A valid row must have value greater than 1000 where value is amt * num
#+
#+ @param r tabType THe new row
#+
#+ @returnType BOOLEAN
#+ @return Is the row valid
#+
#+ @returnType STRING
#+ @return Error message if the row is not valid
#+
#+ @returnType STRING
#+ @return Fieldname as to where to put the cursor
PUBLIC FUNCTION row_valid(r tabType) RETURNS (BOOLEAN, STRING, STRING)

    IF r.amt * r.num < 1000 THEN
        RETURN FALSE, "Amount * Price Must Be > 1000", "num"
    END IF

    RETURN TRUE, NULL, NULL
END FUNCTION


PUBLIC FUNCTION key_valid(r tabType) RETURNS (BOOLEAN, STRING, STRING)
    --TODO replace with test that id is unique
    IF r.id = 0 THEN
        RETURN FALSE, "Id Must Be > 0", "id"
    END IF

    RETURN TRUE, NULL, NULL
END FUNCTION



-- Field Functions

#+ Is the dmy field valid?
#+
#+ A date is valid if it is after today
#+
#+ @param dmy DATE The date field
#+
#+ @returnType BOOLEAN
#+ @return Is the field valid
#+
#+ @returnType STRING
#+ @return Error message if the field is not valid
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



#+ Is the num field valid?
#+
#+ A num is valid if it is greater than zero
#+
#+ @param num INTEGER The number field
#+
#+ @returnType BOOLEAN
#+ @return Is the field valid
#+
#+ @returnType STRING
#+ @return Error message if the field is not valid
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



#+ Is the amt field valid?
#+
#+ An amt is valid if it is greater than zero
#+
#+ @param amt DECIMAL(11,2) The amount field
#+
#+ @returnType BOOLEAN
#+ @return Is the field valid
#+
#+ @returnType STRING
#+ @return Error message if the field is not valid
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



PUBLIC FUNCTION amt_active(r tabType) RETURNS BOOLEAN
    RETURN (r.num MOD 2== 0)
END FUNCTION



PUBLIC FUNCTION amt_visible(r tabType) RETURNS BOOLEAN
    RETURN (r.num MOD 4!= 0)
END FUNCTION

&include "wrapper_include.inc"
WRAP_FUNCTION_T1_0(row_default, rec, tabType)
WRAP_FUNCTION_T1_FV(dmy_valid, dmy, DATE)
WRAP_FUNCTION_T1_FV(num_valid, num, DATE)
WRAP_FUNCTION_T1_FV(amt_valid, amt, DATE)
WRAP_FUNCTION_T1_RV(row_valid, rec, tabType)
WRAP_FUNCTION_T1_RV(key_valid, rec, tabType)
WRAP_FUNCTION_T1_B(amt_active, rec, tabType)
WRAP_FUNCTION_T1_B(amt_visible, rec, tabType)






