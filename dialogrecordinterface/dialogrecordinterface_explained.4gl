-- Attempt at simpler version of above in order to explain the issue
-- Essentially the parameter for the reference functions needs to be a reflect.value when I would 
-- rather code it as the parameter type.
-- If ANYTYPE / ANYRECORD were available then these might be able to be used
-- instead need the wrapper function to map variable to reflect value etc

IMPORT reflect

TYPE validate_function_type FUNCTION (rv reflect.Value) RETURNS (BOOLEAN, STRING)

DEFINE field_validate_list DICTIONARY OF validate_function_type


MAIN
    -- Register the validation function
    LET field_validate_list["string"] = FUNCTION _string_valid
    LET field_validate_list["number"] = FUNCTION _number_valid
    LET field_validate_list["string"] = FUNCTION _date_valid




END MAIN



FUNCTION string_valid(s)
DEFINE s STRING
    IF s.getLength() > 3 THEN
        #OK
    ELSE
        RETURN FALSE,"Must be at least four characters" 
    END IF
    RETURN TRUE, ""
END FUNCTION

FUNCTION number_valid(n)
DEFINE n INTEGER
    IF n >=100 THEN
        #OK
    ELSE
        RETURN FALSE,"Must be at least 100"
    END IF
    RETURN TRUE, ""
END FUNCTION

FUNCTION date_valid(d)
DEFINE d DATE
    IF d> TODAY THEN
        #OK
    ELSE
        RETURN FALSE, "Must be after today"
    END IF
    RETURN TRUE, ""
END FUNCTION







&define WRAP_FUNCTION_T1_FV(p1,p2,p3) FUNCTION _ ## p1(rv reflect.Value) RETURNS (BOOLEAN, STRING) \
DEFINE ok BOOLEAN \
DEFINE error_text STRING \
DEFINE p2 p3 \
    CALL rv.assignToVariable(p2) \
    CALL p1(p2) RETURNING ok, error_text \
    RETURN ok, error_text \
END FUNCTION

WRAP_FUNCTION_T1_FV(string_valid, s, STRING)
WRAP_FUNCTION_T1_FV(number_valid, n, INTEGER )
WRAP_FUNCTION_T1_FV(date_valid, d , DATE)