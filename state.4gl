IMPORT util

IMPORT FGL lib_stm

TYPE tablenameType RECORD --TODO should this be RECORD LIKE state.*
    state_code CHAR(2),
    state_name CHAR(15)
END RECORD

DEFINE rec tablenameType

-- Populate Fields
FUNCTION init()
    DEFINE i INTEGER

    LET stm.name = "ex_stm_state"
    LET stm.order_by = "state_code"
    LET stm.where_clause = "1=1"
    LET stm.title = "State Table"

    -- TODO see if can replace indexes and see if can use DICTIONARY based on column name
    LET stm.column[1].name = "state_code"
    LET stm.column[1].label = "Code"
    LET stm.column[1].type = "CHAR(2)"
    LET stm.column[1].key = TRUE
    LET stm.column[1].notnull = TRUE

    LET stm.column[2].name = "state_name"
    LET stm.column[2].label = "Name"
    LET stm.column[2].type = "CHAR(25)"
    LET stm.column[2].key = FALSE

    -- Should not need to explicitly state this but essentially for all the FUNCTION references it sets to a default function
    IF 1 = 1 THEN
        FOR i = 1 TO stm.column.getLength()
            LET stm.column[i].default_function = FUNCTION lib_stm.field_default
            LET stm.column[i].default_qbe_function = FUNCTION lib_stm.field_default
            LET stm.column[i].visible_function = FUNCTION lib_stm.field_visible
            LET stm.column[i].editable_function = FUNCTION lib_stm.field_editable
            LET stm.column[i].valid_function = FUNCTION lib_stm.field_valid
        END FOR

        LET stm.can_view_function = FUNCTION can_view
        LET stm.can_add_function = FUNCTION can_add
        LET stm.can_update_function = FUNCTION can_update
        LET stm.can_delete_function = FUNCTION can_delete

        LET stm.can_view_row_function = FUNCTION can_view_row
        LET stm.can_update_row_function = FUNCTION can_update_row
        LET stm.can_delete_row_function = FUNCTION can_delete_row

        LET stm.key_valid_function = FUNCTION key_valid
        LET stm.data_valid_function = FUNCTION data_valid
    END IF

    -- This is where customer adds references to the functions they have explicitly coded
    LET stm.column[1].valid_function = FUNCTION state_code_valid
    LET stm.column[2].valid_function = FUNCTION state_name_valid

END FUNCTION

-- Table level rules
FUNCTION can_view() RETURNS BOOLEAN
    RETURN TRUE
END FUNCTION

FUNCTION can_add() RETURNS BOOLEAN
    RETURN TRUE
END FUNCTION

FUNCTION can_update() RETURNS BOOLEAN
    RETURN TRUE
END FUNCTION

FUNCTION can_delete() RETURNS BOOLEAN
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
FUNCTION data_valid() RETURNS(BOOLEAN, STRING, STRING)

    RETURN TRUE, NULL, NULL
END FUNCTION

-- If any record available
FUNCTION data_valid_with_anyrecord(d) RETURNS(BOOLEAN, STRING, STRING)
    DEFINE d tablenameType

    RETURN TRUE, NULL, NULL
END FUNCTION

FUNCTION key_valid() RETURNS(BOOLEAN, STRING, STRING)

    SELECT 'X' FROM ex_stm_state WHERE state_code = rec.state_code

    IF status = NOTFOUND THEN
        #OK
    ELSE
        RETURN FALSE, "Key already exists", "state_code"
    END IF
    RETURN TRUE, NULL, NULL
END FUNCTION

-- Field validation

FUNCTION state_code_valid(value STRING) RETURNS(BOOLEAN, STRING)

    IF value IS NULL THEN
        RETURN FALSE, "State Code must be entered"
    END IF
    IF value.trim().getLength() != 2 THEN
        RETURN FALSE, "State Code must be 2 characters"
    END IF
    RETURN TRUE, NULL
END FUNCTION

FUNCTION state_name_valid(value STRING) RETURNS(BOOLEAN, STRING)

    IF value IS NULL THEN
        RETURN FALSE, "State Name must be entered"
    END IF
    RETURN TRUE, NULL
END FUNCTION

#TODO is this used?
FUNCTION set_rec(dict DICTIONARY OF STRING)
    CALL util.JSON.parse(util.JSON.stringify(dict), rec)
END FUNCTION

{
From Renes samples




FUNCTION (rec state_rec)data_valid()
    RETURN TRUE, NULL, NULL
END FUNCTION

    LET stm.key_valid_function = FUNCTION rec.data_valid

}
