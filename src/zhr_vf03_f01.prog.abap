*&---------------------------------------------------------------------*
*& Include          ZHR_VF03_F01
*&---------------------------------------------------------------------*

*&---------------------------------------------------------------------*
*& Form F_SELECIONA_DADOS
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM f_seleciona_dados .
  DATA: lt_data TYPE TABLE OF ty_data,
        ls_data TYPE ty_data.

  SELECT vbrp~vbeln vbrp~posnr vbrp~arktx vbrp~werks
         vbrp~fkimg vbrp~vgbel vbrp~matnr vbrk~vkorg
         vbrk~zterm vbrk~fkdat vbrk~waerk vbrk~knumv
         vbrk~vtweg vbrk~spart vbrk~pltyp vbrp~vgpos
    FROM vbrp
    JOIN vbrk
      ON vbrp~vbeln = vbrk~vbeln
    INTO TABLE gt_data
   WHERE vbrp~vbeln IN s_vbeln
     AND vbrp~matnr IN s_matnr
     AND vbrk~vkorg IN s_vkorg
     AND vbrk~fkdat IN s_data
     AND vbrp~vgbel IN s_remes.

  IF gt_data IS NOT INITIAL.
    SELECT vbeln posnr vgbel vgpos matkl
      FROM lips
      INTO TABLE gt_lips
       FOR ALL ENTRIES IN gt_data
     WHERE lips~vbeln = gt_data-vgbel.

    IF gt_lips IS NOT INITIAL.
      SELECT vbeln posnr vgpos matkl
        FROM vbap
        INTO TABLE gt_vbap
         FOR ALL ENTRIES IN gt_lips
       WHERE vbap~vbeln = gt_lips-vgbel
         AND vbap~posnr = gt_lips-vgpos
         AND vbap~matkl IN s_grupo.

      IF s_grupo IS NOT INITIAL.
        SORT: gt_lips BY vgbel vgpos,
              gt_data BY vgbel vgpos.

        LOOP AT gt_vbap INTO gs_vbap.
          CLEAR: gs_lips, ls_data.

          READ TABLE gt_lips INTO gs_lips
            WITH KEY vgbel = gs_vbap-vbeln
                     vgpos = gs_vbap-posnr
                     BINARY SEARCH.

          IF sy-subrc = 0.
            READ TABLE gt_data INTO ls_data
              WITH KEY vgbel = gs_lips-vbeln
                       vgpos = gs_lips-posnr
                       BINARY SEARCH.

            APPEND ls_data TO lt_data.
          ENDIF.
        ENDLOOP.

        IF lt_data IS INITIAL.
          MESSAGE 'Nenhum registro encontrado.' TYPE 'S' DISPLAY LIKE 'E'.
          LEAVE LIST-PROCESSING.
        ENDIF.

        gt_data = lt_data.
      ENDIF.

      SELECT vbeln kunnr auart
        FROM vbak
        INTO TABLE gt_vbak
         FOR ALL ENTRIES IN gt_lips
       WHERE vbak~vbeln = gt_lips-vgbel.

      SELECT vbeln posnr zterm inco1 inco2
        FROM vbkd
        INTO TABLE gt_vbkd
         FOR ALL ENTRIES IN gt_lips
       WHERE vbeln = gt_lips-vgbel.
    ENDIF.

    IF gt_data IS NOT INITIAL.
      SELECT zterm vtext spras
        FROM tvzbt
        INTO TABLE gt_zterm
         FOR ALL ENTRIES IN gt_data
       WHERE tvzbt~zterm = gt_data-zterm
         AND tvzbt~spras = sy-langu.

      SELECT knumv kposn kwert kbetr  kschl
        FROM prcd_elements
        INTO TABLE gt_imposto
         FOR ALL ENTRIES IN gt_data
       WHERE prcd_elements~knumv = gt_data-knumv.

      SELECT vbeln kodat tragr
        FROM likp
        INTO TABLE gt_likp
         FOR ALL ENTRIES IN gt_data
       WHERE likp~vbeln = gt_data-vgbel.
    ENDIF.

    IF gt_likp IS NOT INITIAL.
      SELECT vtext tragr
        FROM ttgrt
        INTO TABLE gt_ttgrt
         FOR ALL ENTRIES IN gt_likp
       WHERE ttgrt~tragr = gt_likp-tragr
         AND ttgrt~spras = sy-langu.
    ENDIF.

    IF gt_vbak IS NOT INITIAL.
      SELECT bezei auart
        FROM tvakt
        INTO TABLE gt_tvakt
         FOR ALL ENTRIES IN gt_vbak
       WHERE tvakt~auart = gt_vbak-auart
         AND tvakt~spras = sy-langu.

      SELECT bezei auart
        FROM tvakt
        INTO TABLE gt_tvakt
         FOR ALL ENTRIES IN gt_vbak
       WHERE tvakt~auart = gt_vbak-auart
         AND tvakt~spras = sy-langu.
    ENDIF.

    IF gt_vbkd IS NOT INITIAL.
      SELECT vtext zterm
        FROM tvzbt
        INTO TABLE gt_tvzbt
         FOR ALL ENTRIES IN gt_vbkd
       WHERE tvzbt~zterm = gt_vbkd-zterm2
         AND tvzbt~spras = sy-langu.
    ENDIF.

    IF gt_vbap IS NOT INITIAL.
      SELECT wgbez matkl
        FROM t023t
        INTO TABLE gt_t023t
       WHERE t023t~spras = sy-langu.
    ENDIF.

    SELECT *
      FROM zht_log_emails
      INTO TABLE gt_log_emails
       FOR ALL ENTRIES IN gt_data
     WHERE zht_log_emails~vbeln = gt_data-vbeln.

  ELSE.
    MESSAGE 'Nenhum registro encontrado.' TYPE 'S' DISPLAY LIKE 'E'.
    LEAVE LIST-PROCESSING.
  ENDIF.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form f_monta_tabela_saida
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM f_monta_tabela_saida.

  DATA: lt_lips          TYPE TABLE OF ty_lips,
        lt_lines2        TYPE TABLE OF tline,
        lv_thead         LIKE thead,
        ls_lines2        TYPE tline,
        lv_item          TYPE string,
        lv_select        TYPE string,
        ls_vbrp          TYPE ty_vbrp,
        ls_vbrk          TYPE ty_vbrk,
        ls_zterm         TYPE ty_tvzbt,
        ls_vbkd          TYPE ty_vbkd,
        ls_tvzbt         TYPE ty_tvzbt,
        ls_t023t         TYPE ty_t023t,
        ls_ttgrt         TYPE ty_ttgrt,
        ls_prcd_elements TYPE prcd_elements,
        ls_likp          TYPE ty_likp,
        ls_tvakt         TYPE ty_tvakt,
        ls_vbuk          TYPE ty_vbuk.

  SORT: gt_imposto    BY knumv kposn kschl ,
        gt_log_emails BY vbeln type,
        gt_vbap       BY vbeln posnr,
        gt_vbkd       BY vbeln2 posnr,
        lt_lips       BY vbeln,
        gt_icon       BY name,
        gt_zterm      BY zterm,
        gt_likp       BY vbeln,
        gt_ttgrt      BY tragr,
        gt_vbak       BY vbeln,
        gt_tvakt      BY auart,
        gt_vbkd       BY vbeln2,
        gt_tvzbt      BY zterm.

  LOOP AT gt_data INTO gs_data.
    CLEAR: ls_vbrp          ,
           ls_vbrk          ,
           ls_zterm         ,
           ls_vbkd          ,
           ls_tvzbt         ,
           ls_t023t         ,
           ls_ttgrt         ,
           ls_prcd_elements ,
           ls_likp          ,
           ls_tvakt         ,
           ls_vbuk          ,
           gs_imposto       .

    READ TABLE gt_imposto INTO gs_imposto
      WITH KEY knumv = gs_data-knumv
               kposn = gs_data-posnr
               kschl = 'JR1'
               BINARY SEARCH.
    IF sy-subrc <> 0.
      gs_imposto-kwert = '0'.
    ENDIF.

    IF gs_imposto-kwert = '0' OR gs_data-waerk <> 'USD'.
      gs_saida-icon = icon_led_red.
    ELSEIF gs_imposto-kwert > '0' AND gs_imposto-kwert < '2'.
      gs_saida-icon = icon_led_yellow.
    ELSE.
      gs_saida-icon = icon_led_green.
    ENDIF.

    gs_saida-vbeln  = gs_data-vbeln .  " Código da fatura
    gs_saida-posnr  = gs_data-posnr .  " Item
    gs_saida-arktx  = gs_data-arktx .  " Descrição do material
    gs_saida-werks  = gs_data-werks .  " Centro
    gs_saida-fkimg  = gs_data-fkimg .  " Quantidade faturada
    gs_saida-vgbel  = gs_data-vgbel .  " Número da remessa
    gs_saida-matnr  = gs_data-matnr .  " Material
    gs_saida-vkorg  = gs_data-vkorg .  " Organização de vendas
    gs_saida-zterm  = gs_data-zterm .  " Condição de pagamento
    gs_saida-fkdat  = gs_data-fkdat .  " Data de faturamento
    gs_saida-waerk  = gs_data-waerk .  " Moeda do documento

    CLEAR ls_zterm.
    READ TABLE gt_zterm INTO ls_zterm
      WITH KEY zterm = gs_data-zterm
        BINARY SEARCH.
    IF sy-subrc IS INITIAL.
      CONCATENATE gs_saida-zterm '-' ls_zterm-vtext
             INTO gv_linha SEPARATED BY space.

      gs_saida-zterm  = gv_linha.     " Condição de pagamento + descrição
    ENDIF.

    CLEAR gs_imposto.
    READ TABLE gt_imposto INTO gs_imposto
      WITH KEY knumv = gs_data-knumv
               kposn = gs_data-posnr
               kschl = 'JR1'
               BINARY SEARCH.
    IF sy-subrc IS INITIAL.
      gs_saida-kwert  = gs_imposto-kwert.
    ENDIF.

    CLEAR gs_imposto.
    READ TABLE gt_imposto INTO gs_imposto
      WITH KEY knumv = gs_data-knumv
               kposn = gs_data-posnr
               kschl = 'PCIP'

               BINARY SEARCH.
    IF sy-subrc IS INITIAL.
      gs_saida-kwert1  = gs_imposto-kwert.
    ENDIF.

    CLEAR ls_likp.
    READ TABLE gt_likp INTO ls_likp
      WITH KEY vbeln = gs_data-vgbel
        BINARY SEARCH.
    IF sy-subrc IS INITIAL.
      gs_saida-kodat  = ls_likp-kodat. " Data de picking
      CLEAR gs_saida-tragr.

      READ TABLE gt_ttgrt INTO ls_ttgrt
        WITH KEY tragr = ls_likp-tragr
          BINARY SEARCH.
      IF ls_likp-tragr IS NOT INITIAL.
        CONCATENATE ls_likp-tragr '-' ls_ttgrt-vtext
               INTO gv_linha SEPARATED BY space.
      ENDIF.
      gs_saida-tragr  = gv_linha.     " Grupo de transporte
    ENDIF.

    IF sy-subrc IS INITIAL.
      gs_saida-vtext1  = ls_ttgrt-vtext.
    ENDIF.

    READ TABLE gt_lips INTO gs_lips
      WITH KEY vbeln = gs_data-vgbel
               posnr = gs_data-vgpos
        BINARY SEARCH.

    READ TABLE gt_vbak INTO gs_vbak
      WITH KEY vbeln = gs_lips-vgbel
        BINARY SEARCH.

    IF sy-subrc IS INITIAL.
      gs_saida-kunnr  =  gs_vbak-kunnr. " Cliente

      READ TABLE gt_tvakt INTO ls_tvakt
        WITH KEY auart = gs_vbak-auart
          BINARY SEARCH.

      CONCATENATE gs_vbak-auart '-' ls_tvakt-bezei
             INTO gv_linha SEPARATED BY space.

      gs_saida-auart   = gv_linha.      " Tipo de ordem
      gs_saida-vbeln1  = gs_vbak-vbeln. " Ordem de venda
    ENDIF.

    READ TABLE gt_vbkd INTO ls_vbkd
      WITH KEY vbeln2 = gs_vbak-vbeln
        BINARY SEARCH.
    IF sy-subrc IS INITIAL.
      READ TABLE gt_tvzbt INTO ls_tvzbt
        WITH KEY zterm = ls_vbkd-zterm2
          BINARY SEARCH.

      CONCATENATE ls_vbkd-zterm2 '-' ls_tvzbt-vtext
             INTO gv_linha SEPARATED BY space.

      gs_saida-zterm2  = gv_linha.     " Código de pagamento 2
      gs_saida-inco1   = ls_vbkd-inco1." Incoterms 1
      gs_saida-inco2   = ls_vbkd-inco2." Incoterms 2
    ENDIF.

    READ TABLE gt_vbap INTO gs_vbap
      WITH KEY vbeln = gs_vbak-vbeln
               posnr = gs_lips-vgpos
        BINARY SEARCH.

    IF sy-subrc IS INITIAL.
      READ TABLE gt_t023t INTO ls_t023t
        WITH KEY matkl = gs_vbap-matkl
          BINARY SEARCH.
      IF sy-subrc = 0.
        CONCATENATE gs_vbap-matkl '-' ls_t023t-wgbez
               INTO gv_linha SEPARATED BY space.
      ELSE.
        gv_linha = gs_vbap-matkl.
      ENDIF.
      gs_saida-matkl  = gv_linha.     " Grupo de mercadorias
    ENDIF.

    lv_item = gs_data-vbeln && gs_data-posnr.
    lv_thead-tdid     = '0001'.
    lv_thead-tdspras  = 'EN'.
    lv_thead-tdobject = 'VBBP'.
    lv_thead-tdname   = lv_item.

    CALL FUNCTION 'READ_TEXT'
      EXPORTING
        id                      = lv_thead-tdid
        language                = lv_thead-tdspras
        name                    = lv_thead-tdname
        object                  = lv_thead-tdobject
      TABLES
        lines                   = lt_lines2
      EXCEPTIONS
        id                      = 1
        language                = 2
        name                    = 3
        not_found               = 4
        object                  = 5
        reference_check         = 6
        wrong_access_to_archive = 7.

    READ TABLE lt_lines2 INTO ls_lines2
         INDEX 1.
    gs_saida-lines2  = ls_lines2-tdline. " Texto de vendas de material
    REFRESH lt_lines2.
    CLEAR ls_lines2.

    CLEAR gs_log_emails.
    READ TABLE gt_log_emails INTO gs_log_emails
      WITH KEY vbeln = gs_saida-vbeln
               type = 'Ordem de venda'
        BINARY SEARCH.
    gs_saida-ordvenda = gs_log_emails-vbelngerado. " Ordem gerada
    CLEAR gs_log_emails.

    READ TABLE gt_log_emails INTO gs_log_emails
      WITH KEY vbeln = gs_saida-vbeln
               type = 'Remessa'
        BINARY SEARCH.
    gs_saida-remessa = gs_log_emails-vbelngerado. " Remessa gerada
    CLEAR gs_log_emails.

    READ TABLE gt_log_emails INTO gs_log_emails
      WITH KEY vbeln = gs_saida-vbeln
               type = 'Fatura'
        BINARY SEARCH.
    gs_saida-fatura = gs_log_emails-vbelngerado.  " Fatura gerada
    CLEAR gs_log_emails.

    gs_saida-log = icon_history.

    APPEND gs_saida TO gt_saida.
  ENDLOOP.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form f_fieldcat
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM f_fieldcat TABLES pt_fcat TYPE lvc_t_fcat.

  PERFORM f_fill_fieldcat TABLES pt_fcat USING:
  " FIELDNAME;  TABNAME;  COLTEXT;  ICON;  SUM;   EDIT;
   'ICON'          ''     TEXT-024   'X'    ''     '',    " Status
   'LOG'           ''     TEXT-027   ''     ''     '',    " Log
   'VBELN'         ''     TEXT-002   ''     ''     '',    " Código da fatura
   'POSNR'         ''     TEXT-003   ''     ''     '',    " Item
   'MATNR'         ''     TEXT-004   ''     ''     '',    " Material
   'ARKTX'         ''     TEXT-005   ''     ''     '',    " Descrição do material
   'WERKS'         ''     TEXT-006   ''     ''     '',    " Centro
   'FKIMG'         ''     TEXT-007   ''     ''     '',    " Quantidade faturada
   'VKORG'         ''     TEXT-008   ''     ''     '',    " Organização de vendas
   'ZTERM'         ''     TEXT-009   ''     ''     '',    " Condição de pagamento
   'FKDAT'         ''     TEXT-011   ''     ''     '',    " Data de faturamento
   'WAERK'         ''     TEXT-012   ''     ''     '',    " Moeda do documento
   'VGBEL'         ''     TEXT-013   ''     ''     '',    " Número da remessa
   'KWERT'         ''     TEXT-014   ''     ''     '',    " Valor do JR1
   'KWERT1'        ''     TEXT-023   ''     ''     '',    " Preço Interno
   'KODAT'         ''     TEXT-015   ''     ''     '',    " Data de picking
   'TRAGR'         ''     TEXT-016   ''     ''     '',    " Grupo de transporte
   'KUNNR'         ''     TEXT-017   ''     ''     '',    " Cliente
   'AUART'         ''     TEXT-018   ''     ''     '',    " Tipo de ordem
   'VBELN1'        ''     TEXT-019   ''     ''     '',    " Ordem de venda
   'ZTERM2'        ''     TEXT-020   ''     ''     '',    " Código de pagamento
   'INCO1'         ''     TEXT-021   ''     ''     '',    " Incoterms
   'MATKL'         ''     TEXT-022   ''     ''     '',    " Grupo de mercadorias
   'LINES2'        ''     TEXT-025   ''     ''     '',    " Texto de vendas de material
   'ORDVENDA'      ''     TEXT-026   ''     ''     '',    " Nova Ordem de venda
   'REMESSA'       ''     TEXT-035   ''     ''     '',    " Nova Remessa
   'FATURA'        ''     TEXT-036   ''     ''     ''.    " Novo Faturamento


