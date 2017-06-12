Introduction
 
The Single Table maintenance program is one of the most common design patterns we will see in a Genero application suite.  As the name suggests it is a program that is responsible for allowing users to view and edit data in a single table.  In a typical ERP system, you will see over a hundred of these programs with names such as “Customer Maintenance”, “Product Maintenance”, “Supplier Maintenance”, “Branch Maintenance”, “Store Maintenance”, “Rep Maintenance”, “GL Code Maintenance” etc
 
Genero developers are constantly striving for ways to improve the way they code these applications so that they are in particular consistent in behaviour across the application, and easy to code and maintain.  This leads to development of code generators such as FourGen and our more recent BAM that try to improve the way these programs are coded.
 
By simplifying the way these programs are produced, it leaves more time to concentrate on the programs that the customer is really paying for.  For example an ERP provider might decide to add a new module in a new area of business for them e.g. Warehousing.  The customer is more interested in paying for the programs that lead to more effective use of the warehouse then they are in paying for the single table maintenance “Warehouse Maintenance” program.  The ISV is therefore looking for ways to do these single table maintenance programs as effectively as possible so that they can devote more time to the “money” programs.

Reubens Ideal Design

My ideal design for a Generic Single Table Maintenance program is based around the fact that in preparing the specifications for such a program, the business rules/program that apply will be based on the following questions ...

Table Level 
 
Can I see this table?

FUNCTION tablename_visible()
    RETURN TRUE|FALSE
END FUNCTION

Can I add a row in this table?

FUNCTION tablename_add()
     RETURN TRUE|FALSE
END FUNCTION

Can I change a row in this table?

FUNCTION tablename_update()
     RETURN TRUE|FALSE
END FUNCTION

Can I delete a row in this table?

FUNCTION tablename_delete()
     RETURN TRUE|FALSE
END FUNCTION

What rows are displayed initially

FUNCTION tablename_initial_row()
   RETURN where-clause
END FUNCTION

What order are rows displayed

FUNCTION tablename_initial_order()
   RETURN orderby-clause
END FUNCTION

At the row level ... 
 
Can I see this row?

FUNCTION tablename_row_visible(row INTEGER)
    RETURN TRUE|FALSE
END FUNCTION

Can I update this row in this table?

FUNCTION tablename_row_update(row INTEGER)
     RETURN TRUE|FALSE
END FUNCTION

Can I delete a row in this table?

FUNCTION tablename_row_delete(row INTEGER)
     RETURN TRUE|FALSE
END FUNCTION

Is this row valid?

FUNCTION tablename_row_valid(row INTEGER)
     RETURN TRUE|FALSE, row INTEGER, errortext STRING
END FUNCTION

Is this row key valid?

FUNCTION tablename_key_valid(row INTEGER)
     RETURN TRUE|FALSE, row INTEGER, errortext STRING
END FUNCTION

At the column level ...
 
Can I see this column?

FUNCTION tablename_columnname_visible()
    RETURN TRUE|FALSE
END FUNCTION

Can I change this column? 

FUNCTION tablename_columnname_update()
     RETURN TRUE|FALSE
END FUNCTION

What is the column default value?

FUNCTION tablename_columnname_default()
     RETURN defaultvalue STRING
END FUNCTION

Is the entered value valid

FUNCTION tablename_columnname_valid(value)
    RETURN TRUE|FALSE, errortext STRING
END FUNCTION
 
At the widget level ...
 
For COMBOBOX’s, an SQL 

FUNCTION tablename_columnname_combobox_init(cb ui.ComboBox)
END FUNCTION

For zooms/lookup etc
FUNCTION tablename_columnname_zoom(value)
   RETURN value
END FUNCTION
etc
etc
 
 
In coding a single table maintenance program, a junior developer should just be concerned with answering and coding these questions, and placing them in the appropriately named function.  The junior developer does not need to be concerned with the framework and skeleton for the program, after-all it is the same for all single table maintenance programs so that we have a consistent user interface.
 
By using the new generic/dialog functionality, this framework can be coded by a senior developer once, and it is then made available to the junior developers to fill the gaps, the gaps being these functions with the business logic.

Other Design Criterion

A second design criterion I have is that the same logic should apply no matter what the user interface.  So if uploading values via a web-service, I should be able to write a generic upload program that uses the same tablename_row_valid(), tablename_column_valid() functions (and other functions as appropriate).

Further Expansion

There are other patterns in an application suite.  The next two after this I would look at the starter pattern, and the master-detail pattern
