IMPORT util
--  Callback Functions
PUBLIC TYPE default_function_type FUNCTION () RETURNS STRING 

PUBLIC TYPE simple_rule_function_type FUNCTION () RETURNS BOOLEAN
PUBLIC TYPE simple_rule_with_error_function_type FUNCTION () RETURNS (BOOLEAN, STRING)

PUBLIC TYPE simple_row_rule_function_type FUNCTION (row INTEGER) RETURNS BOOLEAN
PUBLIC TYPE simple_row_rule_with_error_function_type FUNCTION (row INTEGER) RETURNS (BOOLEAN, STRING)

PUBLIC TYPE value_valid_function_type FUNCTION (value STRING) RETURNS (BOOLEAN, STRING)
PUBLIC TYPE record_valid_function_type FUNCTION () RETURNS (BOOLEAN, STRING, STRING)



-- What information do we have about a database column
PUBLIC TYPE column_type RECORD
    name STRING,
    type STRING,
    key BOOLEAN,
    label STRING,
    notnull BOOLEAN,
    widget STRING,
    widget_properties STRING,
    default_function default_function_type,
    default_qbe_function default_function_type,
    visible_function simple_rule_function_type,
    editable_function simple_rule_function_type, 
    valid_function value_valid_function_type
END RECORD

-- What information do we have about a database table
PUBLIC TYPE table_type RECORD
    name STRING,
    form STRING,
    title STRING,
    order_by STRING,
    where_clause STRING,
 #   set_rec_function set_rec_function_type,   TODO line not necessary?
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


PUBLIC DEFINE stm table_type

DEFINE stm_rec DICTIONARY OF STRING   # ANYRECORD
DEFINE stm_idx INTEGER
DEFINE stm_arr DYNAMIC ARRAY OF RECORD
    column DICTIONARY OF STRING       # ANYRECORD
END RECORD

DEFINE m_key_clause STRING
DEFINE m_update_clause STRING
DEFINE m_insert_column_clause STRING
DEFINE m_insert_values_clause STRING




DEFINE add_mode BOOLEAN
DEFINE d ui.Dialog
DEFINE f ui.Form

DEFINE where_clause STRING

FUNCTION init()
    LET m_key_clause = key_clause()
    LET m_update_clause = update_clause()
    LET m_insert_column_clause = insert_column_clause()
    LET m_insert_values_clause = insert_values_clause()
END FUNCTION


FUNCTION maintain()
DEFINE ok BOOLEAN
DEFINE err_text STRING
DEFINE row INTEGER

    IF stm.form IS NOT NULL THEN
        OPEN WINDOW w WITH FORM stm.form
    ELSE
        OPEN WINDOW w WITH 1 ROWS, 1 COLUMNS
        CALL create_grid(ui.Window.getCurrent().createForm(stm.name).getNode())
    END IF
    LET f = ui.Window.getCurrent().getForm()
    CALL ui.Window.getCurrent().setText(stm.title)
    CALL f.loadActionDefaults("lib_stm")
    CALL f.loadToolBar("lib_stm")
    CALL f.loadTopMenu("lib_stm")

    CALL stm_arr.clear()
    LET stm_idx = 0

    MENU ""
        BEFORE MENU
            CALL menu_state(DIALOG)
            
        ON ACTION query
            IF query() THEN
                CALL populate()
                IF stm_arr.getLength() > 0 THEN
                    LET stm_idx = 1
                    CALL display_row(stm_idx)
                ELSE
                    CALL show_error_dialog("No rows found", FALSE)
                    LET stm_idx = 0
                END IF
            END IF
            CALL menu_state(DIALOG)

        ON ACTION add
            LET add_mode = TRUE
            CALL input() RETURNING ok
            IF ok THEN
                CALL insert_row() RETURNING ok, err_text
                IF ok THEN
                    CALL stm_arr.appendElement()
                    CALL stm_rec.copyTo(stm_arr[stm_arr.getLength()].column)
                ELSE
                    CALL show_error_dialog(SFMT("Could not insert row %1", err_text), TRUE)
                END IF
            ELSE
                CALL show_error_dialog("Row insert cancelled", FALSE)
            END IF
            LET stm_idx = stm_arr.getLength()
            CALL display_row(stm_idx)
            CALL menu_state(DIALOG)

        ON ACTION update
            CALL stm_arr[stm_idx].column.copyTo(stm_rec)
            LET add_mode = FALSE
            CALL input() RETURNING ok
            IF ok THEN
                CALL update_row() RETURNING ok, err_text
                IF ok THEN
                    CALL stm_rec.copyTo(stm_arr[stm_idx].column)
                ELSE
                    CALL show_error_dialog(SFMT("Could not update row %1", err_text), TRUE)
                END IF
            ELSE
                CALL show_error_dialog("Row update cancelled", FALSE)
            END IF
            CALL display_row(stm_idx)
            CALL menu_state(DIALOG)

        ON ACTION remove
            CALL stm_arr[stm_idx].column.copyTo(stm_rec)
            CALL delete_row() RETURNING ok, err_text
            IF ok THEN
                CALL stm_arr.deleteElement(stm_idx)
                IF stm_idx > stm_arr.getLength() THEN
                    LET stm_idx = stm_arr.getLength()
                    IF stm_idx > 0 THEN
                        CALL display_row(stm_idx)
                    ELSE
                        CALL display_clear_row(stm_idx)
                    END IF
                ELSE
                    CALL display_row(stm_idx)
                END IF
                MESSAGE "Row deleted"
            ELSE
                CALL show_error_dialog(SFMT("Could not delete row %1", err_text), TRUE)
            END IF
            CALL menu_state(DIALOG)

        ON ACTION browse
            CALL browse() RETURNING ok, row
            IF ok THEN
                LET stm_idx = row
                CALL display_row(stm_idx)
            END IF
            CALL menu_state(DIALOG)

        ON ACTION bulkadd
            CALL bulkadd()
            CALL menu_state(DIALOG)

        ON ACTION first
            LET stm_idx = 1
            CALL display_row(stm_idx)
            CALL menu_state(DIALOG)

        ON ACTION previous
            LET stm_idx = stm_idx - 1
            CALL display_row(stm_idx)
            CALL menu_state(DIALOG)

        ON ACTION next
            LET stm_idx = stm_idx + 1
            CALL display_row(stm_idx)
            CALL menu_state(DIALOG)

        ON ACTION last
            LET stm_idx = stm_arr.getLength()
            CALL display_row(stm_idx)
            CALL menu_state(DIALOG)

        ON ACTION close
            EXIT MENU
    END MENU

    CLOSE WINDOW w


