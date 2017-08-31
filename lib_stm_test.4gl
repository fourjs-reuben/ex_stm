IMPORT FGL lib_stm_testdata
IMPORT FGL lib_stm

IMPORT FGL state



MAIN
    CLOSE WINDOW SCREEN
    DEFER INTERRUPT
    DEFER QUIT
    OPTIONS FIELD ORDER FORM
    OPTIONS INPUT WRAP
    CALL ui.Dialog.setDefaultUnbuffered(TRUE)
    CALL ui.Interface.loadStyles("lib_stm")
    CALL ui.Interface.loadActionDefaults("lib_stm")
    CONNECT TO ":memory:"

    
    IF NOT lib_stm_testdata.create() THEN
        DISPLAY "Error creating test data"
    END IF
    IF NOT lib_stm_testdata.populate() THEN
        DISPLAY "Error populating test data"
    END IF

    CALL state.init()
    CALL lib_stm.maintain()

END MAIN