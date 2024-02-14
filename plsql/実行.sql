

DECLARE
  "I会社コード" VARCHAR2(200);
  "I給与支払年月_CUR" NUMBER;
  "I給与支払年月_PRE" NUMBER;
  "IプログラムID" VARCHAR2(200);
  "I担当者コード" NUMBER;
  "O処理件数" NUMBER;
  "O正常件数" NUMBER;
  "O異常件数" NUMBER;
  OERRMSG VARCHAR2(200);
  v_Return NUMBER;
BEGIN
  "I会社コード" := '0930';
  "I給与支払年月_CUR" := 202008;
  "I給与支払年月_PRE" := 202007;
  "IプログラムID" := 'PID001';
  "I担当者コード" := 99999999;

DBMS_OUTPUT.PUT_LINE('実行開始：  ' || SYSTIMESTAMP || '    >>>>>>>>>>>>>>>>>>>>');

  v_Return := "KP930A07給与支給比較"(
    "I会社コード" => "I会社コード",
    "I給与支払年月_CUR" => "I給与支払年月_CUR",
    "I給与支払年月_PRE" => "I給与支払年月_PRE",
    "IプログラムID" => "IプログラムID",
    "I担当者コード" => "I担当者コード",
    "O処理件数" => "O処理件数",
    "O正常件数" => "O正常件数",
    "O異常件数" => "O異常件数",
    OERRMSG => OERRMSG
  );

DBMS_OUTPUT.PUT_LINE('実行終了：  ' || SYSTIMESTAMP || '    <<<<<<<<<<<<<<<<<<<<');

  /* Legacy output: 
DBMS_OUTPUT.PUT_LINE('v_Return = ' || v_Return);
*/ 
  :v_Return := v_Return;
  /* Legacy output: */
DBMS_OUTPUT.PUT_LINE('"O処理件数" = ' || "O処理件数");
DBMS_OUTPUT.PUT_LINE('"O正常件数" = ' || "O正常件数");
DBMS_OUTPUT.PUT_LINE('"O異常件数" = ' || "O異常件数");

DBMS_OUTPUT.PUT_LINE('OERRMSG = ' || OERRMSG);
 
--rollback; 
END;