END FUNCTION


FUNCTION menu_state(d)
DEFINE d ui.Dialog

    CALL d.setActionActive("query", TRUE)
    
    CALL d.setActionActive("add", can_add())
    CALL d.setActionActive("bulkadd", can_add())
    IF stm_arr.getLength() > 0 THEN
        CALL d.setActionActive("browse", TRUE)
        CALL d.setActionActive("update", IIF(can_update(),IIF(can_update_row(stm_idx), TRUE, FALSE), FALSE))
        CALL d.setActionActive("remove",  IIF(can_delete(),IIF(can_delete_row(stm_idx), TRUE, FALSE), FALSE))

        CALL d.setActionActive("first", stm_idx > 1)
        CALL d.setActionActive("previous", stm_idx > 1)
        CALL d.setActionActive("next",  stm_idx < stm_arr.getLength())
        CALL d.setActionActive("last",  stm_idx < stm_arr.getLength())
    ELSE
        CALL d.setActionActive("browse", FALSE)
        CALL d.setActionActive("update", FALSE)
        CALL d.setActionActive("remove", FALSE)
        CALL d.setActionActive("first", FALSE)
        CALL d.setActionActive("previous", FALSE)
        CALL d.setActionActive("next", FALSE)
        CALL d.setActionActive("last", FALSE)
    END IF
END FUNCTION



FUNCTION query()
DEFINE ev STRING

DEFINE sb base.StringBuffer
DEFINE i INTEGER
DEFINE value STRING

    INITIALIZE where_clause TO NULL

    LET add_mode = TRUE
    
    LET d = ui.Dialog.createConstructByName(stm.column)

    CALL d.addTrigger("ON ACTION accept")
    CALL d.addTrigger("ON ACTION cancel")
    CALL d.addTrigger("ON ACTION close")

    WHILE TRUE
        -- Set state
        CALL state()
        
        LET ev = d.nextEvent()
        CASE
            WHEN ev = "BEFORE CONSTRUCT"
                MESSAGE "Enter QBE Criteria"
                --CALL set_qbe_default_values()
                
            WHEN ev MATCHES "BEFORE FIELD*"
                -- CALL before_qbe_field()
            WHEN ev MATCHES "ON CHANGE *"
                -- CALL on_change_field()
            WHEN ev MATCHES "AFTER FIELD*"
                --CALL after_qbe_field()
            WHEN ev  = "ON ACTION close" OR ev = "ON ACTION cancel"
                #LET int_flag = 0 TODO do we need this line
                EXIT WHILE
            WHEN ev = "AFTER CONSTRUCT"
                IF qbe_accept() THEN
                    EXIT WHILE
                END IF
            WHEN ev = "ON ACTION accept"
                CALL d.accept()
            OTHERWISE
                DISPLAY "OTHERWISE ", ev
        END CASE
    END WHILE
    IF int_flag THEN
        LET int_flag = 0
        RETURN FALSE
    END IF

    -- Construct where clause
    LET sb = base.StringBuffer.create()
    FOR i = 1 TO stm.column.getLength()
        LET value = d.getQueryFromField(stm.column[i].name)
        IF value IS NOT NULL THEN
            IF sb.getLength() > 0 THEN
                CALL sb.append(" and ")
            END IF
            CALL sb.append(value)
        END IF
    END FOR
    LET where_clause = sb.toString()
    IF where_clause IS NULL OR where_clause.trim().getLength() = 0 THEN
        LET where_clause = "1=1"
    END IF
    RETURN TRUE
END FUNCTION


FUNCTION populate()
DEFINE hdl base.SqlHandle
DEFINE sql base.StringBuffer
DEFINE row,col INTEGER

    LET sql = base.StringBuffer.create()
    CALL sql.append("select ")
    FOR col = 1 TO stm.column.getLength()
        IF col > 1 THEN
            CALL sql.append(", ")
        END IF
        CALL sql.append(stm.column[col].name)
    END FOR
    CALL sql.append(" from ")
    CALL sql.append(stm.name)
    IF where_clause IS NOT NULL THEN
        CALL sql.append(" where ")
        CALL sql.append(where_clause)
        END IF
    IF stm.order_by IS NOT NULL THEN
        CALL sql.append(" order by ")
        CALL sql.append(stm.order_by)
    END IF
    
    LET hdl = base.SqlHandle.create()
    CALL hdl.prepare(sql.toString())
    CALL hdl.open()

    CALL stm_arr.clear()
    LET row = 0
    
    WHILE TRUE
        CALL hdl.fetch()
        IF SQLCA.SQLCODE==NOTFOUND THEN 
            EXIT WHILE 
        END IF
        LET row = row + 1

        FOR col = 1 TO hdl.getResultCount()
            LET stm_arr[row].column[hdl.getResultName(col)] = hdl.getResultValue(col)
        END FOR        
    END WHILE

    CALL hdl.close()