ENDFORM.

*&---------------------------------------------------------------------
*& Form F_FILL_FIELDCAT
*&---------------------------------------------------------------------
*& Preenche o catálogo de campos do relatório
*&---------------------------------------------------------------------
FORM f_fill_fieldcat TABLES pt_fcat TYPE lvc_t_fcat
                      USING p_fieldname TYPE any
                            p_tabname   TYPE any
                            p_coltext   TYPE any
                            p_icon      TYPE any
                            p_sum       TYPE any
                            p_edit      TYPE any.

  DATA: ls_fieldcat TYPE lvc_s_fcat.

  ls_fieldcat-fieldname = p_fieldname.
  ls_fieldcat-tabname   = p_tabname.
  ls_fieldcat-coltext   = p_coltext.
  ls_fieldcat-icon      = p_icon.
  ls_fieldcat-do_sum    = p_sum.
  ls_fieldcat-col_opt   = 'X'.
  ls_fieldcat-no_zero   = 'X'.
  ls_fieldcat-edit      = p_edit.
  ls_fieldcat-checkbox  = p_edit.

  IF ls_fieldcat-fieldname = 'LOG'.
    ls_fieldcat-hotspot = 'X'.
  ENDIF.

  APPEND ls_fieldcat TO pt_fcat.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form f_imprime_alv
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM f_imprime_alv.
  DATA: lt_fieldcat TYPE lvc_t_fcat,
        lt_sort     TYPE lvc_t_sort,
        ls_sort     TYPE lvc_s_sort,
        ls_layout   TYPE lvc_s_layo.

  PERFORM f_fieldcat TABLES lt_fieldcat.

