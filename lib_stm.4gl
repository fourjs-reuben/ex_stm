IMPORT util
--  Callback Functions
PUBLIC TYPE default_function_type FUNCTION () RETURNS STRING 

PUBLIC TYPE simple_rule_function_type FUNCTION () RETURNS BOOLEAN
PUBLIC TYPE simple_rule_with_error_function_type FUNCTION () RETURNS (BOOLEAN, STRING)

PUBLIC TYPE simple_row_rule_function_type FUNCTION (row INTEGER) RETURNS BOOLEAN
PUBLIC TYPE simple_row_rule_with_error_function_type FUNCTION (row INTEGER) RETURNS (BOOLEAN, STRING)

PUBLIC TYPE value_valid_function_type FUNCTION (value STRING) RETURNS (BOOLEAN, STRING)
PUBLIC TYPE record_valid_function_type FUNCTION() RETURNS (BOOLEAN, STRING, STRING)

PUBLIC TYPE set_function_type FUNCTION (fieldname STRING, value STRING)
PUBLIC TYPE get_function_type FUNCTION (fieldname STRING) RETURNS (STRING)

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
    set set_function_type,
    get get_function_type,
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
DEFINE set_fn set_function_type

    LET set_fn = data.set 

    IF data.form IS NOT NULL THEN
        OPEN WINDOW w WITH FORM data.form
    ELSE
        OPEN WINDOW w WITH 1 ROWS, 1 COLUMNS
        CALL create_grid(ui.Window.getCurrent().createForm(data.name).getNode())
    END IF

    LET f = ui.Window.getCurrent().getForm()
    CALL ui.Window.getCurrent().setText(data.title)

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
                CALL set_fn(d.getCurrentItem(), d.getFieldValue(d.getCurrentItem()))
                -- CALL on_change_field()
            WHEN ev MATCHES "AFTER FIELD*"
                CALL after_field()
            WHEN ev  = "ON ACTION close" OR ev = "ON ACTION cancel"
                #LET int_flag = 0 TODO do we need this line
                EXIT WHILE
            WHEN ev = "AFTER INPUT"
                IF accept() THEN
                    EXIT WHILE
                END IF
            WHEN ev = "ON ACTION accept"
                CALL d.accept()
            OTHERWISE
                DISPLAY "OTHERWISE ", ev
        END CASE
    END WHILE
    
END FUNCTION





PRIVATE FUNCTION state()
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



PRIVATE FUNCTION set_default_values()
DEFINE i INTEGER
DEFINE value STRING
DEFINE fn default_function_type
DEFINE set_fn set_function_type

    LET set_fn = data.set

    FOR i = 1 TO data.column.getLength()
        LET fn = data.column[i].default_function
        LET value = fn()
        CALL d.setFieldValue(data.column[i].name, value)
        CALL set_fn(data.column[i].name, value)
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
    LET fn = data.column[idx].valid_function
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

                # TODO investigate why the line below cant be used instead of 3 above
                #CALL data.column[i].valid_function(d.getFieldValue(data.column[i].name)) RETURNING ok, error_text
                
                IF NOT ok THEN
                    CALL show_error_dialog(error_text, TRUE)
                    CALL d.nextField(data.column[i].name)
                    RETURN FALSE
                END IF
            END IF
        END FOR

        LET kfn = data.key_valid_function
        CALL kfn() RETURNING ok, error_text, fieldname
        IF NOT ok THEN
            CALL show_error_dialog(error_text, TRUE)
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
                CALL show_error_dialog(error_text, TRUE)
                CALL d.nextField(data.column[i].name)
                RETURN FALSE
            END IF
        END IF
    END FOR
    
    LET dfn = data.data_valid_function
    CALL dfn() RETURNING ok, error_text, fieldname
    IF NOT ok THEN
        CALL show_error_dialog(error_text, TRUE)
        CALL d.nextField(nvl(fieldname,first_data_field))
        RETURN FALSE
    END IF    
    RETURN TRUE
END FUNCTION



PUBLIC FUNCTION create_grid(parent_node om.DomNode)
DEFINE vbox_node, group_node, grid_node, field_node, label_node, widget_node om.DomNode
DEFINE i,j,k INTEGER

DEFINE json_attributes util.JSONObject

    LET vbox_node = parent_node.createChild("VBox") -- TODO Do without VBOX so can use GRIDCHILDRENINPARENT
    -- Two group boxes, one for key fields, one for data fields
    FOR j = 1 TO 2
        LET group_node = vbox_node.createChild("Group")
        CALL group_node.setAttribute("text", IIF(j=1,"Key Field(s)", "Data Field(s)"))
        LET grid_node = group_node.createChild("Grid")
        FOR i = 1 To data.column.getLength()
            IF j = 1 AND data.column[i].key 
            OR j = 2 AND NOT data.column[i].key THEN
                LET label_node =  grid_node.createChild("Label")
                CALL label_node.setAttribute("posX",0)
                CALL label_node.setAttribute("posY",i-1)
                CALL label_node.setAttribute("text", data.column[i].label)
                CALL label_node.setAttribute("gridWidth", 10)
        
                LET field_node = grid_node.createChild("FormField")
                CALL field_node.setAttribute("name",SFMT("formonly.%1",data.column[i].name))
                CALL field_node.setAttribute("colName",data.column[i].name)
                CALL field_node.setAttribute("fieldId",i-1)
                CALL field_node.setAttribute("sqlTabName","formonly")
                CALL field_node.setAttribute("tabIndex",i)
                IF data.column[i].notnull THEN
                    CALL field_node.setAttribute("notNull", "1")
                END IF

                LET widget_node = field_node.createChild(nvl(data.column[i].widget,"Edit"))
                CALL widget_node.setAttribute("posX", 10)
                CALL widget_node.setAttribute("posY", i-1)
                CALL widget_node.setAttribute("width", 10)
                CALL widget_node.setAttribute("gridWidth", 10)

                IF data.column[i].widget_properties IS NOT NULL THEN
                    LET json_attributes = util.JSONObject.parse(data.column[i].widget_properties)
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


FUNCTION create_table_sql()
DEFINE i INTEGER
DEFINE sb base.StringBuffer

    LET sb = base.StringBuffer.create()
    FOR i = 1 TO data.column.getLength()
        IF i > 1 THEN
            CALL sb.append(", ")
        END IF
        CALL sb.append(SFMT("%1 %2", data.column[i].name, data.column[i].type))
    END FOR
    RETURN sb.toString()
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


PRIVATE FUNCTION show_error_dialog(text STRING, wait BOOLEAN)
    IF wait THEN
        CALL FGL_WINMESSAGE("Error", text, "stop")
    ELSE
        ERROR text
    END IF
END FUNCTION



