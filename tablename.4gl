IMPORT FGL lib_stm

TYPE tablenameType RECORD
    field1 STRING,
    field2 STRING,
    field3 DATE
END RECORD

DEFINE arr DYNAMIC ARRAY OF tablenameType
DEFINE rec DYNAMIC ARRAY OF tablenameType



-- Populate Fields
FUNCTION init()
DEFINE i INTEGER

    LET data.name = "my_table"
    LET data.order_by = "field1"
    LET data.where_clause = "1=1"
    LET data.title = "My Table"

    LET data.column[1].name = "field1"   LET data.column[1].type = "STRING" LET data.column[1].key = TRUE
    LET data.column[2].name = "field2"   LET data.column[2].type = "STRING" LET data.column[2].key = FALSE
    LET data.column[3].name = "field3"   LET data.column[3].type = "DATE"   LET data.column[3].key = FALSE    

     -- Set initially to stub function
    FOR i = 1 TO data.column.getLength()
        LET data.column[i].default_function = FUNCTION lib_stm.field_default
        LET data.column[i].visible_function = FUNCTION lib_stm.field_visible
        LET data.column[i].editable_function = FUNCTION lib_stm.field_editable
        LET data.column[i].valid_function = FUNCTION lib_stm.field_valid
    END FOR
    
    LET data.can_view_function = FUNCTION can_view
    LET data.can_add_function = FUNCTION can_add
    LET data.can_update_function = FUNCTION can_update
    LET data.can_delete_function = FUNCTION can_delete

    LET data.can_view_row_function = FUNCTION can_view_row
    LET data.can_update_row_function = FUNCTION can_update_row
    LET data.can_delete_row_function = FUNCTION can_delete_row

    LET data.key_valid_function = FUNCTION key_valid
    LET data.data_valid_function = FUNCTION data_valid

   
    -- Add here as defined per column
    LET data.column[3].default_function = FUNCTION field3_default
    LET data.column[3].valid_function = FUNCTION field3_valid
END FUNCTION




-- Table level rules
FUNCTION can_view() RETURNS BOOLEAN
    RETURN TRUE
END FUNCTION

FUNCTION can_add()  RETURNS BOOLEAN
    RETURN TRUE
END FUNCTION

FUNCTION can_update()  RETURNS BOOLEAN
    RETURN TRUE
END FUNCTION

FUNCTION can_delete()  RETURNS BOOLEAN
    RETURN TRUE
END FUNCTION







-- Row level rules
FUNCTION can_view_row(row INTEGER) RETURNS BOOLEAN
    RETURN TRUE
END FUNCTION

FUNCTION can_update_row(row INTEGER) RETURNS BOOLEAN
    RETURN TRUE
END FUNCTION

FUNCTION can_delete_row(row INTEGER) RETURNS BOOLEAN
    RETURN TRUE
END FUNCTION


-- Record validation
FUNCTION data_valid() RETURNS (BOOLEAN, STRING, STRING)
    RETURN TRUE, NULL, NULL
END FUNCTION

FUNCTION key_valid() RETURNS (BOOLEAN, STRING, STRING)
    RETURN TRUE, NULL, NULL
END FUNCTION



-- Column level rules

FUNCTION field3_default() RETURNS STRING
    RETURN TODAY
END FUNCTION

FUNCTION field3_valid(value STRING) RETURNS (BOOLEAN, STRING)
    IF value <= TODAY THEN
        RETURN FALSE, "Date must be after today"
    END IF
    RETURN TRUE, ""
END FUNCTION