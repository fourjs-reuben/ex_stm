
--  Callback Functions
PUBLIC TYPE default_function_type FUNCTION () RETURNS STRING 

PUBLIC TYPE simple_rule_function_type FUNCTION () RETURNS BOOLEAN
PUBLIC TYPE simple_rule_with_error_function_type FUNCTION () RETURNS (BOOLEAN, STRING)

PUBLIC TYPE simple_row_rule_function_type FUNCTION (row INTEGER) RETURNS BOOLEAN
PUBLIC TYPE simple_row_rule_with_error_function_type FUNCTION (row INTEGER) RETURNS (BOOLEAN, STRING)

PUBLIC TYPE value_valid_function_type FUNCTION (value STRING) RETURNS (BOOLEAN, STRING)
PUBLIC TYPE record_valid_function_type FUNCTION() RETURNS (BOOLEAN, STRING, STRING)

-- What information do we have about a database column
PUBLIC TYPE column_type RECORD
    name STRING,
    type STRING,
    key BOOLEAN,
    label STRING,
    widget STRING,
    widget_properties STRING,
    default_function default_function_type,
    visible_function simple_rule_function_type,
    editable_function simple_rule_function_type, 
    valid_function value_valid_function_type
END RECORD

-- What information do we have about a database table
PUBLIC TYPE table_type RECORD
    name STRING,
    title STRING,
    order_by STRING,
    where_clause STRING,
    can_view_function simple_rule_function_type,
    can_add_function simple_rule_function_type,
    can_update_function simple_rule_function_type,
    can_delete_function simple_rule_function_type,
    can_view_row_function simple_row_rule_function_type,
    can_update_row_function simple_row_rule_function_type,
    can_delete_row_function simple_row_rule_function_type,
    key_valid_function record_valid_function_type,
    data_valid_function record_valid_function_type,
    column DYNAMIC ARRAY OF column_type
END RECORD



PUBLIC DEFINE data table_type
DEFINE add_mode BOOLEAN
DEFINE d ui.Dialog
DEFINE f ui.Form



FUNCTION input()
DEFINE ev STRING


    OPTIONS INPUT WRAP
    OPTIONS FIELD ORDER FORM

    OPEN WINDOW w WITH FORM "tablename"  #TODO replace with dynamic create form
    CALL ui.Window.getCurrent().setText(data.title)
    LET f = ui.Window.getCurrent().getForm()

    LET add_mode = TRUE
    
    CALL ui.Dialog.setDefaultUnbuffered(TRUE)
    LET d = ui.Dialog.createInputByName(data.column)

    CALL d.addTrigger("ON ACTION accept")
    CALL d.addTrigger("ON ACTION cancel")
    CALL d.addTrigger("ON ACTION close")

    WHILE TRUE
        -- Set state
        CALL state()
        
        LET ev = d.nextEvent()
        CASE
            WHEN ev = "BEFORE INPUT"
                IF add_mode THEN
                    CALL set_default_values()
                END IF
            WHEN ev MATCHES "BEFORE FIELD*"
                -- CALL before_field()
            WHEN ev MATCHES "ON CHANGE *"
                -- CALL on_change_field()
            WHEN ev MATCHES "AFTER FIELD*"
                CALL after_field()
            WHEN ev  = "ON ACTION close" OR ev = "ON ACTION cancel"
                LET int_flag = 0
                EXIT WHILE
            WHEN ev = "ON ACTION accept"
                IF accept() THEN
                    EXIT WHILE
                END IF
                
            OTHERWISE
                DISPLAY "OTHERWISE ", ev
        END CASE
    END WHILE
    
END FUNCTION





FUNCTION state()
DEFINE i INTEGER
DEFINE vfn simple_rule_function_type
DEFINE efn simple_rule_function_type
DEFINE value BOOLEAN

    FOR i = 1 TO data.column.getLength()
        LET vfn = data.column[i].visible_function
        LET value = vfn()
        CALL f.setFieldHidden(data.column[i].name, NOT value)

        LET efn = data.column[i].editable_function
        LET value = efn()
        CALL d.setFieldActive(data.column[i].name, value AND ((NOT add_mode AND NOT data.column[i].key) OR add_mode))
    END FOR
