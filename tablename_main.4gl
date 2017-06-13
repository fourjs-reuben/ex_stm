IMPORT FGL lib_stm            -- UI
IMPORT FGL tablename          -- Business Rules

MAIN
    CLOSE WINDOW SCREEN
    DEFER INTERRUPT
    DEFER QUIT
    OPTIONS FIELD ORDER FORM
    OPTIONS INPUT WRAP
    
    CALL tablename.init()
    DISPLAY lib_stm.create_table_sql()
    CALL lib_stm.input()
END MAIN