END FUNCTION



FUNCTION insert_row()
DEFINE hdl base.SqlHandle
DEFINE sql STRING
DEFINE i INTEGER
DEFINE ok BOOLEAN, err_text STRING

    LET sql = SFMT("INSERT INTO %1 (%2) VALUES(%3)", stm.name, m_insert_column_clause, m_insert_values_clause)
    LET hdl = base.SqlHandle.create()
    CALL hdl.prepare(sql)
    
    -- Data fields first
    FOR i = 1 TO stm.column.getLength()
        CALL hdl.setParameter(i, stm_rec[stm.column[i].name])
    END FOR
    
    TRY
        CALL hdl.execute()
        LET ok = TRUE
    CATCH
        LET ok = FALSE
        LET err_text = SQLCA.sqlcode
    END TRY
    CALL hdl.close()
    RETURN ok, err_text
END FUNCTION


FUNCTION update_row()
DEFINE hdl base.SqlHandle
DEFINE sql STRING
DEFINE i,k INTEGER
DEFINE ok BOOLEAN, err_text STRING

    LET sql = SFMT("UPDATE %1 SET %2 WHERE %3", stm.name, m_update_clause, m_key_clause)
    LET hdl = base.SqlHandle.create()
    CALL hdl.prepare(sql)
    LET k = 0
    -- Data fields first
    FOR i = 1 TO stm.column.getLength()
        IF NOT stm.column[i].key THEN
            LET k = k + 1
            CALL hdl.setParameter(k, stm_rec[stm.column[i].name])
        END IF
    END FOR
    -- Then key fields
    FOR i = 1 TO stm.column.getLength()
        IF stm.column[i].key THEN
            LET k = k + 1
            CALL hdl.setParameter(k, stm_rec[stm.column[i].name])
        END IF
    END FOR

    TRY
        CALL hdl.execute()
        LET ok = TRUE
    CATCH
        LET ok = FALSE
        LET err_text = SQLCA.sqlcode
    END TRY
    CALL hdl.close()
    RETURN ok, err_text
END FUNCTION



FUNCTION delete_row()
DEFINE hdl base.SqlHandle
DEFINE sql STRING
DEFINE i,k INTEGER
DEFINE ok BOOLEAN, err_text STRING


    LET sql = SFMT("DELETE FROM %1 WHERE %2", stm.name, m_key_clause)
    
    LET hdl = base.SqlHandle.create()
    CALL hdl.prepare(sql)
    LET k = 0
    FOR i = 1 TO stm.column.getLength()
        IF stm.column[i].key THEN
            LET k = k + 1
            CALL hdl.setParameter(k, stm_rec[stm.column[i].name])
        END IF
    END FOR

    TRY
        CALL hdl.execute()
        LET ok = TRUE
    CATCH
        LET ok = FALSE
        LET err_text = SQLCA.sqlcode
    END TRY
    CALL hdl.close()
    RETURN ok, err_text
END FUNCTION



PRIVATE FUNCTION key_clause()
DEFINE sb base.StringBuffer
DEFINE i INTEGER

   LET sb = base.StringBuffer.create()
    
    FOR i = 1 TO stm.column.getLength()
        IF stm.column[i].key THEN
            IF sb.getLength() > 0  THEN
                CALL sb.append(" and ")
            END IF
            CALL sb.append(sfmt("%1 = ? ", stm.column[i].name))
        END IF
    END FOR
    RETURN sb.toString()
END FUNCTION



PRIVATE FUNCTION update_clause()
DEFINE sb base.StringBuffer
DEFINE i INTEGER

    LET sb = base.StringBuffer.create()
    
    FOR i = 1 TO stm.column.getLength()
        IF NOT stm.column[i].key THEN
            IF sb.getLength() > 0  THEN
                CALL sb.append(" , ")
            END IF
            CALL sb.append(sfmt("%1 = ? ", stm.column[i].name))
        END IF
    END FOR
    RETURN sb.toString()
END FUNCTION



PRIVATE FUNCTION insert_column_clause()
DEFINE sb base.StringBuffer
DEFINE i INTEGER

    LET sb = base.StringBuffer.create()
    
    FOR i = 1 TO stm.column.getLength()
        IF sb.getLength() > 0  THEN
            CALL sb.append(" , ")
        END IF
        CALL sb.append(stm.column[i].name)
    END FOR
    RETURN sb.toString()
END FUNCTION



PRIVATE FUNCTION insert_values_clause()
DEFINE sb base.StringBuffer
DEFINE i INTEGER

    LET sb = base.StringBuffer.create()
    
    FOR i = 1 TO stm.column.getLength()
        IF sb.getLength() > 0  THEN
            CALL sb.append(" , ")
        END IF
        CALL sb.append(" ? ")
    END FOR
    RETURN sb.toString()
END FUNCTION





FUNCTION display_row(row)
DEFINE row INTEGER
DEFINE col INTEGER

    FOR col = 1 TO stm.column.getLength()
        CALL ui.Form.displayTo(stm_arr[row].column[stm.column[col].name], stm.column[col].name, NULL,NULL)
    END FOR
END FUNCTION

FUNCTION display_clear_row(row)
DEFINE row INTEGER
DEFINE col INTEGER

    FOR col = 1 TO stm.column.getLength()
        CALL ui.Form.displayTo(NULL, stm.column[col].name, NULL,NULL)
    END FOR
END FUNCTION



