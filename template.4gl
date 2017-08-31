IMPORT FGL lib_stm


TYPE tablenameType RECORD
    state_code CHAR(2),
    state_name CHAR(15)
END RECORD

DEFINE arr DYNAMIC ARRAY OF tablenameType
DEFINE rec tablenameType

-- Populate Fields
FUNCTION init()
DEFINE i INTEGER

    LET data.name = "state"
    LET data.order_by = "state_code"
    LET data.where_clause = "1=1"
    LET data.title = "State Table"

    -- TODO see if replace indexes by array dictionary
    LET data.column[1].name = "state_code"     
    LET data.column[1].label = "Code"   
    LET data.column[1].type = "CHAR(2)" 
    LET data.column[1].key = TRUE
    LET data.column[1].notnull = TRUE
    
    LET data.column[2].name = "state_name"   
    LET data.column[2].label = "Char" 
    LET data.column[2].type = "CHAR(25)" 
    LET data.column[2].key = FALSE

     -- Set initially to stub function
    FOR i = 1 TO data.column.getLength()
        LET data.column[i].default_function = FUNCTION lib_stm.field_default
        LET data.column[i].default_qbe_function = FUNCTION lib_stm.field_default
        LET data.column[i].visible_function = FUNCTION lib_stm.field_visible
        LET data.column[i].editable_function = FUNCTION lib_stm.field_editable
        LET data.column[i].valid_function = FUNCTION lib_stm.field_valid
    END FOR

    LET data.set = FUNCTION set
    LET data.get = FUNCTION get
    
    LET data.can_view_function = FUNCTION can_view
    LET data.can_add_function = FUNCTION can_add
    LET data.can_update_function = FUNCTION can_update
    LET data.can_delete_function = FUNCTION can_delete

    LET data.can_view_row_function = FUNCTION can_view_row
    LET data.can_update_row_function = FUNCTION can_update_row
    LET data.can_delete_row_function = FUNCTION can_delete_row

    LET data.key_valid_function = FUNCTION key_valid
    LET data.data_valid_function = FUNCTION data_valid
    
END FUNCTION


-- TODO should not need this set function
FUNCTION set(fieldname STRING, value STRING)

    CASE fieldname
        WHEN "state_code" LET rec.state_code = value
        WHEN "state_name" LET rec.state_name = value
    END CASE
END FUNCTION


-- TODO should not need this get function
FUNCTION get(fieldname STRING) RETURNS STRING
DEFINE value STRING

    CASE fieldname
        WHEN "state_code" LET value = rec.state_code
        WHEN "state_name" LET value = rec.state_name
    END CASE
    RETURN value
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
