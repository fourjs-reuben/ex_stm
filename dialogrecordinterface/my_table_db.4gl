

FUNCTION init()

    CONNECT TO ":memory:+driver='dbmsqt'"

    CREATE TABLE my_table(
        id INTEGER,
        desc CHAR(20),
        dmy DATE,
        num INTEGER,
        amt DECIMAL(11,2))

    INSERT INTO my_table VALUES(1,"Aaa", TODAY, 1, 1.11)
    INSERT INTO my_table VALUES(2,"Bbb", TODAY, 2, 2.22)
    INSERT INTO my_table VALUES(3,"Ccc", TODAY, 3, 3.33)
END FUNCTION