* Ordena
  CLEAR ls_sort.
  ls_sort-spos       = 1.
  ls_sort-fieldname  = 'VBELN'.
  ls_sort-up         = 'X'.

  APPEND ls_sort TO lt_sort.

* Layout
  ls_layout-zebra      = 'X'.
  ls_layout-cwidth_opt = 'X'.
  ls_layout-sel_mode   = 'D'.

  CALL FUNCTION 'REUSE_ALV_GRID_DISPLAY_LVC'
    EXPORTING
      i_callback_program       = sy-repid
      i_callback_user_command  = 'F_USER_COMMAND'
      i_callback_pf_status_set = 'F_PFSTATUS'
      is_layout_lvc            = ls_layout
      it_fieldcat_lvc          = lt_fieldcat
      it_sort_lvc              = lt_sort
    TABLES
      t_outtab                 = gt_saida
    EXCEPTIONS
      program_error            = 1
      OTHERS                   = 2.
  IF sy-subrc <> 0.
    MESSAGE 'Erro na exibição do ALV' TYPE 'S' DISPLAY LIKE 'E'.
    LEAVE LIST-PROCESSING.
  ENDIF.


ENDFORM.

FORM f_pfstatus USING rt_extab TYPE slis_t_extab.
  SET PF-STATUS '0100' EXCLUDING rt_extab.
ENDFORM.

