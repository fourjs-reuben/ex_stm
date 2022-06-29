IMPORT reflect
IMPORT FGL control
IMPORT FGL user_interface
IMPORT FGL my_table


MAIN
DEFINE rec my_table.tabType

DEFINE my_dialog user_interface.dialogType

    DEFER INTERRUPT
    DEFER QUIT
    OPTIONS FIELD ORDER FORM
    OPTIONS INPUT WRAP
    CLOSE WINDOW SCREEN
    OPEN WINDOW w WITH FORM "dialogrecordinterface"
    
    LET my_dialog.rv = reflect.Value.valueOf(rec)
    
    LET my_dialog.row_default_fn = FUNCTION my_table._row_default
    LET my_dialog.row_valid_fn = FUNCTION my_table._row_valid

    LET my_dialog.field_valid_fn["dmy"] = FUNCTION my_table._dmy_valid
    LET my_dialog.field_valid_fn["num"] = FUNCTION my_table._num_valid
    LET my_dialog.field_valid_fn["amt"] = FUNCTION my_table._amt_valid
    
    CALL control.edit(my_dialog)
    
    CLOSE WINDOW w
    DISPLAY rec.*

END MAIN