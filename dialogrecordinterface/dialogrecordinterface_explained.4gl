-- Attempt at simpler version of above in order to explain the issue


IMPORT reflect

# ISSUE #1 WITHOUT ANYTYPE, ANY RECORD, use reflect.value in FUNCTION referencing
#TYPE validate_function_type FUNCTION (value ANYTYPE) RETURNS (BOOLEAN, STRING)
TYPE validate_function_type FUNCTION (rv reflect.Value) RETURNS (BOOLEAN, STRING)

DEFINE field_validate_list DICTIONARY OF validate_function_type


MAIN

DEFINE d ui.Dialog
DEFINE record_rv, field_rv reflect.Value
DEFINE current_field_name STRING

DEFINE ok BOOLEAN
DEFINE error_text STRING

    -- INIT

    # ISSUE #1 WITHOUT ANYTYPE, ANY RECORD, use preprocessor to map function defined using reflect.Value to function with actual type
    #LET field_validate_list["string"] = FUNCTION string_valid
    #LET field_validate_list["number"] = FUNCTION number_valid
    #ET field_validate_list["date"]   = FUNCTION date_valid
    
    LET field_validate_list["string"] = FUNCTION _string_valid
    LET field_validate_list["number"] = FUNCTION _number_valid
    LET field_validate_list["date"]   = FUNCTION _date_valid

    --  GENERIC DIALOG CODE

    -- assume function to map dialog fields to reflect value for record, hence record_rv is populated, seedialog2rec in user_interface.4gl
    LET current_field_name = d.getCurrentItem()  -- what is current field we are processing
    LET field_rv = record_rv.getFieldByName(current_field_name) -- get the field value from the record reflected value

    # ISSUE #2, want to push the reflected Value rather than the reflect Value onto the stack
    CALL field_validate_list[current_field_name](field_rv) RETURNING ok, error_text
    #CALL field_validate_list[current_field_name](*field_rv) RETURNING ok, error_text

    
END MAIN



FUNCTION string_valid(s STRING) RETURNS (BOOLEAN, STRING)

    IF s.getLength() > 3 THEN
        #OK
    ELSE
        RETURN FALSE,"Must be at least four characters" 
    END IF
    RETURN TRUE, ""
END FUNCTION

FUNCTION number_valid(n INTEGER) RETURNS (BOOLEAN, STRING)

    IF n >=100 THEN
        #OK
    ELSE
        RETURN FALSE,"Must be at least 100"
    END IF
    RETURN TRUE, ""
END FUNCTION

FUNCTION date_valid(d DATE) RETURNS (BOOLEAN, STRING)

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