FUNCTION input()
DEFINE ev STRING
DEFINE ok BOOLEAN
DEFINE i INTEGER

    LET d = ui.Dialog.createInputByName(stm.column)

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
                ELSE
                    FOR i = 1 TO stm.column.getLength()
                        CALL d.setFieldValue(stm.column[i].name, stm_rec[stm.column[i].name])
                    END FOR
                END IF
            WHEN ev MATCHES "BEFORE FIELD*"
                -- CALL before_field()
            WHEN ev MATCHES "ON CHANGE *"
                #TODO CALL set_fn(d.getCurrentItem(), d.getFieldValue(d.getCurrentItem()))
                LET stm_rec[d.getCurrentItem()] = d.getFieldValue(d.getCurrentItem())
                -- CALL on_change_field()
            WHEN ev MATCHES "AFTER FIELD*"
                CALL after_field()
            WHEN ev  = "ON ACTION close" OR ev = "ON ACTION cancel"
                LET ok = FALSE
                EXIT WHILE
            WHEN ev = "AFTER INPUT"
                IF accept() THEN
                    LET ok = TRUE
                    EXIT WHILE
                END IF
            WHEN ev = "ON ACTION accept"
                CALL d.accept()
            OTHERWISE
                DISPLAY "OTHERWISE ", ev
        END CASE
    END WHILE

    LET int_flag = 0
    RETURN ok
END FUNCTION









FUNCTION browse()
DEFINE d ui.Dialog
DEFINE ev STRING
DEFINE row, col INTEGER
DEFINE ok BOOLEAN

    OPEN WINDOW browse WITH 1 ROWS, 1 COLUMNS
    CALL create_table(ui.Window.getCurrent().createForm("browse").getNode())
    CALL ui.Window.getCurrent().setText(SFMT("Browse %1", stm.name))
    CALL ui.Window.getCurrent().getForm().loadToolBar("lib_stm_browse")

    LET d = ui.Dialog.createDisplayArrayTo(stm.column,"scr")

    CALL d.setSelectionMode("scr", TRUE)

    CALL d.addTrigger("ON ACTION accept")
    CALL d.addTrigger("ON ACTION close")
    CALL d.addTrigger("ON ACTION cancel")
    
    -- populate
    FOR row = 1 TO stm_arr.getLength()
        CALL d.setCurrentRow("scr",row)
        FOR col = 1 TO stm.column.getLength()
            CALL d.setFieldValue(stm.column[col].name,stm_arr[row].column[stm.column[col].name])
        END FOR
    END FOR

    CALL d.setCurrentRow("scr",stm_idx)
    WHILE TRUE
        LET ev = d.nextEvent()
        CASE ev
            WHEN "ON ACTION close"
                LET ok = FALSE
                EXIT WHILE
            WHEN "ON ACTION cancel"
                LET ok = FALSE
                EXIT WHILE
            WHEN "ON ACTION accept"
                LET ok = TRUE
                LET row = d.getCurrentRow("scr")
                EXIT WHILE
        END CASE

    END WHILE
    CALL d.close()
    
    CLOSE WINDOW browse
    IF ok THEN
        RETURN TRUE, row
    ELSE
        RETURN FALSE, NULL
    END IF

END FUNCTION




FUNCTION bulkadd()
DEFINE d ui.Dialog
DEFINE ev STRING
DEFINE row, col INTEGER

    OPEN WINDOW bulkadd WITH 1 ROWS, 1 COLUMNS
    CALL create_table(ui.Window.getCurrent().createForm("bulkadd").getNode())
    CALL ui.Window.getCurrent().setText(SFMT("Bulk Add %1", stm.name))
    CALL ui.Window.getCurrent().getForm().loadToolBar("lib_stm_bulkadd")

    LET d = ui.Dialog.createInputArrayFrom(stm.column,"scr")

    CALL d.addTrigger("ON ACTION accept")
    CALL d.addTrigger("ON ACTION cancel")
    CALL d.addTrigger("ON ACTION close")

    CALL d.setCurrentRow("scr",1)
    WHILE TRUE
        LET ev = d.nextEvent()
        CASE ev
            WHEN "ON ACTION accept"
                EXIT WHILE
            WHEN "ON ACTION cancel"
                EXIT WHILE
            WHEN "ON ACTION close"
                EXIT WHILE
        END CASE

    END WHILE
    CALL d.close()
    
    CLOSE WINDOW bulkadd

END FUNCTION



PRIVATE FUNCTION state()
DEFINE i INTEGER
DEFINE vfn simple_rule_function_type
DEFINE efn simple_rule_function_type
DEFINE value BOOLEAN

    FOR i = 1 TO stm.column.getLength()
        LET vfn = stm.column[i].visible_function
        LET value = vfn()
        CALL f.setFieldHidden(stm.column[i].name, NOT value)

        LET efn = stm.column[i].editable_function
        LET value = efn()
        CALL d.setFieldActive(stm.column[i].name, value AND ((NOT add_mode AND NOT stm.column[i].key) OR add_mode))
    END FOR
END FUNCTION



PRIVATE FUNCTION qbe_state()
DEFINE i INTEGER
DEFINE vfn simple_rule_function_type
DEFINE efn simple_rule_function_type
DEFINE value BOOLEAN

    FOR i = 1 TO stm.column.getLength()
        LET vfn = stm.column[i].visible_function
        LET value = vfn()
        -- Only show field based on value and current value in combobox
        CALL f.setFieldHidden(SFMT("%1_expression",stm.column[i].name), NOT value)
    END FOR
END FUNCTION



