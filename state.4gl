IMPORT FGL lib_stm

TYPE tablenameType RECORD
    state_code CHAR(2),
    state_name CHAR(15)
END RECORD

#DEFINE arr DYNAMIC ARRAY OF tablenameType
#DEFINE rec tablenameType
#DEFINE idx INTEGER

-- Populate Fields
FUNCTION init()
DEFINE i INTEGER

    LET stm.name = "ex_stm_state"
    LET stm.order_by = "state_code"
    LET stm.where_clause = "1=1"
    LET stm.title = "State Table"

    -- TODO see if replace indexes by array dictionary
    LET stm.column[1].name = "state_code"     
    LET stm.column[1].label = "Code"   
    LET stm.column[1].type = "CHAR(2)" 
    LET stm.column[1].key = TRUE
    LET stm.column[1].notnull = TRUE
    
    LET stm.column[2].name = "state_name"   
    LET stm.column[2].label = "Name" 
    LET stm.column[2].type = "CHAR(25)" 
    LET stm.column[2].key = FALSE

     -- Set initially to stub function
    FOR i = 1 TO stm.column.getLength()
        LET stm.column[i].default_function = FUNCTION lib_stm.field_default
        LET stm.column[i].default_qbe_function = FUNCTION lib_stm.field_default
        LET stm.column[i].visible_function = FUNCTION lib_stm.field_visible
        LET stm.column[i].editable_function = FUNCTION lib_stm.field_editable
        LET stm.column[i].valid_function = FUNCTION lib_stm.field_valid
    END FOR

    #LET stm.set = FUNCTION set
   # LET stm.get = FUNCTION get
    
    LET stm.can_view_function = FUNCTION can_view
    LET stm.can_add_function = FUNCTION can_add
    LET stm.can_update_function = FUNCTION can_update
    LET stm.can_delete_function = FUNCTION can_delete

    LET stm.can_view_row_function = FUNCTION can_view_row
    LET stm.can_update_row_function = FUNCTION can_update_row
    LET stm.can_delete_row_function = FUNCTION can_delete_row

    LET stm.key_valid_function = FUNCTION key_valid
    LET stm.data_valid_function = FUNCTION data_valid

    
    #LET stm.set_idx_function = FUNCTION set_idx
    #LET stm.get_idx_function = FUNCTION get_idx
    #ET stm.count_function = FUNCTION get_count
    
END FUNCTION
{
FUNCTION get_count() RETURNS INTEGER
    RETURN arr.getLength()
END FUNCTION

FUNCTION get_idx() RETURNS INTEGER
    RETURN idx
END FUNCTION

FUNCTION set_idx(i INTEGER)
    LET idx = i
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
}

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
