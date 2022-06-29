IMPORT reflect

-- Field
TYPE field_title_fn_type FUNCTION(rv reflect.Value) RETURNS(STRING)
TYPE field_active_fn_type FUNCTION(rv reflect.Value) RETURNS(BOOLEAN)
TYPE field_visible_fn_type FUNCTION(rv reflect.Value) RETURNS(BOOLEAN)
TYPE field_default_fn_type FUNCTION(rv reflect.Value) RETURNS()
TYPE field_valid_fn_type FUNCTION(rv reflect.Value) RETURNS(BOOLEAN, STRING)


-- Row
TYPE row_default_fn_type FUNCTION(rv reflect.Value)
TYPE row_valid_fn_type FUNCTION(rv reflect.Value) RETURNS(BOOLEAN, STRING, STRING)

-- Record


TYPE dynamic_dialogs_field_type DYNAMIC ARRAY OF RECORD
name, type STRING
END RECORD


PUBLIC TYPE dialogType RECORD
    d ui.Dialog,
    fields dynamic_dialogs_field_type,
    rv reflect.Value,
    field_title_fn DICTIONARY OF field_title_fn_type,
    field_active_fn DICTIONARY OF field_active_fn_type,
    field_visible_fn DICTIONARY OF field_visible_fn_type,
    field_default_fn DICTIONARY OF field_default_fn_type,
    field_valid_fn DICTIONARY OF field_valid_fn_type,
    row_default_fn row_default_fn_type,
    row_valid_fn row_valid_fn_type
END RECORD



FUNCTION (this dialogType) init_fields(t reflect.Type)
    VAR i INTEGER
    VAR field_count  = t.getFieldCount()
    CALL this.fields.clear()
    FOR i = 1 TO field_count
        LET this.fields[i].name = t.getFieldName(i)
        LET this.fields[i].type = t.getFieldType(i).toString()
    END FOR
END FUNCTION


FUNCTION (this dialogType) create_input()

    CALL this.init_fields(this.rv.getType())
    LET this.d = ui.Dialog.createInputByName(this.fields)
END FUNCTION




FUNCTION (this dialogType) rec2dialog()

    VAR rt = this.rv.getType()
    VAR i INTEGER
    VAR count =  rt.getFieldCount()
    FOR i = 1 TO count
        CALL this.d.setFieldValue(rt.getFieldName(i), this.rv.getField(i).toString())
    END FOR

END FUNCTION

FUNCTION (this dialogType) dialog2rec()

    VAR rt = this.rv.getType()
    VAR i INTEGER
    VAR count =  rt.getFieldCount()
    FOR i = 1 TO count
        CALL this.rv.getField(i).set(reflect.Value.copyOf(this.d.getFieldValue(rt.getFieldName(i))))
    END FOR
END FUNCTION








