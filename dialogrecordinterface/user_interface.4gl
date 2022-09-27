-- Everything in here is generic and it will be used by every instance
-- There will be no referece to a database table or field

IMPORT reflect

IMPORT FGL db

-- Table Functions Type
-- other candidates include order by, filter

-- Row Functions Type
TYPE row_default_fn_type FUNCTION(rv reflect.Value)
TYPE row_valid_fn_type FUNCTION(rv reflect.Value) RETURNS(BOOLEAN, STRING, STRING)

-- Field Function Type
TYPE field_active_fn_type FUNCTION(rv reflect.Value) RETURNS(BOOLEAN) -- return true/false if field active
TYPE field_visible_fn_type FUNCTION(rv reflect.Value) RETURNS(BOOLEAN) -- return true/value if field visible
TYPE field_default_fn_type FUNCTION(rv reflect.Value) RETURNS() -- return default value for individual field
TYPE field_valid_fn_type FUNCTION(rv reflect.Value) RETURNS(BOOLEAN, STRING) -- return true/false if field valid

TYPE dynamic_dialogs_field_type DYNAMIC ARRAY OF RECORD -- Used to setup dynamic dialog
    name STRING,
    type STRING
END RECORD

PUBLIC TYPE dialogType RECORD
    d ui.Dialog,
    current_row INTEGER,
    fields dynamic_dialogs_field_type,
    properties RECORD
        table_name STRING,
        form_name STRING,
        table_title STRING,
        field_title DICTIONARY OF STRING,
        primary_key DICTIONARY OF STRING
    END RECORD,
    functions RECORD
        row_default_fn row_default_fn_type,
        row_valid_fn row_valid_fn_type,
        key_valid_fn row_valid_fn_type,

        field_active_fn DICTIONARY OF field_active_fn_type,
        field_visible_fn DICTIONARY OF field_visible_fn_type,
        field_default_fn DICTIONARY OF field_default_fn_type,
        field_valid_fn DICTIONARY OF field_valid_fn_type
    END RECORD,
    arr_rv reflect.Value,
    row_rv reflect.Value
END RECORD

PUBLIC FUNCTION pre(my_dialog dialogType)
    DEFER INTERRUPT
    DEFER QUIT
    OPTIONS FIELD ORDER FORM
    OPTIONS INPUT WRAP
    CLOSE WINDOW SCREEN

    CALL ui.Interface.loadStyles("user_interface.4st")
    CALL ui.Interface.loadActionDefaults("user_interface.4ad")
    CALL ui.Interface.loadToolBar("user_interface.4tb")
    OPEN WINDOW w WITH FORM my_dialog.properties.form_name ATTRIBUTES(TEXT = my_dialog.properties.table_title)

    VAR keys = my_dialog.properties.field_title.getKeys()
    VAR field_idx INTEGER
    FOR field_idx = 1 TO keys.getLength()
        CALL ui.Window.getCurrent().getForm()
            .setElementText("lbl_" || keys[field_idx], my_dialog.properties.field_title[keys[field_idx]])
    END FOR

END FUNCTION

PUBLIC FUNCTION post()
    CLOSE WINDOW w
END FUNCTION

FUNCTION maintenance(my_dialog dialogType INOUT)

    MENU ""
        BEFORE MENU
            CALL maintenance_state(DIALOG, my_dialog)

        ON ACTION query
            CALL qbe(my_dialog)
            CALL db.populate(my_dialog.arr_rv, "my_table", "1=1", "id")
            IF my_dialog.arr_rv.getLength() > 0 THEN
                LET my_dialog.current_row = 1
                CALL display_current_row(my_dialog)
                CALL maintenance_state(DIALOG, my_dialog)
            END IF
            CALL maintenance_state(DIALOG, my_dialog)
            
        ON ACTION add
            CALL edit(my_dialog, TRUE)
            
        ON ACTION update
            CALL edit(my_dialog, FALSE)
            
        ON ACTION delete
            #
        ON ACTION first
            LET my_dialog.current_row = 1
            CALL display_current_row(my_dialog)
            CALL maintenance_state(DIALOG, my_dialog)
            #
        ON ACTION prev
            LET my_dialog.current_row = my_dialog.current_row - 1
            CALL display_current_row(my_dialog)
            CALL maintenance_state(DIALOG, my_dialog) #
        ON ACTION goto
            #
        ON ACTION next
            #
            LET my_dialog.current_row = my_dialog.current_row + 1
            CALL display_current_row(my_dialog)
            CALL maintenance_state(DIALOG, my_dialog)
        ON ACTION last
            LET my_dialog.current_row = my_dialog.arr_rv.getLength()
            CALL display_current_row(my_dialog)
            CALL maintenance_state(DIALOG, my_dialog)
            #
        ON ACTION exit
            EXIT MENU
    END MENU
