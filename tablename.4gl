IMPORT FGL lib_stm

TYPE tablenameType RECORD
    key_fld INTEGER, char_fld CHAR(10), date_fld DATE, checkbox_fld CHAR(1), integer_fld INTEGER, decimal_fld DECIMAL(11,2), from_dmy DATE, to_dmy DATE
END RECORD

DEFINE arr DYNAMIC ARRAY OF tablenameType
DEFINE rec tablenameType



-- Populate Fields
FUNCTION init()
DEFINE i INTEGER

    LET data.name = "my_table"
    LET data.order_by = "key_fld"
    LET data.where_clause = "1=1"
    LET data.title = "My Table"

    -- TODO see if replace indexes by array dictionary
    LET data.column[1].name = "key_fld"     
    LET data.column[1].label = "Key 1"   
    LET data.column[1].type = "INTEGER" 
    LET data.column[1].key = TRUE
    LET data.column[1].notnull = TRUE
    
    LET data.column[2].name = "char_fld"   
    LET data.column[2].label = "Char" 
    LET data.column[2].type = "CHAR(10)" 
    LET data.column[2].key = FALSE

    LET data.column[3].name = "date_fld"   
    LET data.column[3].label = "DateEdit" 
    LET data.column[3].type = "DATE"   
    LET data.column[3].key = FALSE    
    LET data.column[3].widget = "DateEdit"

    LET data.column[4].name = "checkbox_fld"   
    LET data.column[4].label = "CheckBox" 
    LET data.column[4].type = "CHAR(1)"   
    LET data.column[4].key = FALSE    
    LET data.column[4].notnull = TRUE
    LET data.column[4].widget = "CheckBox"
    LET data.column[4].widget_properties = '{"valueChecked": "Y", "valueUnchecked": "N"}'

    LET data.column[5].name = "integer_fld"   
    LET data.column[5].label = "Integer" 
    LET data.column[5].type = "INTEGER" 
    LET data.column[5].key = FALSE
    
    LET data.column[6].name = "decimal_fld"   
    LET data.column[6].label = "Decimal" 
    LET data.column[6].type = "DECIMAL(11,2)" 
    LET data.column[6].key = FALSE
    LET data.column[6].widget_properties = '{"format": "###,##&.&&"}'

    LET data.column[7].name = "from_dmy"   
    LET data.column[7].label = "From" 
    LET data.column[7].notnull = TRUE
    LET data.column[7].type = "DATE" 
    LET data.column[7].key = FALSE
    LET data.column[7].widget = "DateEdit"

    LET data.column[8].name = "to_dmy"   
    LET data.column[8].label = "To"
    LET data.column[8].notnull = TRUE 
    LET data.column[8].type = "DATE" 
    LET data.column[8].key = FALSE
    LET data.column[8].widget = "DateEdit"

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

   
    -- Add here as defined per column
    LET data.column[3].default_function = FUNCTION date_fld_default
    LET data.column[3].valid_function = FUNCTION date_fld_valid

    LET data.column[4].default_function = FUNCTION cbox_fld_default

    LET data.column[5].valid_function = FUNCTION integer_fld_valid
END FUNCTION



-- TODO should not need this set function
FUNCTION set(fieldname STRING, value STRING)

    CASE fieldname
        WHEN "key_fld" LET rec.key_fld = value
        WHEN "char_fld" LET rec.char_fld = value
        WHEN "date_fld" LET rec.date_fld = value
        WHEN "checkbox_fld" LET rec.checkbox_fld = value
        WHEN "integer_fld" LET rec.integer_fld = value
        WHEN "decimal_fld" LET rec.decimal_fld = value
        WHEN "from_dmy" LET rec.from_dmy = value
        WHEN "to_dmy" LET rec.to_dmy = value
    END CASE
END FUNCTION


-- TODO should not need this get function
FUNCTION get(fieldname STRING) RETURNS STRING
DEFINE value STRING

    CASE
        WHEN "key_fld" LET value = rec.key_fld
        WHEN "char_fld" LET value = rec.char_fld
        WHEN "date_fld" LET value = rec.date_fld
        WHEN "checkbox_fld" LET value = rec.checkbox_fld
        WHEN "integer_fld" LET value = rec.integer_fld
        WHEN "decimal_fld" LET value = rec.decimal_fld
        WHEN "from_dmy" LET value = rec.from_dmy
        WHEN "to_dmy" LET value = rec.to_dmy
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

    IF rec.from_dmy < rec.to_dmy THEN
        #OK
    ELSE
        RETURN FALSE, "From must be before to", "from_dmy"
    END IF
    RETURN TRUE, NULL, NULL
END FUNCTION

FUNCTION key_valid() RETURNS (BOOLEAN, STRING, STRING)
    RETURN TRUE, NULL, NULL
END FUNCTION



-- Column level rules
FUNCTION date_fld_default() RETURNS STRING
    RETURN TODAY+1
END FUNCTION

FUNCTION date_fld_valid(value STRING) RETURNS (BOOLEAN, STRING)
    IF value <= TODAY THEN
        RETURN FALSE, "Date must be after today"
    END IF
   
    RETURN TRUE, ""
END FUNCTION

FUNCTION cbox_fld_default() RETURNS STRING
    RETURN "Y"
END FUNCTION

FUNCTION integer_fld_valid(value STRING) RETURNS (BOOLEAN, STRING)
    IF value > 0 THEN
        #OK
    ELSE
        RETURN FALSE, "Integer must be positive"
    END IF
     IF value MOD 2 = 0 THEN
        #OK
    ELSE
        RETURN FALSE, "Integer must be even"
    END IF
    RETURN TRUE, ""
END FUNCTION