END FUNCTION



FUNCTION set_default_values()
DEFINE i INTEGER
DEFINE value STRING
DEFINE fn default_function_type

    FOR i = 1 TO data.column.getLength()
        LET fn = data.column[i].default_function
        LET value = fn()
        CALL d.setFieldValue(data.column[i].name, value)
    END FOR
END FUNCTION



FUNCTION before_field()
END FUNCTION



FUNCTION on_change_field()
END FUNCTION



FUNCTION after_field()
DEFINE fn value_valid_function_type
DEFINE value STRING
DEFINE idx INTEGER
DEFINE ok BOOLEAN
DEFINE error_text STRING

    LET idx = get_data_column_idx(d.getCurrentItem())
    LET fn = data.column[idx].valid_function
    LET value = d.getFieldValue(d.getCurrentItem())
    CALL fn(value) RETURNING ok, error_text
    IF NOT ok THEN
        ERROR error_text
        CALL d.nextField("+CURR")
    END IF
END FUNCTION



FUNCTION accept()

DEFINE i INTEGER
DEFINE ok BOOLEAN
DEFINE error_text STRING
DEFINE fieldname STRING
DEFINE value STRING
DEFINE first_key_field STRING
DEFINE first_data_field STRING
DEFINE fn value_valid_function_type
DEFINE kfn record_valid_function_type
DEFINE dfn record_valid_function_type


    -- Test key data.column
    IF add_mode THEN
        -- Individually test every key field
        FOR i = 1 TO data.column.getLength()
            IF data.column[i].key THEN
                IF first_key_field IS NULL THEN
                    LET first_key_field = data.column[i].name
                END IF
                
                LET fn = data.column[i].valid_function
                LET value = d.getFieldValue(data.column[i].name)
                CALL fn(value) RETURNING ok, error_text

            #    CALL data.column[i].valid_function(d.getFieldValue(data.column[i].name)) RETURNING ok, error_text
                
                IF NOT ok THEN
                    ERROR error_text
                    CALL d.nextField(data.column[i].name)
                    RETURN FALSE
                END IF
            END IF
        END FOR

        LET kfn = data.key_valid_function
        CALL kfn() RETURNING ok, error_text, fieldname
        IF NOT ok THEN
            ERROR error_text
            CALL d.nextField(nvl(fieldname,first_key_field))
            RETURN FALSE
        END IF
    END IF

    -- Individually test every remaining data field
    FOR i = 1 TO data.column.getLength()
        IF NOT data.column[i].key THEN
            IF first_data_field IS NULL THEN
                LET first_data_field = data.column[i].name
            END IF
            LET fn = data.column[i].valid_function
            LET value = d.getFieldValue(data.column[i].name)
            CALL fn(value) RETURNING ok, error_text
            IF NOT ok THEN
                ERROR error_text
                CALL d.nextField(data.column[i].name)
                RETURN FALSE
            END IF
        END IF
    END FOR
    
    LET dfn = data.data_valid_function
    CALL dfn() RETURNING ok, error_text, fieldname
    IF NOT ok THEN
        ERROR error_text
        CALL d.nextField(nvl(fieldname,first_data_field))
        RETURN FALSE
    END IF    
    RETURN TRUE
END FUNCTION


-- Stub Default Functions
PUBLIC FUNCTION field_visible() RETURNS BOOLEAN
    RETURN TRUE
END FUNCTION

PUBLIC FUNCTION field_editable() RETURNS BOOLEAN
    RETURN TRUE
END FUNCTION

PUBLIC FUNCTION field_default() RETURNS STRING
    RETURN NULL
END FUNCTION

PUBLIC FUNCTION field_valid(value STRING) RETURNS (BOOLEAN, STRING)
    RETURN TRUE, NULL
END FUNCTION



PRIVATE FUNCTION get_data_column_idx(name)
DEFINE name STRING
DEFINE i INTEGER

    FOR i = 1 TO data.column.getLength()
        IF data.column[i].name = name THEN
            RETURN i
        END IF
    END FOR
    EXIT PROGRAM 1
END FUNCTION