END FUNCTION

PRIVATE FUNCTION display_current_row(my_dialog dialogType INOUT)
    LET my_dialog.row_rv = my_dialog.arr_rv.getArrayElement(my_dialog.current_row)
    CALL display_row(my_dialog)
END FUNCTION

PRIVATE FUNCTION maintenance_state(m ui.Dialog, my_dialog dialogType)

    DEFINE array_populated BOOLEAN

    LET array_populated = my_dialog.arr_rv.getLength() > 0

    CALL m.setActionActive("update", array_populated)
    CALL m.setActionActive("delete", array_populated)

    CALL m.setActionActive("first", array_populated AND my_dialog.current_row > 1)
    CALL m.setActionActive("prev", array_populated AND my_dialog.current_row > 1)
    CALL m.setActionActive("goto", array_populated)
    CALL m.setActionActive("next", array_populated AND my_dialog.current_row < my_dialog.arr_rv.getLength())
    CALL m.setActionActive("last", array_populated AND my_dialog.current_row < my_dialog.arr_rv.getLength())

END FUNCTION

PRIVATE FUNCTION display_row(my_dialog dialogType INOUT)
    DEFINE field_name STRING
    DEFINE field_idx INTEGER

    FOR field_idx = 1 TO my_dialog.fields.getLength()
        LET field_name = my_dialog.fields[field_idx].name
        CALL ui.Form.displayTo(my_dialog.row_rv.getFieldByName(field_name).toString(), field_name, NULL, NULL)
    END FOR
END FUNCTION

PRIVATE FUNCTION qbe(my_dialog dialogType INOUT)

    LET my_dialog.d = ui.Dialog.createConstructByName(my_dialog.fields)
    CALL my_dialog.d.addTrigger("ON ACTION accept")
    CALL my_dialog.d.addTrigger("ON ACTION cancel")

    -- qbe defaults TODO

    WHILE TRUE
        VAR ev = my_dialog.d.nextEvent()
        IF ev IS NULL THEN
            EXIT WHILE
        END IF
        CASE
            -- after field logic TODO
            -- after construct logic TODO
            WHEN ev = "ON ACTION accept"
                LET int_flag = TRUE
                EXIT WHILE
            WHEN ev = "ON ACTION cancel"
                LET int_flag = TRUE
                EXIT WHILE
        END CASE
    END WHILE
    CALL my_dialog.d.close()

END FUNCTION