FORM f_user_command USING r_ucomm     LIKE sy-ucomm
                          rs_selfield TYPE slis_selfield.

  CASE r_ucomm.
    WHEN 'CANCEL' OR 'BACK'.
      SET SCREEN 0.
    WHEN 'EXIT'.
      LEAVE PROGRAM.
    WHEN '&CREATES'.
      PERFORM f_criar_ordem USING r_ucomm rs_selfield.
      rs_selfield-refresh = 'X'.
    WHEN '&CREATEDL'.
      PERFORM f_criar_remessa USING r_ucomm rs_selfield.
      rs_selfield-refresh = 'X'.
    WHEN '&CREATEBD'.
      PERFORM f_criar_fatura USING r_ucomm rs_selfield.
      rs_selfield-refresh = 'X'.
    WHEN '&IC1'.
      PERFORM f_criar_log USING rs_selfield.
    WHEN '&ZCREATECO'.
      PERFORM f_completa_processo USING r_ucomm rs_selfield.
    WHEN '&ZDELLOG'. " Teste - Deleta log para liberar ordem de venda
      DELETE FROM zht_log_emails.
      COMMIT WORK.

      CLEAR: gt_saida.

      PERFORM f_seleciona_dados.
      PERFORM f_monta_tabela_saida.
      rs_selfield-refresh = 'X'.
  ENDCASE.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form f_criar_ordem
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM f_criar_ordem USING r_ucomm     LIKE sy-ucomm
                         rs_selfield TYPE slis_selfield.

  DATA: ls_order_header_in      TYPE bapisdhd1,
        ls_order_header_inx     TYPE bapisdhd1x,
        lt_order_items_in       TYPE STANDARD TABLE OF bapisditm,
        ls_order_items_in       TYPE bapisditm,
        lt_order_items_inx      TYPE STANDARD TABLE OF bapisditmx,
        ls_order_items_inx      TYPE bapisditmx,
        lt_order_partners       TYPE STANDARD TABLE OF bapiparnr,
        ls_order_partners       TYPE bapiparnr,
        lt_bapiret2             TYPE bapiret2_t,

        lt_order_schedules_in   TYPE STANDARD TABLE OF bapischdl,
        ls_order_schedules_in   TYPE bapischdl,
        lt_order_schedules_inx  TYPE STANDARD TABLE OF bapischdlx,
        ls_order_schedules_inx  TYPE bapischdlx,
        lt_order_conditions_in  TYPE STANDARD TABLE OF bapicond,
        ls_order_conditions_in  TYPE bapicond,
        lt_order_conditions_inx TYPE STANDARD TABLE OF bapicondx,
        ls_order_conditions_inx TYPE bapicondx,
        lt_order_text           TYPE STANDARD TABLE OF bapisdtext,
        ls_order_text           TYPE bapisdtext,
        lv_vbeln                TYPE vbeln,

        ls_saida                TYPE ty_saida,
        lt_log                  TYPE TABLE OF zht_log_emails,
        ls_log_emails           TYPE zht_log_emails,
        lv_linha                TYPE string,
        lv_message              TYPE string,
        lv_data                 TYPE string,
        lv_hora                 TYPE string,
        lv_count                TYPE int4,
        lv_texto                TYPE string,
        lo_report               TYPE REF TO lcl_report,
        lv_type_message         TYPE string.

  lo_report = NEW lcl_report( ).

  READ TABLE gt_saida INTO ls_saida
       INDEX rs_selfield-tabindex.

  SELECT *
    FROM zht_log_emails
    INTO TABLE lt_log
   WHERE vbeln = ls_saida-vbeln.

  IF ls_saida-ordvenda IS NOT INITIAL.
    CLEAR lv_type_message.
    lv_type_message = 'Erro - Mais de uma ordem de venda'.
    PERFORM f_mensagem USING lv_type_message ls_saida lv_message.
  ELSE.

    " Cabeçalho
    CLEAR: lv_vbeln,
           gs_vbak,
           gs_data,
           ls_order_header_in.

    SORT: gt_vbak BY vbeln,
          gt_data BY vbeln posnr.

    READ TABLE gt_vbak INTO gs_vbak
      WITH KEY vbeln = ls_saida-vbeln1
        BINARY SEARCH.

    READ TABLE gt_data INTO gs_data
      WITH KEY vbeln = ls_saida-vbeln
               posnr = ls_saida-posnr
        BINARY SEARCH.

    ls_order_header_in-doc_type   = gs_vbak-auart. " Tipo de Ordem (AUART)
    ls_order_header_in-sales_org  = gs_data-vkorg. " Org. Vendas (VKORG)
    ls_order_header_in-distr_chan = gs_data-vtweg. " Canal de Distribuição (VTWEG)
    ls_order_header_in-division   = gs_data-spart. " Distribuição
    ls_order_header_in-pmnttrms   = gs_data-zterm. " Condição de Pagamento (ZTERM)
    ls_order_header_in-currency   = gs_data-waerk.
    ls_order_header_in-purch_no_c = 'via BAPI'.
    ls_order_header_in-purch_date = sy-datum.
    ls_order_header_in-incoterms1 = ls_saida-inco1.
    ls_order_header_in-incoterms2 = ls_saida-inco2.
    ls_order_header_in-price_date = sy-datum.
    ls_order_header_in-price_list = gs_data-pltyp.

    ls_order_header_inx-doc_type   = 'X'.
    ls_order_header_inx-sales_org  = 'X'.
    ls_order_header_inx-distr_chan = 'X'.
    ls_order_header_inx-division   = 'X'.
    ls_order_header_inx-pmnttrms   = 'X'.
    ls_order_header_inx-currency   = 'X'.
    ls_order_header_inx-purch_no_c = 'X'.
    ls_order_header_inx-purch_date = 'X'.
    ls_order_header_inx-incoterms1 = 'X'.
    ls_order_header_inx-incoterms2 = 'X'.
    ls_order_header_inx-price_list = 'X'.
    ls_order_header_inx-price_date = 'X'.

    ls_order_header_inx-updateflag = 'I'.

    " Parceiros
    CLEAR ls_order_partners.
    ls_order_partners-partn_role = 'AG'.        " Emissor da Ordem
    ls_order_partners-partn_numb = gs_vbak-kunnr. " Código do cliente
    APPEND ls_order_partners TO lt_order_partners.

    CLEAR ls_order_partners.
    ls_order_partners-partn_role = 'WE'.        " Recebedor da Mercadoria
    ls_order_partners-partn_numb = gs_vbak-kunnr. " Código do cliente
    APPEND ls_order_partners TO lt_order_partners.

    " Itens
    DATA: lv_value(4),
          lt_item     TYPE TABLE OF ty_item,
          ls_item     TYPE ty_item.

    REFRESH: lt_item.
    CLEAR:   ls_item.

    SELECT vbeln posnr werks
           fkimg matnr matkl
      FROM vbrp
      INTO TABLE lt_item
     WHERE vbeln = ls_saida-vbeln.

    LOOP AT lt_item INTO ls_item.
      lv_value = lv_value + 1.

      CLEAR ls_order_items_in.
      ls_order_items_in-itm_number = ls_item-posnr.
      ls_order_items_in-material   = ls_item-matnr.
      ls_order_items_in-plant      = ls_item-werks.
      ls_order_items_in-matl_group = ls_item-matkl.
      ls_order_items_in-target_qty = ls_item-fkimg.

      CLEAR ls_order_items_inx.
      ls_order_items_inx-itm_number  = ls_item-posnr.
      ls_order_items_inx-material    = 'X'.
      ls_order_items_inx-plant       = 'X'.
      ls_order_items_inx-matl_group  = 'X'.
      ls_order_items_inx-target_qty  = 'X'.
      ls_order_items_inx-updateflag  = 'I'.

      APPEND ls_order_items_in  TO lt_order_items_in.
      APPEND ls_order_items_inx TO lt_order_items_inx.

      " Divisão de remessa
      CLEAR ls_order_schedules_in.
      ls_order_schedules_in-itm_number = ls_item-posnr.
      ls_order_schedules_in-sched_line = lv_value.
      ls_order_schedules_in-req_qty    = ls_item-fkimg.
      APPEND ls_order_schedules_in TO lt_order_schedules_in.

      CLEAR ls_order_schedules_inx.
      ls_order_schedules_inx-itm_number  = ls_item-posnr.
      ls_order_schedules_inx-sched_line  = lv_value.
      ls_order_schedules_inx-req_qty     = 'X'.
      ls_order_schedules_inx-updateflag  = 'I'.
      APPEND ls_order_schedules_inx TO lt_order_schedules_inx.
    ENDLOOP.
    " Condições

    CALL FUNCTION 'BAPI_SALESORDER_CREATEFROMDAT2'
      EXPORTING
        order_header_in     = ls_order_header_in
        order_header_inx    = ls_order_header_inx
        "logic_switch         =
      IMPORTING
        salesdocument       = lv_vbeln
      TABLES
        return              = lt_bapiret2
        order_items_in      = lt_order_items_in
        order_items_inx     = lt_order_items_inx
        order_partners      = lt_order_partners
        order_schedules_in  = lt_order_schedules_in
        order_schedules_inx = lt_order_schedules_inx.

    READ TABLE lt_bapiret2 TRANSPORTING NO FIELDS WITH KEY type = 'E'.
    IF sy-subrc = 0.
      CALL FUNCTION 'BAPI_TRANSACTION_ROLLBACK'.

      CLEAR lv_type_message.
      lv_type_message = 'Erro - Geração OV'.
      PERFORM f_mensagem USING lv_type_message ls_saida lv_message.

      cl_rmsl_message=>display( lt_bapiret2 ).
      EXIT.
    ENDIF.

    IF lines( lt_bapiret2 ) > 0.
      "cl_rmsl_message=>display( lt_bapiret2 ).
    ENDIF.

    CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'
      EXPORTING
        wait = 'X'.

    gv_ordv = lv_vbeln.
    IF gv_ordv IS NOT INITIAL.
      CLEAR lv_type_message.
      lv_type_message = 'Sucesso - OV'.
      PERFORM f_mensagem USING lv_type_message ls_saida lv_message.
    ENDIF.

    CLEAR: gt_saida,
           lv_texto.

    PERFORM f_seleciona_dados.
    PERFORM f_monta_tabela_saida.

    IF r_ucomm <> '&ZCREATECO' .
      CONCATENATE 'Ordem criada com sucesso' lv_vbeln INTO lv_texto SEPARATED BY space.
      MESSAGE lv_texto TYPE 'I'.
    ENDIF.
  ENDIF.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form f_criar_remessa
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM f_criar_remessa USING r_ucomm     LIKE sy-ucomm
                           rs_selfield TYPE slis_selfield.

  DATA: lv_delivery          TYPE bapishpdelivnumb-deliv_numb,
        lt_sales_order_items TYPE STANDARD TABLE OF bapidlvreftosalesorder,
        ls_sales_order_items TYPE bapidlvreftosalesorder,
        lt_return            TYPE STANDARD TABLE OF bapiret2,
        ls_return            TYPE bapiret2,

        lt_vbap              TYPE STANDARD TABLE OF vbap,
        ls_vbap              TYPE vbap,
        lv_error             TYPE flag,
        ls_saida             TYPE ty_saida,
        ls_log_emails        TYPE zht_log_emails,
        lv_message           TYPE string,
        lt_log               TYPE TABLE OF zht_log_emails,
        lv_linha             TYPE string,
        lv_data              TYPE string,
        lv_count             TYPE int4,
        lv_hora              TYPE string,
        lv_texto             TYPE string,
        lo_report            TYPE REF TO lcl_report,
        lv_type_message      TYPE string.

  lo_report = NEW lcl_report( ).

  READ TABLE gt_saida INTO ls_saida
       INDEX rs_selfield-tabindex.

  IF ls_saida-ordvenda <> ''.
    SELECT *
      INTO TABLE lt_vbap
      FROM vbap
     WHERE vbeln = ls_saida-ordvenda.

    LOOP AT lt_vbap INTO ls_vbap.
      CLEAR ls_sales_order_items.
      ls_sales_order_items-ref_doc    = ls_vbap-vbeln.
      ls_sales_order_items-ref_item   = ls_vbap-posnr.
      ls_sales_order_items-dlv_qty    = ls_vbap-kwmeng.
      ls_sales_order_items-sales_unit = ls_vbap-vrkme.
      APPEND ls_sales_order_items TO lt_sales_order_items.
    ENDLOOP.

    CALL FUNCTION 'BAPI_OUTB_DELIVERY_CREATE_SLS'
      IMPORTING
        delivery          = lv_delivery
      TABLES
        sales_order_items = lt_sales_order_items
        return            = lt_return.

    lv_error = ''.

    LOOP AT lt_return INTO ls_return WHERE type = 'E' OR type = 'A'.
      lv_error = 'X'.
      EXIT.
    ENDLOOP.

    IF lv_error = 'X'.
      CLEAR lv_type_message.
      lv_type_message = 'Erro - Geração DL'.
      PERFORM f_mensagem USING lv_type_message ls_saida lv_message.

      CALL FUNCTION 'BAPI_TRANSACTION_ROLLBACK'.
      cl_rmsl_message=>display( lt_return ).
    ELSE.
      CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'
        EXPORTING
          wait = 'X'.
      gv_remessa = lv_delivery.

      CLEAR lv_type_message.
      lv_type_message = 'Sucesso - DL'.
      PERFORM f_mensagem USING lv_type_message ls_saida lv_message.

      CLEAR: gt_saida,
             lv_texto.

      PERFORM f_seleciona_dados.
      PERFORM f_monta_tabela_saida.

      IF r_ucomm <> '&ZCREATECO'.
        CONCATENATE 'Remessa criada' lv_delivery INTO lv_texto SEPARATED BY space.
        MESSAGE lv_texto TYPE 'I'.
      ENDIF.
    ENDIF.
  ENDIF.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form f_criar_fatura
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM f_criar_fatura USING r_ucomm     LIKE sy-ucomm
                          rs_selfield TYPE slis_selfield.
  DATA: lt_billingdatain TYPE STANDARD TABLE OF bapivbrk,
        lt_success       TYPE STANDARD TABLE OF bapivbrksuccess,
        lt_return	       TYPE STANDARD TABLE OF bapiret1,
        ls_billingdatain TYPE bapivbrk,
        ls_return	       TYPE bapiret1,
        ls_success       TYPE bapivbrksuccess,
        ld_error         TYPE flag,
        ls_fatura        TYPE ty_fatura,

        ls_saida         TYPE ty_saida,
        lt_log           TYPE TABLE OF zht_log_emails,
        ls_log_emails    TYPE zht_log_emails,
        lv_linha         TYPE string,
        lv_count         TYPE int4,
        lv_data          TYPE string,
        lv_hora          TYPE string,
        lv_texto         TYPE string,
        lo_report        TYPE REF TO lcl_report,
        lv_type_message  TYPE string,
        lv_flag          TYPE string.

  lo_report = NEW lcl_report( ).

  READ TABLE gt_saida INTO ls_saida
       INDEX rs_selfield-tabindex.

  SELECT SINGLE vbeln vbtyp
    FROM likp
    INTO ls_fatura
   WHERE vbeln = ls_saida-remessa.

  CLEAR lt_billingdatain.
  ls_billingdatain-ref_doc    = ls_fatura-vbeln.
  ls_billingdatain-ref_doc_ca = 'J'.
  APPEND ls_billingdatain TO lt_billingdatain.

  CALL FUNCTION 'BAPI_BILLINGDOC_CREATEMULTIPLE'
    TABLES
      billingdatain = lt_billingdatain
      return        = lt_return
      success       = lt_success.

  LOOP AT lt_return INTO ls_return WHERE type = 'E' OR type = 'A'.
    ld_error = 'X'.
    EXIT.
  ENDLOOP.

  DATA: lv_error TYPE string.
  IF ld_error = 'X'.
    READ TABLE lt_return TRANSPORTING NO FIELDS WITH KEY type = 'E'.
    IF sy-subrc = 0.
      CALL FUNCTION 'BAPI_TRANSACTION_ROLLBACK'.
      LOOP AT lt_return INTO ls_return.
        lv_error = ls_return-message.
        MESSAGE lv_error TYPE 'I'.
      ENDLOOP.
    ENDIF.
    DATA: lv_message TYPE string.

    CLEAR: lv_data, lv_hora.
    CONCATENATE sy-datum+6(2) sy-datum+4(2) sy-datum+0(4) INTO lv_data SEPARATED BY '/'.
    CONCATENATE sy-uzeit+0(2) sy-uzeit+2(2) sy-uzeit+4(2) INTO lv_hora SEPARATED BY ':'.

    LOOP AT lt_return INTO ls_return.
      ls_log_emails-message     = 'Erro: '.
      CONCATENATE ls_log_emails-message ls_return-message INTO lv_message.

    ENDLOOP.
    CLEAR lv_type_message.
    lv_type_message = 'Erro - Fatura'.
    PERFORM f_mensagem USING lv_type_message ls_saida lv_message.


    IF sy-subrc = 0.
      COMMIT WORK.
    ELSE.
      ROLLBACK WORK.
    ENDIF.

  ELSE.
    lv_flag = 'S'.
    CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'
      EXPORTING
        wait = 'X'.

    READ TABLE lt_success INTO ls_success
         INDEX 1.

    CLEAR lv_type_message.
    lv_type_message = 'Sucesso - Fatura'.
    PERFORM f_mensagem USING lv_type_message ls_saida lv_message.

    IF sy-subrc = 0.

      COMMIT WORK.
    ELSE.
      ROLLBACK WORK.
    ENDIF.

    gv_fatura = ls_success-bill_doc.
    CLEAR: gt_saida,
           lv_texto.

    PERFORM f_seleciona_dados.
    PERFORM f_monta_tabela_saida.

    IF r_ucomm <> '&ZCREATECO'.
      CONCATENATE 'Faturamento criado' ls_success-bill_doc INTO lv_texto SEPARATED BY space.
      MESSAGE lv_texto TYPE 'I'.
    ELSEIF r_ucomm = '&ZCREATECO' AND lv_flag = 'S'.
      MESSAGE 'Processo completado com sucesso.' TYPE 'I'.
    ELSEIF r_ucomm = '&ZCREATECO' AND lv_flag <> 'S'.
      MESSAGE 'Processo cancelado por motivo de erro.' TYPE 'I'.
    ENDIF.
  ENDIF.