PRIVATE FUNCTION set_default_values()
DEFINE i INTEGER
DEFINE value STRING
DEFINE fn default_function_type

    FOR i = 1 TO stm.column.getLength()
        LET fn = stm.column[i].default_function
        LET value = fn()
        LET stm_rec[stm.column[i].name]= value
        CALL d.setFieldValue(stm.column[i].name, value)
    END FOR
END FUNCTION



PRIVATE FUNCTION set_default_qbe_values()
DEFINE i INTEGER
DEFINE value STRING
DEFINE fn default_function_type
    
    FOR i = 1 TO stm.column.getLength()
        LET fn = stm.column[i].default_qbe_function
        LET value = fn()
        CALL d.setFieldValue(stm.column[i].name, value)
    END FOR
END FUNCTION



PRIVATE FUNCTION before_field()
END FUNCTION



PRIVATE FUNCTION on_change_field()
    -- TODO move field into record
END FUNCTION




PRIVATE FUNCTION after_field()
DEFINE fn value_valid_function_type
DEFINE value STRING
DEFINE idx INTEGER
DEFINE ok BOOLEAN
DEFINE error_text STRING

    LET idx = get_data_column_idx(d.getCurrentItem())
    LET fn = stm.column[idx].valid_function
    LET value = d.getFieldValue(d.getCurrentItem())
    CALL fn(value) RETURNING ok, error_text
    IF NOT ok THEN
        CALL show_error_dialog(error_text, TRUE)
        CALL d.nextField("+CURR")
    END IF
END FUNCTION



PRIVATE FUNCTION accept()

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


    -- Test key stm.column
    IF add_mode THEN
        -- Individually test every key field
        FOR i = 1 TO stm.column.getLength()
            IF stm.column[i].key THEN
                IF first_key_field IS NULL THEN
                    LET first_key_field = stm.column[i].name
                END IF
                
                LET fn = stm.column[i].valid_function
                LET value = d.getFieldValue(stm.column[i].name)
                CALL fn(value) RETURNING ok, error_text

                # TODO investigate why the line below cant be used instead of 3 above
                #CALL stm.column[i].valid_function(d.getFieldValue(stm.column[i].name)) RETURNING ok, error_text
                
                IF NOT ok THEN
                    CALL show_error_dialog(error_text, TRUE)
                    CALL d.nextField(stm.column[i].name)
                    RETURN FALSE
                END IF
            END IF
        END FOR

        LET kfn = stm.key_valid_function
        CALL kfn() RETURNING ok, error_text, fieldname
        IF NOT ok THEN
            CALL show_error_dialog(error_text, TRUE)
            CALL d.nextField(nvl(fieldname,first_key_field))
            RETURN FALSE
        END IF
    END IF

    -- Individually test every remaining data field
    FOR i = 1 TO stm.column.getLength()
        IF NOT stm.column[i].key THEN
            IF first_data_field IS NULL THEN
                LET first_data_field = stm.column[i].name
            END IF
            LET fn = stm.column[i].valid_function
            LET value = d.getFieldValue(stm.column[i].name)
            CALL fn(value) RETURNING ok, error_text
            IF NOT ok THEN
                CALL show_error_dialog(error_text, TRUE)
                CALL d.nextField(stm.column[i].name)
                RETURN FALSE
            END IF
        END IF
    END FOR
    
    LET dfn = stm.data_valid_function
    CALL dfn() RETURNING ok, error_text, fieldname
    IF NOT ok THEN
        CALL show_error_dialog(error_text, TRUE)
        CALL d.nextField(nvl(fieldname,first_data_field))
        RETURN FALSE
    END IF    
    RETURN TRUE
END FUNCTION



PRIVATE FUNCTION qbe_accept()
    RETURN TRUE
END FUNCTION


PUBLIC FUNCTION create_grid(parent_node om.DomNode)
DEFINE vbox_node, group_node, grid_node, field_node, label_node, widget_node om.DomNode
DEFINE i,j,k INTEGER

DEFINE json_attributes util.JSONObject

    CALL parent_node.setAttribute("minWidth",80)
    CALL parent_node.setAttribute("minHeight",25)

    LET vbox_node = parent_node.createChild("VBox") -- TODO Do without VBOX so can use GRIDCHILDRENINPARENT
    -- Two group boxes, one for key fields, one for data fields
    FOR j = 1 TO 2
        LET group_node = vbox_node.createChild("Group")
        CALL group_node.setAttribute("text", IIF(j=1,"Key Field(s)", "Data Field(s)"))
        LET grid_node = group_node.createChild("Grid")
        FOR i = 1 To stm.column.getLength()
            IF j = 1 AND stm.column[i].key 
            OR j = 2 AND NOT stm.column[i].key THEN
                LET label_node =  grid_node.createChild("Label")
                CALL label_node.setAttribute("posX",0)
                CALL label_node.setAttribute("posY",i-1)
                CALL label_node.setAttribute("text", stm.column[i].label)
                CALL label_node.setAttribute("gridWidth", 10)
        
                LET field_node = grid_node.createChild("FormField")
                CALL field_node.setAttribute("name",SFMT("formonly.%1",stm.column[i].name))
                CALL field_node.setAttribute("colName",stm.column[i].name)
                CALL field_node.setAttribute("fieldId",i-1)
                CALL field_node.setAttribute("sqlTabName","formonly")
                CALL field_node.setAttribute("tabIndex",i)
                IF stm.column[i].notnull THEN
                    CALL field_node.setAttribute("notNull", "1")
                END IF

                LET widget_node = field_node.createChild(nvl(stm.column[i].widget,"Edit"))
                CALL widget_node.setAttribute("posX", 10)
                CALL widget_node.setAttribute("posY", i-1)
                CALL widget_node.setAttribute("width", 10)
                CALL widget_node.setAttribute("gridWidth", 10)

                IF stm.column[i].widget_properties IS NOT NULL THEN
                    LET json_attributes = util.JSONObject.parse(stm.column[i].widget_properties)
                    FOR k = 1 TO json_attributes.getLength()
                        CALL widget_node.setAttribute(json_attributes.name(k), json_attributes.get(json_attributes.name(k)))
                    END FOR
                END IF
            END IF
        END FOR
    END FOR

    -- add a stretchable element at bottom of vbox to eat the remaining space
    LET grid_node = vbox_node.createChild("Grid")
    LET widget_node = grid_node.createChild("Image")
    CALL widget_node.setAttribute("posX", 0)
    CALL widget_node.setAttribute("posY", i)
    CALL widget_node.setAttribute("width", 20)
    CALL widget_node.setAttribute("gridWidth", 20)
    CALL widget_node.setAttribute("image","empty")
    CALL widget_node.setAttribute("sizePolicy", "stretch")
    CALL widget_node.setAttribute("stretch", "both")
