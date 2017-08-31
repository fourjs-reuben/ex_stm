IMPORT FGL lib_stm            -- UI
IMPORT FGL tablename          -- Business Rules

MAIN
    CLOSE WINDOW SCREEN
    DEFER INTERRUPT
    DEFER QUIT
    OPTIONS FIELD ORDER FORM
    OPTIONS INPUT WRAP
    CALL ui.Dialog.setDefaultUnbuffered(TRUE)

    CALL tablename.init()
    CALL lib_stm.qbe()
END MAIN