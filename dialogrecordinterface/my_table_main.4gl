IMPORT FGL user_interface
IMPORT FGL my_table
IMPORT FGL my_table_db -- Test database


MAIN
DEFINE my_dialog user_interface.dialogType

    CALL my_table_db.init()

    -- Initialisation Functions 
    CALL my_table.setup_reflection() RETURNING my_dialog.arr_rv, my_dialog.row_rv
    CALL my_dialog.init_fields()
    
    -- Developer sets the properties that don't change
    LET my_dialog.properties.primary_key["id"] = TRUE

    LET my_dialog.properties.table_name = "my_table"
    LET my_dialog.properties.form_name = "my_table"
    LET my_dialog.properties.table_title = "My Example"
    LET my_dialog.properties.field_title["id"] = "ID"
    LET my_dialog.properties.field_title["desc"] = "Desc"
    LET my_dialog.properties.field_title["dmy"] = "Date"
    LET my_dialog.properties.field_title["num"] = "Number"
    LET my_dialog.properties.field_title["amt"] = "Amount"

    -- Developer registers the functions that are used.
    LET my_dialog.functions.row_default_fn = FUNCTION _row_default          # Function to set a new row default value
    LET my_dialog.functions.row_valid_fn = FUNCTION _row_valid              # Function to validate a new row

    LET my_dialog.functions.key_valid_fn = FUNCTION _key_valid              # Function to validate a new row
    
    LET my_dialog.functions.field_valid_fn["dmy"] = FUNCTION _dmy_valid     # Function to validate the date field
    LET my_dialog.functions.field_valid_fn["num"] = FUNCTION _num_valid     # Function to validate the number field
    LET my_dialog.functions.field_valid_fn["amt"] = FUNCTION _amt_valid     # Function to validate the amount field

    LET my_dialog.functions.field_active_fn["amt"] = FUNCTION _amt_active     # Function to validate the amount field
    LET my_dialog.functions.field_visible_fn["amt"] = FUNCTION _amt_visible     # Function to validate the amount field

    -- The UI is run
    CALL user_interface.pre(my_dialog)
    CALL user_interface.maintenance(my_dialog)
    CALL user_interface.post()
END MAIN