END FUNCTION



FUNCTION create_table(parent_node om.DomNode)
DEFINE vbox_node, table_node, tablecolumn_node, widget_node, recordview_node, link_node om.DomNode
DEFINE i INTEGER

    CALL parent_node.setAttribute("minWidth",60)
    CALL parent_node.setAttribute("minHeight",15)
    LET vbox_node = parent_node.createChild("VBox")
    LET table_node = vbox_node.createChild("Table")

    -- Create table node
    CALL table_node.setAttribute("pageSize",15)
    CALL table_node.setAttribute("name","tab_browse")
    CALL table_node.setAttribute("style", "browse")
    CALL table_node.setAttribute("height", "15ln")
    CALL table_node.setAttribute("tabName", "scr")
    CALL table_node.setAttribute("doubleClick", "accept")
    
    -- TableColumn nodes
    FOR i = 1 TO stm.column.getLength()
       
       LET tablecolumn_node = table_node.createChild("TableColumn")
       
       CALL tablecolumn_node.setAttribute("name",SFMT("formonly.%1", stm.column[i].name)) 
       CALL tablecolumn_node.setAttribute("sqlTabName","formonly")
       CALL tablecolumn_node.setAttribute("colName",stm.column[i].name)  
       CALL tablecolumn_node.setAttribute("fieldId",(i-1) USING "<&")

       CALL tablecolumn_node.setAttribute("tabIndex", i USING "&")
       CALL tablecolumn_node.setAttribute("sqlType", stm.column[i].type)
       CALL tablecolumn_node.setAttribute("text", stm.column[i].label)

       LET widget_node = tablecolumn_node.createChild("Edit")
       CALL widget_node.setAttribute("width", 10)  #TODO

       #IF m_zoom.column[i].format IS NOT NULL THEN
       #    CALL widget_node.setAttribute("format", m_zoom.column[i].format)
       #END IF
       
       #IF m_zoom.column[i].justify IS NOT NULL THEN
       #    CALL widget_node.setAttribute("justify", m_zoom.column[i].justify)
       #END IF
    END FOR

    -- Create record view
    LET recordview_node = parent_node.createChild("RecordView")
    CALL recordview_node.setAttribute("tabName","formonly")

    -- Link nodes
    FOR i = 1 TO stm.column.getLength()
        LET link_node = recordview_node.createChild("Link")
        CALL link_node.setAttribute("colName",stm.column[i].name)
        CALL link_node.setAttribute("fieldIdRef",(i-1) USING "<&")
    END FOR
   

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

    FOR i = 1 TO stm.column.getLength()
        IF stm.column[i].name = name THEN
            RETURN i
        END IF
    END FOR
    EXIT PROGRAM 1 #TODO
END FUNCTION



PRIVATE FUNCTION show_error_dialog(text STRING, wait BOOLEAN)
    IF wait THEN
        CALL FGL_WINMESSAGE("Error", text, "stop")
    ELSE
        ERROR text
    END IF
END FUNCTION





