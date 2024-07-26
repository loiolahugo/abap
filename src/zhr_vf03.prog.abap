*--------------------------------------------------------------------
*                            Seidor
*--------------------------------------------------------------------
* Nome do Objeto.: zhr_vf03
*--------------------------------------------------------------------
* Tipo de prg ...: Report / Relatório
* Transação .....: ZHR_FATURAMENTO
* Descrição .....: Relatório de Faturamento
*--------------------------------------------------------------------
*                     Histórico de Modifciações
*--------------------------------------------------------------------
*   Data     |      Nome      |   Request    |   Descrição
*--------------------------------------------------------------------
* 02.07.2024 |   Hugo Loiola  | ZTREINAMENTO | Relatório VF03
*--------------------------------------------------------------------
REPORT zhr_vf03.

INCLUDE zhr_vf03_top.
INCLUDE zhr_vf03_cls.
INCLUDE zhr_vf03_scr.
INCLUDE zhr_vf03_f01.

START-OF-SELECTION.

  PERFORM f_seleciona_dados.
  PERFORM f_monta_tabela_saida.
  PERFORM f_imprime_alv.
