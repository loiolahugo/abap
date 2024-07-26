*&---------------------------------------------------------------------*
*& Include          ZHR_VF03_CLS
*&---------------------------------------------------------------------*

CLASS lcl_report DEFINITION.
  PUBLIC SECTION.
    METHODS get_seq
      IMPORTING
        id_vbeln TYPE CHAR10
      RETURNING
        VALUE(rd_output) TYPE int4.
ENDCLASS.
CLASS lcl_report IMPLEMENTATION.
  METHOD get_seq.
    DATA: lv_count TYPE INT4.

    SELECT COUNT(*)
        FROM zht_log_emails
        INTO lv_count
       WHERE vbeln = id_vbeln.

    rd_output = lv_count.
  ENDMETHOD.
ENDCLASS.
