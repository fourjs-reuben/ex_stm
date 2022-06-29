IMPORT FGL user_interface
IMPORT reflect



FUNCTION edit(my_dialog user_interface.dialogType)

    CALL my_dialog.create_input()
    CALL my_dialog.d.addTrigger("ON ACTION accept")  
    CALL my_dialog.d.addTrigger("ON ACTION cancel")

    CALL my_dialog.row_default_fn(my_dialog.rv)
    CALL my_dialog.rec2dialog()

    WHILE TRUE
        VAR ev = my_dialog.d.nextEvent()
        IF ev IS NULL THEN
            EXIT WHILE
        END IF
        
        CALL my_dialog.dialog2rec()
        CASE 
            WHEN ev MATCHES "AFTER FIELD*" 
                VAR fieldname = ev.subString(13,ev.getLength())

                IF my_dialog.field_valid_fn.contains(fieldname) THEN
                    VAR ok BOOLEAN
                    VAR error_text STRING
                    VAR my_fv = my_dialog.rv.getFieldByName(fieldname)
                    CALL my_dialog.field_valid_fn[fieldname](my_fv) RETURNING ok, error_text
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
                    VAR my_fv = my_dialog.rv.getFieldByName(fieldname)
                    IF my_dialog.field_valid_fn.contains(fieldname) THEN
                        VAR ok BOOLEAN
                        VAR error_text STRING
                        CALL my_dialog.field_valid_fn[fieldname](my_fv) RETURNING ok, error_text
                        IF NOT ok THEN
                            ERROR error_text
                            CALL my_dialog.d.nextField(fieldname)
                            CONTINUE WHILE
                        END IF
                    END IF
                END FOR
                

                -- Validate row
                IF 1=1 THEN
                    VAR ok BOOLEAN
                    VAR error_text STRING
                    VAR fieldname STRING
                    CALL my_dialog.row_valid_fn(my_dialog.rv) RETURNING ok, error_text, fieldname
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