PRIVATE FUNCTION edit(my_dialog dialogType INOUT, add_mode BOOLEAN)
    DEFINE field_idx INTEGER
    DEFINE primary_key_list DYNAMIC ARRAY OF STRING
    DEFINE active_field_list DYNAMIC ARRAY OF STRING
    DEFINE visible_field_list DYNAMIC ARRAY OF STRING

    LET primary_key_list = my_dialog.properties.primary_key.getKeys()
    LET active_field_list = my_dialog.functions.field_active_fn.getKeys()
    LET visible_field_list = my_dialog.functions.field_visible_fn.getKeys()

    VAR f = ui.Window.getCurrent().getForm()

    LET my_dialog.d = ui.Dialog.createInputByName(my_dialog.fields)
    CALL my_dialog.d.addTrigger("ON ACTION accept")
    CALL my_dialog.d.addTrigger("ON ACTION cancel")

    IF my_dialog.functions.row_default_fn IS NOT NULL THEN
        CALL my_dialog.functions.row_default_fn(my_dialog.row_rv)
    END IF
    CALL my_dialog.rec2dialog() -- parse record to dialog value generically

    WHILE TRUE
        -- can the user see a field ?
        FOR field_idx = 1 TO visible_field_list.getLength()
            VAR hidden = NOT my_dialog.functions.field_visible_fn[visible_field_list[field_idx]](my_dialog.row_rv)
            CALL f.setElementHidden("lbl_" || visible_field_list[field_idx], hidden)
            CALL f.setFieldHidden(visible_field_list[field_idx], hidden)
        END FOR

        -- Can't edit primary key fields
        IF NOT add_mode THEN
            FOR field_idx = 1 TO primary_key_list.getLength()
                CALL my_dialog.d.setFieldActive(primary_key_list[field_idx], FALSE)
            END FOR
        END IF

        -- can the user edit a field ?
        FOR field_idx = 1 TO active_field_list.getLength()
            IF NOT add_mode AND my_dialog.properties.primary_key.contains(active_field_list[field_idx]) THEN
                CONTINUE FOR
            END IF
            VAR active = my_dialog.functions.field_active_fn[active_field_list[field_idx]](my_dialog.row_rv)
            CALL my_dialog.d.setFieldActive(active_field_list[field_idx], active)
        END FOR

        VAR ev = my_dialog.d.nextEvent()
        IF ev IS NULL THEN
            EXIT WHILE
        END IF

        CALL my_dialog.dialog2rec() -- parse from dialog into record generically
        CASE
            WHEN ev MATCHES "AFTER FIELD*"
                VAR fieldname = ev.subString(13, ev.getLength())

                IF my_dialog.functions.field_valid_fn.contains(fieldname) THEN
                    VAR ok BOOLEAN
                    VAR error_text STRING
                    VAR my_fv = my_dialog.row_rv.getFieldByName(fieldname)
                    CALL my_dialog.functions.field_valid_fn[fieldname](my_fv) RETURNING ok, error_text
                    IF NOT ok THEN
                        ERROR error_text
                        CALL my_dialog.d.nextField(fieldname)
                        CONTINUE WHILE
                    END IF
                END IF
            WHEN ev = "ON ACTION accept"

                VAR i INTEGER
                -- Validate every field
                FOR i = 1 TO my_dialog.fields.getLength()
                    VAR fieldname = my_dialog.fields[i].name
                    VAR my_fv = my_dialog.row_rv.getFieldByName(fieldname)
                    IF my_dialog.functions.field_valid_fn.contains(fieldname) THEN
                        VAR ok BOOLEAN
                        VAR error_text STRING
                        CALL my_dialog.functions.field_valid_fn[fieldname](my_fv) RETURNING ok, error_text
                        IF NOT ok THEN
                            ERROR error_text
                            CALL my_dialog.d.nextField(fieldname)
                            CONTINUE WHILE
                        END IF
                    END IF
                END FOR

                -- Add mode, need to validate key
                IF add_mode AND my_dialog.functions.key_valid_fn IS NOT NULL THEN
                    VAR ok BOOLEAN
                    VAR error_text STRING
                    VAR fieldname STRING
                    CALL my_dialog.functions.key_valid_fn(my_dialog.row_rv) RETURNING ok, error_text, fieldname
                    IF NOT ok THEN
                        ERROR error_text
                        CALL my_dialog.d.nextField(fieldname)
                        CONTINUE WHILE
                    END IF
                END IF

                -- Validate row
                IF my_dialog.functions.row_valid_fn IS NOT NULL THEN
                    VAR ok BOOLEAN
                    VAR error_text STRING
                    VAR fieldname STRING
                    CALL my_dialog.functions.row_valid_fn(my_dialog.row_rv) RETURNING ok, error_text, fieldname
                    IF NOT ok THEN
                        ERROR error_text
                        CALL my_dialog.d.nextField(fieldname)
                        CONTINUE WHILE
                    END IF
                END IF

                -- should this be first or last?
                CALL my_dialog.d.accept()
            WHEN ev = "ON ACTION cancel"
                LET int_flag = TRUE
                EXIT WHILE
            WHEN ev = "AFTER INPUT"
                EXIT WHILE
        END CASE
    END WHILE
    CALL my_dialog.d.close()

END FUNCTION

-- Determine the fields for the generic dialog by using reflection type on the
PUBLIC FUNCTION (this dialogType) init_fields()
    DEFINE t reflect.Type
    DEFINE i INTEGER
    DEFINE field_count INTEGER

    LET t = this.row_rv.getType()
    LET field_count = t.getFieldCount()
    CALL this.fields.clear()
    FOR i = 1 TO field_count
        LET this.fields[i].name = t.getFieldName(i)
        LET this.fields[i].type = t.getFieldType(i).toString()
    END FOR
END FUNCTION

-- These two functions map the dialog field variables to/from the reflected record by name
PRIVATE FUNCTION (this dialogType) rec2dialog()

    VAR rt = this.row_rv.getType()
    VAR i INTEGER
    VAR count = rt.getFieldCount()
    FOR i = 1 TO COUNT
        CALL this.d.setFieldValue(rt.getFieldName(i), this.row_rv.getField(i).toString())
    END FOR

END FUNCTION

PRIVATE FUNCTION (this dialogType) dialog2rec()

    VAR rt = this.row_rv.getType()
    VAR i INTEGER
    VAR count = rt.getFieldCount()
    FOR i = 1 TO COUNT
        CALL this.row_rv.getField(i).set(reflect.Value.copyOf(this.d.getFieldValue(rt.getFieldName(i))))
    END FOR
END FUNCTION