ENDFORM.
*&---------------------------------------------------------------------*
*& Form f_criar_log
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM f_criar_log USING rs_selfield TYPE slis_selfield.

  PERFORM f_monta_saida2 USING rs_selfield.
  PERFORM f_fieldcat2.
  PERFORM f_imprime_alv2.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form f_monta_saida2
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM f_monta_saida2 USING rs_selfield TYPE slis_selfield.
  DATA: ls_saida TYPE ty_saida.
  READ TABLE gt_saida INTO ls_saida
       INDEX rs_selfield-tabindex.

  CLEAR gt_saida2.
  SELECT status_i userid datum hora type vbelngerado message
    FROM zht_log_emails
    INTO TABLE gt_data2
   WHERE vbeln = ls_saida-vbeln.

  LOOP AT gt_data2 INTO gs_data2.
    gs_saida2-status  = gs_data2-status.
    gs_saida2-userid  = gs_data2-userid.
    gs_saida2-data    = gs_data2-data.
    gs_saida2-hora    = gs_data2-hora.
    gs_saida2-type    = gs_data2-type.
    gs_saida2-vbelng  = gs_data2-vbelng.
    gs_saida2-message = gs_data2-message.

    APPEND gs_saida2 TO gt_saida2.
  ENDLOOP.
ENDFORM.


