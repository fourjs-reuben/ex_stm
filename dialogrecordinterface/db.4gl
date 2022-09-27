IMPORT reflect

FUNCTION populate(arr_rv reflect.Value, table_name STRING, where_clause STRING, order_clause STRING)
DEFINE h base.SqlHandle
DEFINE col INTEGER
DEFINE row_rv, field_rv reflect.Value

    LET h = base.SqlHandle.create()

    CALL h.prepare(SFMT("SELECT * FROM %1 WHERE %2 ORDER BY %3", table_name, where_clause, order_clause))
    CALL h.open()
    WHILE TRUE
        CALL h.fetch()
        IF sqlca.sqlcode ==NOTFOUND THEN
            EXIT WHILE
        END IF
        CALL arr_rv.appendArrayElement()
        LET row_rv = arr_rv.getArrayElement(arr_rv.getLength())
        
        FOR col = 1 TO h.getResultCount()
            LET field_rv = row_rv.getFieldByName(h.getResultName(col))
            CALL field_rv.set(reflect.Value.copyOf(h.getResultValue(col)))
        END FOR
    END WHILE
    CALL h.close()    
END FUNCTION

FUNCTION select(row_rv reflect.Value, table_name STRING, key_list DICTIONARY OF STRING)
DEFINE h base.SqlHandle
DEFINE col INTEGER
DEFINE field_rv reflect.Value


DEFINE key_arr DYNAMIC ARRAY OF STRING
DEFINE key_idx INTEGER


    LET h = base.SqlHandle.create()

    CALL h.prepare(SFMT("SELECT * FROM %1 WHERE %2", table_name, key_clause(key_list)))
    CALL h.open()

    LET key_arr = key_list.getKeys() 
    FOR key_idx = 1 TO key_arr.getLength()
        LET field_rv = row_rv.getFieldByName(key_arr[key_idx])
        CALL h.setParameter(key_idx, field_rv.toString()  )
    END FOR
    
    CALL h.fetch()
    IF sqlca.sqlcode ==NOTFOUND THEN
    ELSE
    
        FOR col = 1 TO h.getResultCount()
            LET field_rv = row_rv.getFieldByName(h.getResultName(col))
            CALL field_rv.set(reflect.Value.copyOf(h.getResultValue(col)))
        END FOR
    END IF
    
    CALL h.close()    
END FUNCTION



FUNCTION insert()

END FUNCTION



FUNCTION update()

END FUNCTION



FUNCTION delete(row_rv reflect.Value, table_name STRING, key_list DICTIONARY OF STRING)
DEFINE h base.SqlHandle
DEFINE field_rv reflect.Value

DEFINE key_arr DYNAMIC ARRAY OF STRING
DEFINE key_idx INTEGER

    LET h = base.SqlHandle.create()

    CALL h.prepare(SFMT("DELETE FROM %1 WHERE %2", table_name, key_clause(key_list)))
    CALL h.open()

    LET key_arr = key_list.getKeys() 
    FOR key_idx = 1 TO key_arr.getLength()
        LET field_rv = row_rv.getFieldByName(key_arr[key_idx])
        CALL h.setParameter(key_idx, field_rv.toString()  )
    END FOR    
    CALL h.execute()
    CALL h.close()    
END FUNCTION



PRIVATE FUNCTION key_clause(key_list DICTIONARY OF STRING)
DEFINE sb base.StringBuffer
DEFINE key_arr DYNAMIC ARRAY OF STRING
DEFINE key_idx INTEGER

    LET key_arr = key_list.getKeys() 
    LET sb = base.StringBuffer.create()
    FOR key_idx = 1 TO key_arr.getLength()
        IF key_idx > 1 THEN
            CALL sb.append(" AND ")
        END IF
        CALL sb.append(SFMT(" %1 = ? ", key_arr[key_idx]))
    END FOR
    RETURN sb.toString()
END FUNCTION

