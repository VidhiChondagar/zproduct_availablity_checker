CLASS zproduct_availablity_checker DEFINITION
  PUBLIC CREATE PUBLIC.

  PUBLIC SECTION.
    INTERFACES if_oo_adt_classrun.

  PRIVATE SECTION.

    "------------------------------------------------------------
    " 1.  Console handle (valid everywhere in the class)
    "------------------------------------------------------------
    DATA mo_out TYPE REF TO if_oo_adt_classrun_out.

    "------------------------------------------------------------
    " 2.  Local types – Cloud‑safe
    "------------------------------------------------------------
    TYPES: BEGIN OF ty_movement,
             product_id    TYPE c LENGTH 10,
             movement_date TYPE d,
             qty_in        TYPE i,
             qty_out       TYPE i,
           END   OF ty_movement.

    TYPES: BEGIN OF ty_product,
             product_id   TYPE c LENGTH 10,
             product_name TYPE c LENGTH 50,
             category     TYPE c LENGTH 20,
             stock        TYPE i,
           END   OF ty_product.

    TYPES: BEGIN OF ty_report,
             product_id    TYPE c LENGTH 10,
             product_name  TYPE c LENGTH 50,
             available_qty TYPE i,
           END   OF ty_report.

    "------------------------------------------------------------
    " 3.  Internal tables
    "------------------------------------------------------------
    DATA lt_products TYPE STANDARD TABLE OF ty_product WITH EMPTY KEY.
    DATA lt_moves    TYPE STANDARD TABLE OF ty_movement WITH EMPTY KEY.
    DATA lt_report   TYPE STANDARD TABLE OF ty_report  WITH EMPTY KEY.

    "------------------------------------------------------------
    " 4.  Helper methods
    "------------------------------------------------------------
    METHODS get_data
      IMPORTING i_from TYPE d
                i_to   TYPE d.

    METHODS calculate_availability.
    METHODS print_report
      IMPORTING i_from TYPE d
                i_to   TYPE d.

ENDCLASS.



CLASS zproduct_availablity_checker IMPLEMENTATION.
  METHOD if_oo_adt_classrun~main.

    mo_out = out.                            " <‑‑ keep console reference

    DATA lv_from TYPE d VALUE '20250701'.
    DATA lv_to   TYPE d VALUE '20250705'.

    me->get_data( i_from = lv_from i_to = lv_to ).
    me->calculate_availability( ).
    me->print_report( i_from = lv_from i_to = lv_to ).

  ENDMETHOD.
  METHOD get_data.

    SELECT product_id,
           product_name,
           category,
           stock
      FROM zproducts
      INTO TABLE @lt_products.

   SELECT product_id,
       movement_date,
       quantity_in   AS qty_in,
       quantity_out  AS qty_out
  FROM zproducts_mov
  WHERE movement_date BETWEEN @i_from AND @i_to
  INTO TABLE @lt_moves.

  ENDMETHOD.
  METHOD calculate_availability.

    CLEAR lt_report.

    LOOP AT lt_products INTO DATA(ls_prod).

      DATA(lv_in)  = 0.
      DATA(lv_out) = 0.

      LOOP AT lt_moves INTO DATA(ls_move)
           WHERE product_id = ls_prod-product_id.
        lv_in  += ls_move-qty_in.
        lv_out += ls_move-qty_out.
      ENDLOOP.

      DATA(lv_avail) = ls_prod-stock + lv_in - lv_out.

      APPEND VALUE ty_report(
               product_id    = ls_prod-product_id
               product_name  = ls_prod-product_name
               available_qty = lv_avail ) TO lt_report.

    ENDLOOP.

    SORT lt_report BY available_qty DESCENDING.

  ENDMETHOD.
  METHOD print_report.

    mo_out->write( |==================================================| ).
    mo_out->write( |           PRODUCT AVAILABILITY REPORT           | ).
    mo_out->write( |Period: { i_from } → { i_to }| ).
    mo_out->write( |==================================================| ).
    mo_out->write( |ID    Product Name                     Avail Qty| ).
    mo_out->write( |------------------------------------------------| ).

    LOOP AT lt_report INTO DATA(ls_rep).
      DATA(lv_line) =
        |{ ls_rep-product_id WIDTH = 6 } |
        && |{ ls_rep-product_name WIDTH = 30 } |
        && |{ ls_rep-available_qty ALIGN = RIGHT }|.
      mo_out->write( lv_line ).
    ENDLOOP.

    mo_out->write( |==================================================| ).

  ENDMETHOD.

ENDCLASS.