*&---------------------------------------------------------------------*
*& Form f_fieldcat2
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM f_fieldcat2.
  CLEAR gt_fieldcat2.
  PERFORM f_fill_fieldcat2 TABLES gt_fieldcat2 USING:
  " FIELDNAME;  TABNAME;  COLTEXT;  ICON;  SUM;  EDIT;
   'STATUS_I'     ''      TEXT-028   'X'    ''     '',    " Status
   'USERID'       ''      TEXT-029   ''     ''     '',    " Usuário
   'DATA'         ''      TEXT-030   ''     ''     '',    " Data
   'HORA'         ''      TEXT-031   ''     ''     '',    " Hora
   'TYPE'         ''      TEXT-032   ''     ''     '',    " Tipo de tentativa
   'MESSAGE'      ''      TEXT-033   ''     ''     ''.    " Mensagem de LOG
ENDFORM.

*&---------------------------------------------------------------------
*& Form F_FILL_FIELDCAT2
*&---------------------------------------------------------------------
*& Preenche o catálogo de campos do relatório
*&---------------------------------------------------------------------
FORM f_fill_fieldcat2 TABLES pt_fcat     TYPE lvc_t_fcat
                       USING p_fieldname TYPE any
                             p_tabname   TYPE any
                             p_coltext   TYPE any
                             p_icon      TYPE any
                             p_sum       TYPE any
                             p_edit      TYPE any.

  DATA: ls_fieldcat TYPE lvc_s_fcat.

  ls_fieldcat-fieldname = p_fieldname.
  ls_fieldcat-tabname   = p_tabname.
  ls_fieldcat-coltext   = p_coltext.
  ls_fieldcat-icon      = p_icon.
  ls_fieldcat-do_sum    = p_sum.
  ls_fieldcat-col_opt   = 'X'.
  ls_fieldcat-no_zero   = 'X'.
  ls_fieldcat-edit      = p_edit.
  ls_fieldcat-checkbox  = p_edit.

  APPEND ls_fieldcat TO gt_fieldcat2.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form f_imprime_alv2
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*& -->  p1        text
*& <--  p2        text
*&---------------------------------------------------------------------*
FORM f_imprime_alv2.
*  DATA: lt_fieldcat TYPE lvc_t_fcat,
*        lt_sort     TYPE lvc_t_sort,
*        ls_sort     TYPE lvc_s_sort,
*        ls_layout   TYPE lvc_s_layo.
** Ordena
*  CLEAR ls_sort.
*  ls_sort-spos       = 1.
*  ls_sort-fieldname  = 'DATA'.
*  ls_sort-up         = 'X'.
*
*  APPEND ls_sort TO lt_sort.
*
*  CLEAR ls_sort.
*  ls_sort-spos       = 2.
*  ls_sort-fieldname  = 'HORA'.
*  ls_sort-up         = 'X'.
*
*  APPEND ls_sort TO lt_sort.
*
** Layout
*  ls_layout-zebra      = 'X'.
*  ls_layout-cwidth_opt = 'X'.
*  ls_layout-sel_mode   = 'D'.
*
*  DATA: ls_field TYPE slis_fieldcat_alv,
*        lt_field TYPE STANDARD TABLE OF slis_fieldcat_alv.
*
*  ls_field-COL_POS   = 1.
*  ls_field-FIELDNAME = 'STATUS'.
*  ls_field-SELTEXT_M = TEXT-028.
*  APPEND ls_field to lt_field.
*  clear ls_field.
*
*  ls_field-COL_POS   = 2.
*  ls_field-FIELDNAME = 'USERID'.
*  ls_field-SELTEXT_M = TEXT-029.
*  APPEND ls_field to lt_field.
*  clear ls_field.
*
*  ls_field-COL_POS   = 3.
*  ls_field-FIELDNAME = 'DATA'.
*  ls_field-SELTEXT_M = TEXT-030.
*  APPEND ls_field to lt_field.
*  clear ls_field.
*
*  ls_field-COL_POS   = 4.
*  ls_field-FIELDNAME = 'HORA'.
*  ls_field-SELTEXT_M = TEXT-031.
*  APPEND ls_field to lt_field.
*  clear ls_field.
*
*  ls_field-COL_POS   = 5.
*  ls_field-FIELDNAME = 'TYPE'.
*  ls_field-SELTEXT_M = TEXT-032.
*  APPEND ls_field to lt_field.
*  clear ls_field.
*
*  ls_field-COL_POS   = 6.
*  ls_field-FIELDNAME = 'MESSAGE'.
*  ls_field-SELTEXT_M = TEXT-033.
*  APPEND ls_field to lt_field.
*  clear ls_field.
*
*  ls_field-COL_POS   = 7.
*  ls_field-FIELDNAME = 'VBELN'.
*  ls_field-SELTEXT_M = TEXT-031.
*  APPEND ls_field to lt_field.
*  clear ls_field.
*
*  CALL FUNCTION 'REUSE_ALV_POPUP_TO_SELECT'
*    EXPORTING
*     I_TITLE                        = 'Pop-up de LOG'
*     I_ALLOW_NO_SELECTION           = 'X'
*     I_SCREEN_START_COLUMN          = 10
*     I_SCREEN_START_LINE            = 5
*     I_SCREEN_END_COLUMN            = 100
*     I_SCREEN_END_LINE              = 10
*     i_tabname                      = 'gt_saida2'
*     IT_FIELDCAT                    = lt_field
*    tables
*      t_outtab                      = gt_saida2
*   EXCEPTIONS
*     PROGRAM_ERROR                 = 1
*     OTHERS                        = 2
*            .
  DATA:
     lo_popup  TYPE REF TO cl_reca_gui_f4_popup.

  CALL METHOD cl_reca_gui_f4_popup=>factory_grid
    EXPORTING
      it_f4value     = gt_saida2
      if_multi       = abap_false
      id_title       = 'LOG Pop-up'
    RECEIVING
      ro_f4_instance = lo_popup.

  CALL METHOD lo_popup->set_field_text
    EXPORTING
      id_fieldname = 'STATUS_I'
      id_text      = TEXT-028.
  CALL METHOD lo_popup->set_field_text
    EXPORTING
      id_fieldname = 'USERID'
      id_text      = TEXT-029.
  CALL METHOD lo_popup->set_field_text
    EXPORTING
      id_fieldname = 'DATA'
      id_text      = TEXT-030.
  CALL METHOD lo_popup->set_field_text
    EXPORTING
      id_fieldname = 'HORA'
      id_text      = TEXT-031.
  CALL METHOD lo_popup->set_field_text
    EXPORTING
      id_fieldname = 'TYPE'
      id_text      = TEXT-032.
  CALL METHOD lo_popup->set_field_text
    EXPORTING
      id_fieldname = 'MESSAGE'
      id_text      = TEXT-033.

  CALL METHOD lo_popup->set_field_text
    EXPORTING
      id_fieldname = 'VBELNG'
      id_text      = 'ID Criado'.

  CALL METHOD lo_popup->display
    EXPORTING
      id_start_column = 5
      id_start_line   = 5
      id_end_column   = 90
      id_end_line     = 15
    IMPORTING
      et_result       = gt_saida2.