{
-- This is a more advanced qbe
FUNCTION qbe()
DEFINE ev STRING
DEFINE where_clause STRING
DEFINE sb base.StringBuffer
DEFINE i INTEGER
DEFINE value STRING

DEFINE qbe DYNAMIC ARRAY OF RECORD
    i, da DYNAMIC ARRAY OF RECORD
        name, type STRING
    END RECORD
END RECORD

    IF stm.form IS NOT NULL THEN
        OPEN WINDOW w WITH FORM stm.form
    ELSE
        OPEN WINDOW w WITH 1 ROWS, 1 COLUMNS
        CALL create_qbe_grid(ui.Window.getCurrent().createForm(stm.name).getNode())
    END IF

    LET f = ui.Window.getCurrent().getForm()
    CALL ui.Window.getCurrent().setText(stm.title)
    
   LET d = ui.Dialog.createMultipleDialog()
    -- Global actions
    CALL d.addTrigger("ON ACTION accept")
    CALL d.addTrigger("ON ACTION cancel")
    CALL d.addTrigger("ON ACTION close")

    -- For each field, add an INPUT, and a DISPLAY ARRAY
    FOR i = 1 TO stm.column.getLength()
        LET qbe[i].i[1].name = SFMT("%1_expression", stm.column[i].name)
        LET qbe[i].i[1].type = "STRING"
        LET qbe[i].i[2].name = SFMT("%1_value", stm.column[i].name)
        LET qbe[i].i[2].type = stm.column[i].type
        LET qbe[i].i[3].name = SFMT("%1_from", stm.column[i].name)
        LET qbe[i].i[3].type = stm.column[i].type
        LET qbe[i].i[4].name = SFMT("%1_to", stm.column[i].name)
        LET qbe[i].i[4].type = stm.column[i].type
        LET qbe[i].i[5].name = SFMT("%1_matches", stm.column[i].name)
        LET qbe[i].i[5].type = "STRING"

        CALL d.addInputByName(qbe[i].i, SFMT("qbe_%1", stm.column[i].name))
       # CALL d.addTrigger(SFMT("ON CHANGE %1_expression", stm.column[i].name))
    END FOR
    FOR i = 1 TO stm.column.getLength()
      #  CALL d.addDisplayArrayTo(qbe[i].da, SFMT("%1_da", stm.column[i].name))
    END FOR


    
    WHILE TRUE
        -- Set state
        CALL qbe_state()
        
        LET ev = d.nextEvent()
        DISPLAy ev
        CASE
            WHEN ev = "BEFORE DIALOG"
                FOR i = 1 TO stm.column.getLength()
                    CALL f.setFieldHidden(SFMT("%1_value",stm.column[i].name), TRUE)
                    CALL f.setFieldHidden(SFMT("%1_from", stm.column[i].name), TRUE)
                    CALL f.setFieldHidden(SFMT("%1_to", stm.column[i].name), TRUE)
                    CALL f.setFieldHidden(SFMT("%1_matches", stm.column[i].name), TRUE)
                    CALL f.setElementHidden(SFMT("%1_list", stm.column[i].name), TRUE)
                END FOR

            WHEN ev MATCHES "ON CHANGE *"
                DISPLAY "ON CHANGE"
                CALL on_change_qbe_field(ev)
                

            WHEN ev  = "ON ACTION close" OR ev = "ON ACTION cancel"
                #LET int_flag = 0 TODO do we need this line
                EXIT WHILE
            WHEN ev = "AFTER DIALOG"
                IF 1=1 THEN
                    EXIT WHILE
                END IF
            WHEN ev = "ON ACTION accept"
                CALL d.accept()
                -- qbe_accept
            OTHERWISE
                DISPLAY "OTHERWISE ", ev
        END CASE
    END WHILE

    --LET sb = base.StringBuffer.create()
    --FOR i = 1 TO stm.column.getLength()
        --LET value = d.getQueryFromField(stm.column[i].name)
        --IF value IS NOT NULL THEN
            --IF sb.getLength() > 0 THEN
                --CALL sb.append(" and ")
            --END IF
            --CALL sb.append(value)
        --END IF
    --END FOR
    --LET where_clause =sb.toString()
    
END FUNCTION


PUBLIC FUNCTION create_qbe_grid(parent_node om.DomNode)
DEFINE vbox_node, group_node, grid_node, field_node, label_node, widget_node, item_list_node, item_node om.DomNode
DEFINE i,j,k INTEGER

DEFINE json_attributes util.JSONObject

DEFINE field_count INTEGER

    LET field_count = 0

    LET vbox_node = parent_node.createChild("VBox") -- TODO Do without VBOX so can use GRIDCHILDRENINPARENT
    -- Two group boxes, one for key fields, one for data fields
    FOR j = 1 TO 2
        LET group_node = vbox_node.createChild("Group")
        CALL group_node.setAttribute("text", IIF(j=1,"Key Field(s)", "Data Field(s)"))
        LET grid_node = group_node.createChild("Grid")
        FOR i = 1 To stm.column.getLength()
            IF j = 1 AND stm.column[i].key 
            OR j = 2 AND NOT stm.column[i].key THEN

                --Label Expression Value From To Matches
            
                LET label_node =  grid_node.createChild("Label")
                CALL label_node.setAttribute("posX",0)
                CALL label_node.setAttribute("posY",i-1)
                CALL label_node.setAttribute("text", stm.column[i].label)
                CALL label_node.setAttribute("gridWidth", 10)

                -- Expression ComboBox
                LET field_count = field_count + 1
                LET field_node = grid_node.createChild("FormField")
                CALL field_node.setAttribute("name",SFMT("formonly.%1_expression",stm.column[i].name))
                CALL field_node.setAttribute("colName",SFMT("%1_expression",stm.column[i].name))
                CALL field_node.setAttribute("fieldId",field_count-1)
                CALL field_node.setAttribute("sqlTabName","formonly")
                CALL field_node.setAttribute("tabIndex",field_count)
                IF stm.column[i].notnull THEN
                    CALL field_node.setAttribute("notNull", "1")
                END IF

                LET widget_node = field_node.createChild("ComboBox")
                CALL widget_node.setAttribute("posX", 10)
                CALL widget_node.setAttribute("posY", i-1)
                CALL widget_node.setAttribute("width", 10)
                CALL widget_node.setAttribute("gridWidth", 10)
                -- Add items
                CALL combo_expression(widget_node)
               

                

                -- Value Widget
                LET field_count = field_count + 1
                LET field_node = grid_node.createChild("FormField")
                CALL field_node.setAttribute("name",SFMT("formonly.%1_value",stm.column[i].name))
                CALL field_node.setAttribute("colName",SFMT("%1_value",stm.column[i].name))
                CALL field_node.setAttribute("fieldId",field_count-1)
                CALL field_node.setAttribute("sqlTabName","formonly")
                CALL field_node.setAttribute("tabIndex",field_count)

                LET widget_node = field_node.createChild(nvl(stm.column[i].widget,"Edit"))
                CALL widget_node.setAttribute("posX", 20)
                CALL widget_node.setAttribute("posY", i-1)
                CALL widget_node.setAttribute("width", 10)
                CALL widget_node.setAttribute("gridWidth", 10)

                IF stm.column[i].widget_properties IS NOT NULL THEN
                    LET json_attributes = util.JSONObject.parse(stm.column[i].widget_properties)
                    FOR k = 1 TO json_attributes.getLength()
                        CALL widget_node.setAttribute(json_attributes.name(k), json_attributes.get(json_attributes.name(k)))
                    END FOR
                END IF

                -- From Widget
                LET field_count = field_count + 1
                LET field_node = grid_node.createChild("FormField")
                CALL field_node.setAttribute("name",SFMT("formonly.%1_from",stm.column[i].name))
                CALL field_node.setAttribute("colName",SFMT("%1_from",stm.column[i].name))
                CALL field_node.setAttribute("fieldId",field_count-1)
                CALL field_node.setAttribute("sqlTabName","formonly")
                CALL field_node.setAttribute("tabIndex",field_count)

                LET widget_node = field_node.createChild(nvl(stm.column[i].widget,"Edit"))
                CALL widget_node.setAttribute("posX", 30)
                CALL widget_node.setAttribute("posY", i-1)
                CALL widget_node.setAttribute("width", 10)
                CALL widget_node.setAttribute("gridWidth", 10)

                IF stm.column[i].widget_properties IS NOT NULL THEN
                    LET json_attributes = util.JSONObject.parse(stm.column[i].widget_properties)
                    FOR k = 1 TO json_attributes.getLength()
                        CALL widget_node.setAttribute(json_attributes.name(k), json_attributes.get(json_attributes.name(k)))
                    END FOR
                END IF
                
                -- To Widget
                LET field_count = field_count + 1
                LET field_node = grid_node.createChild("FormField")
                CALL field_node.setAttribute("name",SFMT("formonly.%1_to",stm.column[i].name))
                CALL field_node.setAttribute("colName",SFMT("%1_to",stm.column[i].name))
                CALL field_node.setAttribute("fieldId",field_count-1)
                CALL field_node.setAttribute("sqlTabName","formonly")
                CALL field_node.setAttribute("tabIndex",field_count)

                LET widget_node = field_node.createChild(nvl(stm.column[i].widget,"Edit"))
                CALL widget_node.setAttribute("posX", 40)
                CALL widget_node.setAttribute("posY", i-1)
                CALL widget_node.setAttribute("width", 10)
                CALL widget_node.setAttribute("gridWidth", 10)

                IF stm.column[i].widget_properties IS NOT NULL THEN
                    LET json_attributes = util.JSONObject.parse(stm.column[i].widget_properties)
                    FOR k = 1 TO json_attributes.getLength()
                        CALL widget_node.setAttribute(json_attributes.name(k), json_attributes.get(json_attributes.name(k)))
                    END FOR
                END IF

                -- Matches Widget
                LET field_count = field_count + 1
                LET field_node = grid_node.createChild("FormField")
                CALL field_node.setAttribute("name",SFMT("formonly.%1_matches",stm.column[i].name))
                CALL field_node.setAttribute("colName",SFMT("%1_matches",stm.column[i].name))
                CALL field_node.setAttribute("fieldId",field_count-1)
                CALL field_node.setAttribute("sqlTabName","formonly")
                CALL field_node.setAttribute("tabIndex",field_count)

                LET widget_node = field_node.createChild("Edit")
                CALL widget_node.setAttribute("posX", 50)
                CALL widget_node.setAttribute("posY", i-1)
                CALL widget_node.setAttribute("width", 10)
                CALL widget_node.setAttribute("gridWidth", 10)

                -- Add table array for list
                


                
        
                
                
            END IF
        END FOR
    END FOR

    -- add a stretchable element at bottom of vbox to eat the remaining space
    LET grid_node = vbox_node.createChild("Grid")
    LET widget_node = grid_node.createChild("Image")
    CALL widget_node.setAttribute("posX", 0)
    CALL widget_node.setAttribute("posY", i)
    CALL widget_node.setAttribute("width", 20)
    CALL widget_node.setAttribute("gridWidth", 20)
    CALL widget_node.setAttribute("image","empty")
    CALL widget_node.setAttribute("sizePolicy", "stretch")
    CALL widget_node.setAttribute("stretch", "both")

    DISPLAY vbox_node.toString()
END FUNCTION

PRIVATE FUNCTION combo_expression(combo_node)
DEFINE combo_node, item_node om.DomNode

    &define item_add(p1,p2) LET item_node = combo_node.createChild("Item") \
    CALL item_node.setAttribute("name",p1) \
    CALL item_node.setAttribute("text",p2)

    item_add("all","ALL values")
    item_add("null","is blank (null)")
    item_add("notnull","is not blank")
    item_add("equal","equals")
    item_add("notequal"," is not equal to ")
    item_add("greater","is greater than")
    item_add("greatere","is greater or equal to")
    item_add("less","is less than")
    item_add("lesse","is less than or equal to")
    item_add("begin","begin with")
    item_add("end","ends with")
    item_add("contain","contains")
    item_add("like","is like")
    item_add("between","is between")
    item_add("betweenn","is not between")
    item_add("in", "is in")
    item_add("inn","is not in")
    
END FUNCTION

PRIVATE FUNCTION on_change_qbe_field(ev)
DEFINE ev STRING
DEFINE field_name STRING
DEFINE pos INTEGER
    LET field_name = ev.subString(10,ev.getLength())
    IF field_name MATCHES "*expression" THEN
        LET pos = field_name.getIndexOf("_expression",1)
        LET field_name = field_name.subString(1, pos-1)
        DISPLAY "ON CHANGE",field_name
    END IF
END FUNCTION

#TODO when bug fixed that allows back in
#PUBLIC TYPE set_rec_function_type FUNCTION (dict DICTIONARY OF STRING) 
}