

&define WRAP_FUNCTION_T1_0(p1,p2,p3 ) FUNCTION _ ## p1(rv reflect.Value) \
DEFINE p2 p3 \
    CALL rv.assignToVariable(p2) \
    CALL p1(p2) \
    CALL rv.set(reflect.Value.copyOf(p2)) \
END FUNCTION


&define WRAP_FUNCTION_T1_S(p1,p2,p3) FUNCTION _ ## p1(rv reflect.Value) RETURNS (STRING) \
DEFINE s STRING \
DEFINE p2 p3 \
    CALL rv.assignToVariable(p2) \
    CALL p1(p2) RETURNING s \
    RETURN s \
END FUNCTION

&define WRAP_FUNCTION_T1_B(p1,p2,p3) FUNCTION _ ## p1(rv reflect.Value) RETURNS (BOOLEAN) \
DEFINE ok BOOLEAN \
DEFINE p2 p3 \
    CALL rv.assignToVariable(p2) \
    CALL p1(p2) RETURNING ok \
    RETURN ok \
END FUNCTION

&define WRAP_FUNCTION_T1_FV(p1,p2,p3) FUNCTION _ ## p1(rv reflect.Value) RETURNS (BOOLEAN, STRING) \
DEFINE ok BOOLEAN \
DEFINE error_text STRING \
DEFINE p2 p3 \
    CALL rv.assignToVariable(p2) \
    CALL p1(p2) RETURNING ok, error_text \
    RETURN ok, error_text \
END FUNCTION

&define WRAP_FUNCTION_T1_RV(p1,p2,p3) FUNCTION _ ## p1(rv reflect.Value) RETURNS (BOOLEAN, STRING, STRING) \
DEFINE ok BOOLEAN \
DEFINE error_text STRING \
DEFINE field_name STRING \
DEFINE p2 p3 \
    CALL rv.assignToVariable(p2) \
    CALL p1(p2) RETURNING ok, error_text, field_name \
    RETURN ok, error_text, field_name \
END FUNCTION