ENDFORM.

*&---------------------------------------------------------------------*
*& Form f_mensagem
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      --> LV_TYPE_MESSAGE
*&---------------------------------------------------------------------*
FORM f_mensagem  USING p_lv_type_message TYPE string
                       ls_saida          TYPE ty_saida
                       lv_message        TYPE string.
  DATA: lv_data       TYPE string,
        lv_hora       TYPE string,
        lv_count      TYPE int4,
        lo_report     TYPE REF TO lcl_report,
        ls_log_emails TYPE zht_log_emails.

  lo_report = NEW lcl_report( ).

  CLEAR lv_count.

  IF p_lv_type_message = 'Erro - Mais de uma ordem de venda'.
    CLEAR: lv_data, lv_hora.
    CONCATENATE sy-datum+6(2) sy-datum+4(2) sy-datum+0(4) INTO lv_data SEPARATED BY '/'.
    CONCATENATE sy-uzeit+0(2) sy-uzeit+2(2) sy-uzeit+4(2) INTO lv_hora SEPARATED BY ':'.

    SELECT COUNT(*)
        FROM zht_log_emails
        INTO lv_count
       WHERE vbeln = ls_saida-vbeln.

    CLEAR ls_log_emails.
    ls_log_emails-vbeln       = ls_saida-vbeln.
    ls_log_emails-message     = 'Erro: Tentativa de mais de uma ordem de venda por fatura'.
    ls_log_emails-status      = 'E'.
    ls_log_emails-userid      = sy-uname.
    ls_log_emails-datum       = lv_data.
    ls_log_emails-hora        = lv_hora.
    ls_log_emails-type        = 'Ordem de venda'.
    ls_log_emails-vbelngerado = ''.
    ls_log_emails-seq         = lv_count + 1.
    ls_log_emails-status_i    = icon_led_red.
    INSERT zht_log_emails FROM ls_log_emails.

    IF sy-subrc = 0.
      COMMIT WORK.
    ELSE.
      ROLLBACK WORK.
    ENDIF.
    MESSAGE 'Só é permitido uma ordem de venda nova por fatura' TYPE 'I'.
  ELSEIF p_lv_type_message = 'Erro - Geração OV'.
    CLEAR: lv_data, lv_hora.
    CONCATENATE sy-datum+6(2) sy-datum+4(2) sy-datum+0(4) INTO lv_data SEPARATED BY '/'.
    CONCATENATE sy-uzeit+0(2) sy-uzeit+2(2) sy-uzeit+4(2) INTO lv_hora SEPARATED BY ':'.

    SELECT COUNT(*)
        FROM zht_log_emails
        INTO lv_count
       WHERE vbeln = ls_saida-vbeln.

    CLEAR ls_log_emails.
    ls_log_emails-vbeln       = ls_saida-vbeln.
    ls_log_emails-message     = 'Erro: Falha na geração da ordem de venda'.
    ls_log_emails-status      = 'E'.
    ls_log_emails-userid      = sy-uname.
    ls_log_emails-datum       = lv_data.
    ls_log_emails-hora        = lv_hora.
    ls_log_emails-type        = 'Ordem de venda'.
    ls_log_emails-vbelngerado = ''.
    ls_log_emails-seq         = lv_count + 1.
    ls_log_emails-status_i    = icon_led_red.
    INSERT zht_log_emails FROM ls_log_emails.

    IF sy-subrc = 0.
      COMMIT WORK.
    ELSE.
      ROLLBACK WORK.
    ENDIF.
  ELSEIF p_lv_type_message = 'Sucesso - OV'.
    CLEAR: lv_data, lv_hora.
    CONCATENATE sy-datum+6(2) sy-datum+4(2) sy-datum+0(4) INTO lv_data SEPARATED BY '/'.
    CONCATENATE sy-uzeit+0(2) sy-uzeit+2(2) sy-uzeit+4(2) INTO lv_hora SEPARATED BY ':'.

    SELECT COUNT(*)
        FROM zht_log_emails
        INTO lv_count
       WHERE vbeln = ls_saida-vbeln.

    CLEAR ls_log_emails.
    ls_log_emails-vbeln       = ls_saida-vbeln.
    ls_log_emails-message     = 'Sucesso: Ordem criada com sucesso'.
    ls_log_emails-status      = 'S'.
    ls_log_emails-userid      = sy-uname.
    ls_log_emails-datum       = lv_data.
    ls_log_emails-hora        = lv_hora.
    ls_log_emails-type        = 'Ordem de venda'.
    ls_log_emails-vbelngerado = gv_ordv.
    ls_log_emails-seq         = lv_count + 1.
    ls_log_emails-status_i    = icon_led_green.
    INSERT zht_log_emails FROM ls_log_emails.

    IF sy-subrc = 0.
      COMMIT WORK.
    ELSE.
      ROLLBACK WORK.
    ENDIF.
  ELSEIF p_lv_type_message = 'Erro - Geração DL'.
    CLEAR: lv_data, lv_hora.
    CONCATENATE sy-datum+6(2) sy-datum+4(2) sy-datum+0(4) INTO lv_data SEPARATED BY '/'.
    CONCATENATE sy-uzeit+0(2) sy-uzeit+2(2) sy-uzeit+4(2) INTO lv_hora SEPARATED BY ':'.

    SELECT COUNT(*)
        FROM zht_log_emails
        INTO lv_count
       WHERE vbeln = ls_saida-vbeln.

    CLEAR ls_log_emails.
    ls_log_emails-vbeln       = ls_saida-vbeln.
    ls_log_emails-message     = 'Erro: Falha na geração da remessa'.
    ls_log_emails-status      = 'E'.
    ls_log_emails-userid      = sy-uname.
    ls_log_emails-datum       = lv_data.
    ls_log_emails-hora        = lv_hora.
    ls_log_emails-type        = 'Remessa'.
    ls_log_emails-vbelngerado = ''.
    ls_log_emails-seq         = lv_count + 1.
    ls_log_emails-status_i    = icon_led_red.
    INSERT zht_log_emails FROM ls_log_emails.

    IF sy-subrc = 0.
      COMMIT WORK.
    ELSE.
      ROLLBACK WORK.
    ENDIF.
  ELSEIF p_lv_type_message = 'Sucesso - DL'.
    CLEAR: lv_data, lv_hora.
    CONCATENATE sy-datum+6(2) sy-datum+4(2) sy-datum+0(4) INTO lv_data SEPARATED BY '/'.
    CONCATENATE sy-uzeit+0(2) sy-uzeit+2(2) sy-uzeit+4(2) INTO lv_hora SEPARATED BY ':'.

    SELECT COUNT(*)
      FROM zht_log_emails
      INTO lv_count
     WHERE vbeln = ls_saida-vbeln.

    CLEAR ls_log_emails.
    ls_log_emails-vbeln       = ls_saida-vbeln.
    ls_log_emails-message     = 'Sucesso: Remessa criada com sucesso'.
    ls_log_emails-status      = 'S'.
    ls_log_emails-userid      = sy-uname.
    ls_log_emails-datum       = lv_data.
    ls_log_emails-hora        = lv_hora.
    ls_log_emails-type        = 'Remessa'.
    ls_log_emails-vbelngerado = gv_remessa.
    ls_log_emails-seq         = lv_count + 1.
    ls_log_emails-status_i    = icon_led_green.
    INSERT zht_log_emails FROM ls_log_emails.

    IF sy-subrc = 0.
      COMMIT WORK.
    ELSE.
      ROLLBACK WORK.
    ENDIF.
  ELSEIF p_lv_type_message = 'Sucesso - Fatura'.
    CLEAR: lv_data, lv_hora.
    CONCATENATE sy-datum+6(2) sy-datum+4(2) sy-datum+0(4) INTO lv_data SEPARATED BY '/'.
    CONCATENATE sy-uzeit+0(2) sy-uzeit+2(2) sy-uzeit+4(2) INTO lv_hora SEPARATED BY ':'.

    SELECT COUNT(*)
        FROM zht_log_emails
        INTO lv_count
       WHERE vbeln = ls_saida-vbeln.

    CLEAR ls_log_emails.
    ls_log_emails-vbeln       = ls_saida-vbeln.
    ls_log_emails-message     = 'Sucesso: Fatura criada com sucesso'.
    ls_log_emails-status      = 'S'.
    ls_log_emails-userid      = sy-uname.
    ls_log_emails-datum       = lv_data.
    ls_log_emails-hora        = lv_hora.
    ls_log_emails-type        = 'Fatura'.
    ls_log_emails-vbelngerado = gv_fatura.
    ls_log_emails-seq         = lv_count + 1.
    ls_log_emails-status_i    = icon_led_green.
    INSERT zht_log_emails FROM ls_log_emails.
  ELSEIF p_lv_type_message = 'Erro - Fatura'.
    CLEAR: lv_data, lv_hora.
    CONCATENATE sy-datum+6(2) sy-datum+4(2) sy-datum+0(4) INTO lv_data SEPARATED BY '/'.
    CONCATENATE sy-uzeit+0(2) sy-uzeit+2(2) sy-uzeit+4(2) INTO lv_hora SEPARATED BY ':'.

    SELECT COUNT(*)
      FROM zht_log_emails
      INTO lv_count
     WHERE vbeln = ls_saida-vbeln.

    CLEAR ls_log_emails.
    ls_log_emails-vbeln       = ls_saida-vbeln.
    ls_log_emails-message     = lv_message.
    ls_log_emails-status      = 'E'.
    ls_log_emails-userid      = sy-uname.
    ls_log_emails-datum       = lv_data.
    ls_log_emails-hora        = lv_hora.
    ls_log_emails-type        = 'Fatura'.
    ls_log_emails-vbelngerado = ''.
    ls_log_emails-seq         = lv_count + 1.
    ls_log_emails-status_i    = icon_led_red.
    INSERT zht_log_emails FROM ls_log_emails.

  ENDIF.
