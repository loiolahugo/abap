*&---------------------------------------------------------------------*
*& Include          ZHR_VF03_SCR
*&---------------------------------------------------------------------*

* Tela de seleção
SELECTION-SCREEN BEGIN OF BLOCK bc01 WITH FRAME TITLE TEXT-001. " Parâmetros de seleção
  SELECT-OPTIONS: s_vbeln    FOR vbrp-vbeln, " Código da fatura
                  s_matnr    FOR vbrp-matnr, " Materal
                  s_vkorg    FOR vbrk-vkorg, " Organização de vendas
                  s_data     FOR vbrk-fkdat, " Data do faturamento
                  s_remes    FOR vbrp-vgbel, " Número da remessa
                  s_grupo    FOR vbap-matkl. " Grupo de mercadorias
SELECTION-SCREEN END OF BLOCK bc01.
