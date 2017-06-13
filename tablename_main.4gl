IMPORT FGL lib_stm            -- UI
IMPORT FGL tablename          -- Business Rules

MAIN

    -- Set functions in tablename that will be called from ddinput
    CALL tablename.init()
    CALL lib_stm.input()
END MAIN