ENDFORM.
*&---------------------------------------------------------------------*
*& Form f_completa_processo
*&---------------------------------------------------------------------*
*& text
*&---------------------------------------------------------------------*
*&      --> R_UCOMM
*&      --> RS_SELFIELD
*&---------------------------------------------------------------------*
FORM f_completa_processo  USING r_ucomm     LIKE sy-ucomm
                                rs_selfield TYPE slis_selfield.

  DATA: ls_saida TYPE ty_saida.

  READ TABLE gt_saida INTO ls_saida
   INDEX rs_selfield-tabindex.

  IF ls_saida-ordvenda IS INITIAL.
    CLEAR rs_selfield-refresh.
    PERFORM f_criar_ordem   USING r_ucomm rs_selfield.
    rs_selfield-refresh = 'X'.
    PERFORM f_criar_remessa USING r_ucomm rs_selfield.
    rs_selfield-refresh = 'X'.
    PERFORM f_criar_fatura  USING r_ucomm rs_selfield.
    rs_selfield-refresh = 'X'.
  ELSEIF ls_saida-remessa IS INITIAL.
    CLEAR rs_selfield-refresh.
    PERFORM f_criar_remessa USING r_ucomm rs_selfield.
    rs_selfield-refresh = 'X'.
    PERFORM f_criar_fatura  USING r_ucomm rs_selfield.
    rs_selfield-refresh = 'X'.
  ELSEIF ls_saida-fatura IS INITIAL.
    CLEAR rs_selfield-refresh.
    PERFORM f_criar_fatura  USING r_ucomm rs_selfield.
    rs_selfield-refresh = 'X'.
  ELSE.
    MESSAGE 'Não é possível, pois a fatura já foi processada' TYPE 'I'.
  ENDIF.
  rs_selfield-refresh = 'X'.
ENDFORM.
