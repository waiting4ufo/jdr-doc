create or replace PACKAGE BODY "KP930当月前月比較PKG" AS

  /**
  * エラーメッセージを「C0930前月当月比較エラー」に登録する
  */
  procedure putError(
      iプログラムID     in varchar2,
      i会社コード       in varchar2,
      i給与支払年月_cur in number,
      i給与支払年月_pre in number,
      i担当者コード     in number,
      i社員番号         in number,
      ierrorMsg1        in varchar2,
      ierrorMsg2        in varchar2) 
  AS
  BEGIN
  
      insert into "C0930前月当月比較エラー"(
          プログラムID,
          会社コード,
          給与支払年月_当月,
          給与支払年月_前月,
          担当者コード,
          社員番号,
          メッセージ１,
          メッセージ２,
          登録日時,
          登録者)
      values (
          iプログラムID,
          i会社コード,
          i給与支払年月_cur,
          i給与支払年月_pre,
          i担当者コード,
          i社員番号,
          ierrorMsg1,
          ierrorMsg2,
          sysdate,
          i担当者コード
      );
      
  END putError;
  
  /**
  * 「C0930前月当月比較エラー」テーブルから指定エラー内容をすべて削除する
  */
  procedure clearError(
      iプログラムID     in varchar2,
      i会社コード       in varchar2)
  as
  begin
      delete
          "C0930前月当月比較エラー"
      where
          プログラムID = iプログラムID
          and 会社コード = i会社コード;
      
  end clearError;
  
  /**
  * CSVデータ格納テーブル「C0930前月当月給与支給額比較」の該当データをクリアする
  *
  * 引数
  *     i会社コード
  *     i給与支払年月_cur：給与支払年月(当月)
  */
  procedure csvDataClear(
      i会社コード       in varchar2,
      i給与支払年月_cur in number)
  is
  begin
      delete 
          "C0930前月当月給与支給額比較"
      where
          会社コード = i会社コード and
          給与支払年月 = i給与支払年月_cur;
          
  end csvDataClear;
  
  /**
  * 「給与明細漢字データ項目」から所属名を取得する
  *
  * 引数
  *     i会社コード
  *     i給与支払年月：取得したいデータの給与支払年月
  *     i社員番号
  * 戻り値
  *     retCd_OK：取得済み
  *     retCd_NG：異常発生
  *     retCd_NoData：データ無し
  */
  function get所属名(
      i会社コード   in varchar2,
      i給与支払年月 in number,
      i社員番号     in number,
      o所属名       out 給与明細漢字データ項目.所属名%type,
      oErrMsg       out varchar2
  ) return number
  is
  begin
      o所属名 := '';
  
      select a.所属名 into o所属名
      from
          給与明細漢字データ項目 a
      where
          a.会社コード = i会社コード
    	  and a.給与支払年月 = i給与支払年月
    	  and a.社員番号 = i社員番号;
      
      return retCd_OK;
  exception
      when no_data_found then  --取得データ無し
          oErrMsg := '「所属名」データ無し。' 
                     || 'テーブル[給与明細漢字データ項目] 条件[' 
                     || '会社コード=' || i会社コード || ', '
                     || '給与支払年月=' || i給与支払年月 || ', '
                     || '社員番号=' || i社員番号
                     || ']';
          return retCd_NoData;
      when others then
          oErrMsg := 'システムエラー発生[get所属名()]。'
                     || 'SQLCODE=[' || SQLCODE || '] msg=[' || sqlerrm(SQLCODE) || '] '
                     || 'テーブル[給与明細漢字データ項目] 条件[' 
                     || '会社コード=' || i会社コード || ', '
                     || '給与支払年月=' || i給与支払年月 || ', '
                     || '社員番号=' || i社員番号
                     || ']';
          return retCd_NG;
  end get所属名;
  
  /**
  * 「給与明細マスタ項目3」から通称氏名、通称氏名カナ、戸籍氏名を取得
  *
  * 引数
  *     i会社コード
  *     i給与支払年月：取得したいデータの給与支払年月
  *     i社員番号
  * 戻り値
  *     retCd_OK：取得済み
  *     retCd_NG：異常発生
  *     retCd_NoData：データ無し
  */
  function get給与明細マスタ項目3Data(
      i会社コード   in varchar2,
      i給与支払年月 in number,
      i社員番号     in number,
      o通称氏名     out 給与明細マスタ項目3.通称氏名%type,
      o通称氏名カナ out 給与明細マスタ項目3.通称氏名カナ%type,
      o戸籍氏名     out 給与明細マスタ項目3.戸籍氏名%type,
      oErrMsg       out varchar2
  ) return number
  is
  begin
      o通称氏名 := '';
      o通称氏名カナ := '';
      o戸籍氏名 := '';
      
      select
          通称氏名, 通称氏名カナ, 戸籍氏名 into o通称氏名, o通称氏名カナ, o戸籍氏名
      from
          給与明細マスタ項目3
      where
          会社コード = i会社コード
    	  and 給与支払年月 = i給与支払年月
    	  and 社員番号 = i社員番号;
      
      return retCd_OK;
  exception
      when no_data_found then  --取得データ無し
          oErrMsg := 'データ無し。' 
                     || 'テーブル[給与明細マスタ項目3] 条件[' 
                     || '会社コード=' || i会社コード || ', '
                     || '給与支払年月=' || i給与支払年月 || ', '
                     || '社員番号=' || i社員番号
                     || ']';
          return retCd_NoData;
      when others then
          oErrMsg := 'システムエラー発生[get給与明細マスタ項目3Data()]。'
                     || 'SQLCODE=[' || SQLCODE || '] msg=[' || sqlerrm(SQLCODE) || ']'
                     || 'テーブル[給与明細マスタ項目3] 条件[' 
                     || '会社コード=' || i会社コード || ', '
                     || '給与支払年月=' || i給与支払年月 || ', '
                     || '社員番号=' || i社員番号
                     || ']';
          return retCd_NG;
  end get給与明細マスタ項目3Data;
  
  /**
  * 「給与明細付録項目」からデータ取得
  *
  * 戻り値
  *     retCd_OK：取得済み
  *     retCd_NG：異常発生
  *     retCd_NoData：データ無し
  */
  function get給与明細付録項目Data(
      i会社コード   in varchar2,
      i給与支払年月 in number,
      i社員番号     in number,
      o基本文字5_5  out 給与明細付録項目.基本文字5_5%type,
      o基本文字5_1  out 給与明細付録項目.基本文字5_1%type,
      o基本文字5_2  out 給与明細付録項目.基本文字5_2%type,
      o入社年月日2  out 給与明細付録項目.入社年月日2%type,
      o共通文字1_4  out 給与明細付録項目.共通文字1_4%type,
      o共通文字1_5  out 給与明細付録項目.共通文字1_5%type,
      oErrMsg       out varchar2
  ) return number
  is
  begin
      o基本文字5_5 := '';
      o基本文字5_1 := '';
      o基本文字5_2 := '';
      o入社年月日2 := '';
      o共通文字1_4 := '';
      o共通文字1_5 := '';
      
      select
          基本文字5_5, 基本文字5_1, 基本文字5_2, 入社年月日2, 共通文字1_4, 共通文字1_5
      into
          o基本文字5_5, o基本文字5_1, o基本文字5_2, o入社年月日2, o共通文字1_4, o共通文字1_5
      from
          給与明細付録項目
      where
          会社コード = i会社コード
    	  and 給与支払年月 = i給与支払年月
    	  and 社員番号 = i社員番号;
      
      return retCd_OK;
  exception
      when no_data_found then  --取得データ無し
          oErrMsg := 'データ無し。' 
                     || 'テーブル[給与明細付録項目] 条件[' 
                     || '会社コード=' || i会社コード || ', '
                     || '給与支払年月=' || i給与支払年月 || ', '
                     || '社員番号=' || i社員番号
                     || ']';
          return retCd_NoData;
      when others then
          oErrMsg := 'システムエラー発生[get給与明細付録項目Data()]。'
                     || 'SQLCODE=[' || SQLCODE || '] msg=[' || sqlerrm(SQLCODE) || '] '
                     || 'テーブル[給与明細付録項目] 条件[' 
                     || '会社コード=' || i会社コード || ', '
                     || '給与支払年月=' || i給与支払年月 || ', '
                     || '社員番号=' || i社員番号
                     || ']';
          return retCd_NG;
  end get給与明細付録項目Data;
  
  /**
  * 年齢を計算する
  *
  * 引数
  *    baseDate：基準日付（この日付時点の年齢を計算）
  *    birthday：生年月日
  * 戻り値
  *     retCd_NG:システム例外発生；　以外：年齢
  */
  function calcAge(baseDate in Date, birthday in Date, oErrMsg out varchar2)
  return number
  is
      y number(3,0);
  begin
  
      select trunc(months_between(baseDate, birthday) / 12 ) into y
      from dual;
      
      return y;
  exception
      when others then
          oErrMsg := 'システムエラー発生[calcAge()]。'
                     || 'baseDate=[' || baseDate || '] birthday=[' || birthday || ']'
                     || 'SQLCODE=[' || SQLCODE || '] msg=[' || sqlerrm(SQLCODE) || ']';
          return retCd_NG;
  end;
  
  /**
  *  扶養人数の比較処理
  *
  * 引数
  *     i会社コード
  *     i給与支払年月_cur ：当月
  *     i給与支払年月_pre ：前月
  *     i社員番号
  *     o前_扶養人数
  *     o扶養人数
  *     o差_扶養人数
  *     onoCurYMFlg      ：当月データ無しフラグ(0:データあり；1:データ無し)
  *     onoPreYMFlg      ：前月データ無しふラグ(0:データあり；1：データ無し)
  *     odiffFlg         ：差異ありフラグ(0:差異無し；1：差異あり)
  *     oErrMsg
  * 戻り値
  *     retCd_OK：正常終了
  *     retCd_NG：異常発生
  */
  function get扶養人数(
      i会社コード       in varchar2,
      i給与支払年月_cur in number,
      i給与支払年月_pre in number,
      i社員番号         in number,
      o前_扶養人数      out C0930前月当月給与支給額比較.前_扶養人数%type,
      o扶養人数         out C0930前月当月給与支給額比較.扶養人数%type,
      o差_扶養人数      out C0930前月当月給与支給額比較.差_扶養人数%type,
      onoCurYMFlg       out number,
      onoPreYMFlg       out number,
      odiffFlg          out number,
      oErrMsg           out varchar2)
  return number
  is
      tmpCurCnt number(2,0) := 0;
      tmpPreCnt number(2,0) := 0;
  begin
      o前_扶養人数 := null;
      o扶養人数 := null;
      o差_扶養人数 := null;
      
      onoCurYMFlg := 0;
      onoPreYMFlg := 0;
      odiffFlg := 0;
      
      --当月扶養人数取得
      begin
          select
              (
               nvl(decode(a.配偶者控除,2,1,a.配偶者控除),0)
          	   + nvl(a.扶養親族,0)
          	   + nvl(a.本人特別障害,0)
          	   + nvl(a.本人その他障害,0)
          	   + nvl(a.本人除く特別障害,0)
          	   + nvl(a.本人除くその他障害,0)
          	   + nvl(decode(a.寡婦,2,1,a.寡婦),0)
          	   + nvl(a.特障同居,0)
          	   + nvl(a.勤労,0)
              ) as cnt
          into tmpCurCnt
          from
              給与明細マスタ項目1 a
          where
              a.会社コード = i会社コード
	          and a.給与支払年月 = i給与支払年月_cur  --当月
              and a.社員番号 = i社員番号;
    
          o扶養人数 := tmpCurCnt;
      exception
          when no_data_found then  --当月データ無し
              tmpCurCnt := 0;
              onoCurYMFlg := 1;
              odiffFlg := null;
      end;
      
      --前月扶養人数取得
      begin
          select
              (
               nvl(decode(a.配偶者控除,2,1,a.配偶者控除),0)
          	   + nvl(a.扶養親族,0)
          	   + nvl(a.本人特別障害,0)
          	   + nvl(a.本人その他障害,0)
          	   + nvl(a.本人除く特別障害,0)
          	   + nvl(a.本人除くその他障害,0)
          	   + nvl(decode(a.寡婦,2,1,a.寡婦),0)
          	   + nvl(a.特障同居,0)
          	   + nvl(a.勤労,0)
              )as cnt
          into tmpPreCnt
          from
              給与明細マスタ項目1 a
          where
              a.会社コード = i会社コード
	          and a.給与支払年月 = i給与支払年月_pre  --前月
              and a.社員番号 = i社員番号;
    
          o前_扶養人数 := tmpPreCnt;
      exception
          when no_data_found then  --前月データ無し
              tmpPreCnt := 0;
              onoPreYMFlg := 1;
              odiffFlg := null;
      end;
      
      o差_扶養人数 := tmpCurCnt - tmpPreCnt;
      if o差_扶養人数 <> 0 then  --差異あり
          odiffFlg := 1;
      end if;
  
      return retCd_OK;
  exception
      when others then
          oErrMsg := 'システムエラー発生[get扶養人数()]。'
                     || 'SQLCODE=[' || SQLCODE || '] msg=[' || sqlerrm(SQLCODE) || '] '
                     || 'テーブル[給与明細マスタ項目1] 条件[' 
                     || '会社コード=' || i会社コード || ', '
                     || '給与支払年月_cur=' || i給与支払年月_cur || ', '
                     || '給与支払年月_pre=' || i給与支払年月_pre || ', '
                     || '社員番号=' || i社員番号
                     || ']';
          return retCd_NG;
  end;
  
  /**
  * 「経理用給与明細親番項目」テーブルの差分処理
  *
  * 引数
  *     i会社コード
  *     i給与支払年月_cur ：当月
  *     i給与支払年月_pre ：前月
  *     i社員番号
  *     ...
  *     onoCurYMFlg      ：当月データ無しフラグ(0:データあり；1:データ無し)
  *     onoPreYMFlg      ：前月データ無しふラグ(0:データあり；1：データ無し)
  *     odiffFlg         ：差異ありフラグ(0:差異無し；1：差異あり)
  *     oErrMsg
  * 戻り値
  *     retCd_OK：正常終了
  *     retCd_NG：例外発生
  */
  function get経理用給与明細親番項目Data(
      i会社コード       in varchar2,
      i給与支払年月_cur in number,
      i給与支払年月_pre in number,
      i社員番号         in number,
      i税区分           in C0930前月当月給与支給額比較.税区分%type,
      O前_基本給         out C0930前月当月給与支給額比較.前_基本給%type,
      o基本給            out C0930前月当月給与支給額比較.基本給%type,
      o差_基本給         out C0930前月当月給与支給額比較.差_基本給%type,
      o前_手当A          out C0930前月当月給与支給額比較.前_手当A%type,
      o手当A             out C0930前月当月給与支給額比較.手当A%type,
      o差_手当A          out C0930前月当月給与支給額比較.差_手当A%type,
      o前_手当B          out C0930前月当月給与支給額比較.前_手当B%type,
      o手当B             out C0930前月当月給与支給額比較.手当B%type,
      o差_手当B          out C0930前月当月給与支給額比較.差_手当B%type,
      o前_手当C          out C0930前月当月給与支給額比較.前_手当C%type,
      o手当C             out C0930前月当月給与支給額比較.手当C%type,
      o差_手当C          out C0930前月当月給与支給額比較.差_手当C%type,
      o前_手当D          out C0930前月当月給与支給額比較.前_手当D%type,
      o手当D             out C0930前月当月給与支給額比較.手当D%type,
      o差_手当D          out C0930前月当月給与支給額比較.差_手当D%type,
      o前_手当E          out C0930前月当月給与支給額比較.前_手当E%type,
      o手当E             out C0930前月当月給与支給額比較.手当E%type,
      o差_手当E          out C0930前月当月給与支給額比較.差_手当E%type,
      o前_手当F          out C0930前月当月給与支給額比較.前_手当F%type,
      o手当F             out C0930前月当月給与支給額比較.手当F%type,
      o差_手当F          out C0930前月当月給与支給額比較.差_手当F%type,
      o前_手当G          out C0930前月当月給与支給額比較.前_手当G%type,
      o手当G             out C0930前月当月給与支給額比較.手当G%type,
      o差_手当G          out C0930前月当月給与支給額比較.差_手当G%type,
      o前_手当H          out C0930前月当月給与支給額比較.前_手当H%type,
      o手当H             out C0930前月当月給与支給額比較.手当H%type,
      o差_手当H          out C0930前月当月給与支給額比較.差_手当H%type,
      o前_時間外A        out C0930前月当月給与支給額比較.前_時間外A%type,
      o時間外A           out C0930前月当月給与支給額比較.時間外A%type,
      o差_時間外A        out C0930前月当月給与支給額比較.差_時間外A%type,
      o前_時間外B        out C0930前月当月給与支給額比較.前_時間外B%type,
      o時間外B           out C0930前月当月給与支給額比較.時間外B%type,
      o差_時間外B        out C0930前月当月給与支給額比較.差_時間外B%type,
      o前_時間外C        out C0930前月当月給与支給額比較.前_時間外C%type,
      o時間外C           out C0930前月当月給与支給額比較.時間外C%type,
      o差_時間外C        out C0930前月当月給与支給額比較.差_時間外C%type,
      o前_時間外D        out C0930前月当月給与支給額比較.前_時間外D%type,
      o時間外D           out C0930前月当月給与支給額比較.時間外D%type,
      o差_時間外D        out C0930前月当月給与支給額比較.差_時間外D%type,
      o前_休日A          out C0930前月当月給与支給額比較.前_休日A%type,
      o休日A             out C0930前月当月給与支給額比較.休日A%type,
      o差_休日A          out C0930前月当月給与支給額比較.差_休日A%type,
      o前_休日B          out C0930前月当月給与支給額比較.前_休日B%type,
      o休日B             out C0930前月当月給与支給額比較.休日B%type,
      o差_休日B          out C0930前月当月給与支給額比較.差_休日B%type,
      o前_宿日直A        out C0930前月当月給与支給額比較.前_宿日直A%type,
      o宿日直A           out C0930前月当月給与支給額比較.宿日直A%type,
      o差_宿日直A        out C0930前月当月給与支給額比較.差_宿日直A%type,
      o前_宿日直B        out C0930前月当月給与支給額比較.前_宿日直B%type,
      o宿日直B           out C0930前月当月給与支給額比較.宿日直B%type,
      o差_宿日直B        out C0930前月当月給与支給額比較.差_宿日直B%type,
      o前_手当I          out C0930前月当月給与支給額比較.前_手当I%type,
      o手当I             out C0930前月当月給与支給額比較.手当I%type,
      o差_手当I          out C0930前月当月給与支給額比較.差_手当I%type,
      o前_手当J          out C0930前月当月給与支給額比較.前_手当J%type,
      o手当J             out C0930前月当月給与支給額比較.手当J%type,
      o差_手当J          out C0930前月当月給与支給額比較.差_手当J%type,
      o前_手当K          out C0930前月当月給与支給額比較.前_手当K%type,
      o手当K             out C0930前月当月給与支給額比較.手当K%type,
      o差_手当K          out C0930前月当月給与支給額比較.差_手当K%type,
      o前_手当L          out C0930前月当月給与支給額比較.前_手当L%type,
      o手当L             out C0930前月当月給与支給額比較.手当L%type,
      o差_手当L          out C0930前月当月給与支給額比較.差_手当L%type,
      o前_手当M          out C0930前月当月給与支給額比較.前_手当M%type,
      o手当M             out C0930前月当月給与支給額比較.手当M%type,
      o差_手当M          out C0930前月当月給与支給額比較.差_手当M%type,
      o前_手当N          out C0930前月当月給与支給額比較.前_手当N%type,
      o手当N             out C0930前月当月給与支給額比較.手当N%type,
      o差_手当N          out C0930前月当月給与支給額比較.差_手当N%type,
      o前_手当O          out C0930前月当月給与支給額比較.前_手当O%type,
      o手当O             out C0930前月当月給与支給額比較.手当O%type,
      o差_手当O          out C0930前月当月給与支給額比較.差_手当O%type,
      o前_通勤手当       out C0930前月当月給与支給額比較.前_通勤手当%type,
      o通勤手当          out C0930前月当月給与支給額比較.通勤手当%type,
      o差_通勤手当       out C0930前月当月給与支給額比較.差_通勤手当%type,
      o前_別途支給       out C0930前月当月給与支給額比較.前_別途支給%type,
      o別途支給          out C0930前月当月給与支給額比較.別途支給%type,
      o差_別途支給       out C0930前月当月給与支給額比較.差_別途支給%type,
      o前_支給額合計     out C0930前月当月給与支給額比較.前_支給額合計%type,
      o支給額合計        out C0930前月当月給与支給額比較.支給額合計%type,
      o差_支給額合計     out C0930前月当月給与支給額比較.差_支給額合計%type,
      o前_家族療養付加金 out C0930前月当月給与支給額比較.前_家族療養付加金%type,
      o家族療養付加金    out C0930前月当月給与支給額比較.家族療養付加金%type,
      o差_家族療養付加金 out C0930前月当月給与支給額比較.差_家族療養付加金%type,
      o前_給付金         out C0930前月当月給与支給額比較.前_給付金%type,
      o給付金            out C0930前月当月給与支給額比較.給付金%type,
      o差_給付金         out C0930前月当月給与支給額比較.差_給付金%type,
      o前_その他1        out C0930前月当月給与支給額比較.前_その他1%type,
      oその他1           out C0930前月当月給与支給額比較.その他1%type,
      o差_その他1        out C0930前月当月給与支給額比較.差_その他1%type,
      o前_非課税合計     out C0930前月当月給与支給額比較.前_非課税合計%type,
      o非課税合計        out C0930前月当月給与支給額比較.非課税合計%type,
      o差_非課税合計     out C0930前月当月給与支給額比較.差_非課税合計%type,
      o前_課税合計       out C0930前月当月給与支給額比較.前_課税合計%type,
      o課税合計          out C0930前月当月給与支給額比較.課税合計%type,
      o差_課税合計       out C0930前月当月給与支給額比較.差_課税合計%type,
      o前_総支給額       out C0930前月当月給与支給額比較.前_総支給額%type,
      o総支給額          out C0930前月当月給与支給額比較.総支給額%type,
      o差_総支給額       out C0930前月当月給与支給額比較.差_総支給額%type,
      o前_差し引き支給額 out C0930前月当月給与支給額比較.前_差し引き支給額%type,
      o差し引き支給額    out C0930前月当月給与支給額比較.差し引き支給額%type,
      o差_差し引き支給額 out C0930前月当月給与支給額比較.差_差し引き支給額%type,            
      onoCurYMFlg       out number,
      onoPreYMFlg       out number,
      odiffFlg          out number,
      oErrMsg           out varchar2)
  return number
  is
      cursor 経理用給与明細親番項目Rec(p会社コード varchar2, p給与支払年月 number, p社員番号 number) is
          select
            a.基本給,
          	a.手当A,
          	a.手当B,
          	a.手当C,
          	a.手当D,
          	a.手当E,
          	a.手当F,
          	a.手当G,
          	a.手当H,
          	a.時間外A,
          	a.時間外B,
          	a.時間外C,
          	a.時間外D,
          	a.休日A,
          	a.休日B,
          	a.宿日直A,
          	a.宿日直B,
          	a.手当I,
          	a.手当J,
          	a.手当K,
          	a.手当L,
          	a.手当M,
          	a.手当N,
          	a.手当O,
          	a.通勤手当,
          	a.別途支給,
          	a.支給額合計,
          	a.家族療養付加金,
          	a.給付金,
          	a.その他1,
          	a.差し引き支給額,
          	a.所得税対象額,
          	a.健保料,
          	a.厚保料,
          	a.所得税対象額マイナス,
          	b.汎用S数値小数18_3
          from
              経理用給与明細親番項目 a,
          	  給与明細付録項目3      b
          where
              a.会社コード = b.会社コード
          	  and a.給与支払年月 = b.給与支払年月
          	  and a.社員番号 = b.社員番号
              and a.会社コード = p会社コード      --会社コード
          	  and a.給与支払年月 = p給与支払年月  --給与支払年月
          	  and a.社員番号 = p社員番号;         --社員番号

      curMonthRec 経理用給与明細親番項目Rec%rowtype;  --当月データ
      preMonthRec 経理用給与明細親番項目Rec%rowtype;  --前月データ
      
      tmpCur非課税合計 number(9,0) := 0;
      tmpPre非課税合計 number(9,0) := 0;
      
      tmpCur課税合計   number(9,0) := 0;
      tmpPre課税合計   number(9,0) := 0;
      
      tmpCur総支給額   number(9,0) := 0;
      tmpPre総支給額   number(9,0) := 0;
      
      --差異ありフラグ true:差異あり
      isDiff boolean := false;
  begin
  
      --初期化
      onoCurYMFlg := 0;
      onoPreYMFlg := 0;
      odiffFlg := 0;

      o前_基本給 := null;
      o基本給 := null;
      o差_基本給 := null;
      o前_手当A := null;
      o手当A := null;
      o差_手当A := null;
      o前_手当B := null;
      o手当B := null;
      o差_手当B := null;
      o前_手当C := null;
      o手当C := null;
      o差_手当C := null;
      o前_手当D := null;
      o手当D := null;
      o差_手当D := null;
      o前_手当E := null;
      o手当E := null;
      o差_手当E := null;
      o前_手当F := null;
      o手当F := null;
      o差_手当F := null;
      o前_手当G := null;
      o手当G := null;
      o差_手当G := null;
      o前_手当H := null;
      o手当H := null;
      o差_手当H := null;
      o前_時間外A := null;
      o時間外A := null;
      o差_時間外A := null;
      o前_時間外B := null;
      o時間外B := null;
      o差_時間外B := null;
      o前_時間外C := null;
      o時間外C := null;
      o差_時間外C := null;
      o前_時間外D := null;
      o時間外D := null;
      o差_時間外D := null;
      o前_休日A := null;
      o休日A := null;
      o差_休日A := null;
      o前_休日B := null;
      o休日B := null;
      o差_休日B := null;
      o前_宿日直A := null;
      o宿日直A := null;
      o差_宿日直A := null;
      o前_宿日直B := null;
      o宿日直B := null;
      o差_宿日直B := null;
      o前_手当I := null;
      o手当I := null;
      o差_手当I := null;
      o前_手当J := null;
      o手当J := null;
      o差_手当J := null;
      o前_手当K := null;
      o手当K := null;
      o差_手当K := null;
      o前_手当L := null;
      o手当L := null;
      o差_手当L := null;
      o前_手当M := null;
      o手当M := null;
      o差_手当M := null;
      o前_手当N := null;
      o手当N := null;
      o差_手当N := null;
      o前_手当O := null;
      o手当O := null;
      o差_手当O := null;
      o前_通勤手当 := null;
      o通勤手当 := null;
      o差_通勤手当 := null;
      o前_別途支給 := null;
      o別途支給 := null;
      o差_別途支給 := null;
      o前_支給額合計 := null;
      o支給額合計 := null;
      o差_支給額合計 := null;
      o前_家族療養付加金 := null;
      o家族療養付加金 := null;
      o差_家族療養付加金 := null;
      o前_給付金 := null;
      o給付金 := null;
      o差_給付金 := null;
      o前_その他1 := null;
      oその他1 := null;
      o差_その他1 := null;
      o前_非課税合計 := null;
      o非課税合計 := null;
      o差_非課税合計 := null;
      o前_課税合計 := null;
      o課税合計 := null;
      o差_課税合計 := null;
      o前_総支給額 := null;
      o総支給額 := null;
      o差_総支給額 := null;
      o前_差し引き支給額 := null;
      o差し引き支給額 := null;
      o差_差し引き支給額 := null;
      
      --当月データ取得
      open 経理用給与明細親番項目Rec(i会社コード, i給与支払年月_cur, i社員番号);
      fetch 経理用給与明細親番項目Rec into curMonthRec;
      
      if 経理用給与明細親番項目Rec%notfound then  --当月データ無し
          onoCurYMFlg := 1;  --当月データ無しフラグ設定
          odiffFlg := null;
          
          curMonthRec.基本給 := 0;
          curMonthRec.手当A := 0;
          curMonthRec.手当B := 0;
          curMonthRec.手当C := 0;
          curMonthRec.手当D := 0;
          curMonthRec.手当E := 0;
          curMonthRec.手当F := 0;
          curMonthRec.手当G := 0;
          curMonthRec.手当H := 0;
          curMonthRec.時間外A := 0;
          curMonthRec.時間外B := 0;
          curMonthRec.時間外C := 0;
          curMonthRec.時間外D := 0;
          curMonthRec.休日A := 0;
          curMonthRec.休日B := 0;
          curMonthRec.宿日直A := 0;
          curMonthRec.宿日直B := 0;
          curMonthRec.手当I := 0;
          curMonthRec.手当J := 0;
          curMonthRec.手当K := 0;
          curMonthRec.手当L := 0;
          curMonthRec.手当M := 0;
          curMonthRec.手当N := 0;
          curMonthRec.手当O := 0;
          curMonthRec.通勤手当 := 0;
          curMonthRec.別途支給 := 0;
          curMonthRec.支給額合計 := 0;
          curMonthRec.家族療養付加金 := 0;
          curMonthRec.給付金 := 0;
          curMonthRec.その他1 := 0;
          curMonthRec.差し引き支給額 := 0;
          curMonthRec.所得税対象額 := 0;
          curMonthRec.健保料 := 0;
          curMonthRec.厚保料 := 0;
          curMonthRec.所得税対象額マイナス := 0;
          curMonthRec.汎用S数値小数18_3 := 0;          
      else  --当月データあり
          o基本給 := curMonthRec.基本給;
          o手当A := curMonthRec.手当A;
          o手当B := curMonthRec.手当B;
          o手当C := curMonthRec.手当C;
          o手当D := curMonthRec.手当D;
          o手当E := curMonthRec.手当E;
          o手当F := curMonthRec.手当F;
          o手当G := curMonthRec.手当G;
          o手当H := curMonthRec.手当H;
          o時間外A := curMonthRec.時間外A;
          o時間外B := curMonthRec.時間外B;
          o時間外C := curMonthRec.時間外C;
          o時間外D := curMonthRec.時間外D;
          o休日A := curMonthRec.休日A;
          o休日B := curMonthRec.休日B;
          o宿日直A := curMonthRec.宿日直A;
          o宿日直B := curMonthRec.宿日直B;
          o手当I := curMonthRec.手当I;
          o手当J := curMonthRec.手当J;
          o手当K := curMonthRec.手当K;
          o手当L := curMonthRec.手当L;
          o手当M := curMonthRec.手当M;
          o手当N := curMonthRec.手当N;
          o手当O := curMonthRec.手当O;
          o通勤手当 := curMonthRec.通勤手当;
          o別途支給 := curMonthRec.別途支給;
          o支給額合計 := curMonthRec.支給額合計;
          o家族療養付加金 := curMonthRec.家族療養付加金;
          o給付金 := curMonthRec.給付金;
          oその他1 := curMonthRec.その他1;
          
          tmpCur非課税合計 := curMonthRec.家族療養付加金 + curMonthRec.給付金 + curMonthRec.その他1;
          o非課税合計 := tmpCur非課税合計;
          
          if i税区分 in (1, 3, 4) then
              tmpCur課税合計 := curMonthRec.所得税対象額 
                                + curMonthRec.健保料 
                                + curMonthRec.厚保料 
                                + curMonthRec.汎用S数値小数18_3
                                + curMonthRec.所得税対象額マイナス;
          else
              tmpCur課税合計 := curMonthRec.所得税対象額;
          end if;
          o課税合計 := tmpCur課税合計;
          
          tmpCur総支給額 := curMonthRec.支給額合計 + curMonthRec.家族療養付加金 + curMonthRec.給付金 + curMonthRec.その他1;
          o総支給額 := tmpCur総支給額;
          
          o差し引き支給額 := curMonthRec.差し引き支給額;      
      end if;
      close 経理用給与明細親番項目Rec;
          
      --前月データ取得
      open 経理用給与明細親番項目Rec(i会社コード, i給与支払年月_pre, i社員番号);
      fetch 経理用給与明細親番項目Rec into preMonthRec;
      
      if 経理用給与明細親番項目Rec%notfound then  --前月データ無し
          onoPreYMFlg := 1;  --前月データ無しフラグ設定
          odiffFlg := null;
          
          preMonthRec.基本給 := 0;
          preMonthRec.手当A := 0;
          preMonthRec.手当B := 0;
          preMonthRec.手当C := 0;
          preMonthRec.手当D := 0;
          preMonthRec.手当E := 0;
          preMonthRec.手当F := 0;
          preMonthRec.手当G := 0;
          preMonthRec.手当H := 0;
          preMonthRec.時間外A := 0;
          preMonthRec.時間外B := 0;
          preMonthRec.時間外C := 0;
          preMonthRec.時間外D := 0;
          preMonthRec.休日A := 0;
          preMonthRec.休日B := 0;
          preMonthRec.宿日直A := 0;
          preMonthRec.宿日直B := 0;
          preMonthRec.手当I := 0;
          preMonthRec.手当J := 0;
          preMonthRec.手当K := 0;
          preMonthRec.手当L := 0;
          preMonthRec.手当M := 0;
          preMonthRec.手当N := 0;
          preMonthRec.手当O := 0;
          preMonthRec.通勤手当 := 0;
          preMonthRec.別途支給 := 0;
          preMonthRec.支給額合計 := 0;
          preMonthRec.家族療養付加金 := 0;
          preMonthRec.給付金 := 0;
          preMonthRec.その他1 := 0;
          preMonthRec.差し引き支給額 := 0;
          preMonthRec.所得税対象額 := 0;
          preMonthRec.健保料 := 0;
          preMonthRec.厚保料 := 0;
          preMonthRec.所得税対象額マイナス := 0;
          preMonthRec.汎用S数値小数18_3 := 0;
          
      else  --前月データあり
          o前_基本給 := preMonthRec.基本給;
          o前_手当A := preMonthRec.手当A;
          o前_手当B := preMonthRec.手当B;
          o前_手当C := preMonthRec.手当C;
          o前_手当D := preMonthRec.手当D;
          o前_手当E := preMonthRec.手当E;
          o前_手当F := preMonthRec.手当F;
          o前_手当G := preMonthRec.手当G;
          o前_手当H := preMonthRec.手当H;
          o前_時間外A := preMonthRec.時間外A;
          o前_時間外B := preMonthRec.時間外B;
          o前_時間外C := preMonthRec.時間外C;
          o前_時間外D := preMonthRec.時間外D;
          o前_休日A := preMonthRec.休日A;
          o前_休日B := preMonthRec.休日B;
          o前_宿日直A := preMonthRec.宿日直A;
          o前_宿日直B := preMonthRec.宿日直B;
          o前_手当I := preMonthRec.手当I;
          o前_手当J := preMonthRec.手当J;
          o前_手当K := preMonthRec.手当K;
          o前_手当L := preMonthRec.手当L;
          o前_手当M := preMonthRec.手当M;
          o前_手当N := preMonthRec.手当N;
          o前_手当O := preMonthRec.手当O;
          o前_通勤手当 := preMonthRec.通勤手当;
          o前_別途支給 := preMonthRec.別途支給;
          o前_支給額合計 := preMonthRec.支給額合計;
          o前_家族療養付加金 := preMonthRec.家族療養付加金;
          o前_給付金 := preMonthRec.給付金;
          o前_その他1 := preMonthRec.その他1;
          
          tmpPre非課税合計 := preMonthRec.家族療養付加金 + preMonthRec.給付金 + preMonthRec.その他1;
          o前_非課税合計 := tmpPre非課税合計;
          
          if i税区分 in (1, 3, 4) then
              tmpPre課税合計 := preMonthRec.所得税対象額 
                                + preMonthRec.健保料 
                                + preMonthRec.厚保料 
                                + preMonthRec.汎用S数値小数18_3
                                + preMonthRec.所得税対象額マイナス;
          else
              tmpPre課税合計 := preMonthRec.所得税対象額;
          end if;
          o前_課税合計 := tmpPre課税合計;
          
          tmpPre総支給額 := preMonthRec.支給額合計 + preMonthRec.家族療養付加金 + preMonthRec.給付金 + preMonthRec.その他1;
          o前_総支給額 := tmpPre総支給額;
          
          o前_差し引き支給額 := preMonthRec.差し引き支給額;
      end if;
      close 経理用給与明細親番項目Rec;
      
      --差額計算
      o差_基本給 := curMonthRec.基本給 - preMonthRec.基本給;
      if o差_基本給 != 0 then
          isDiff := true;
      end if;
      
      o差_手当A := curMonthRec.手当A - preMonthRec.手当A;
      if o差_手当A != 0 then
          isDiff := true;
      end if;
      
      o差_手当B := curMonthRec.手当B - preMonthRec.手当B;
      if o差_手当B != 0 then
          isDiff := true;
      end if;
      
      o差_手当C := curMonthRec.手当C - preMonthRec.手当C;
      if o差_手当C != 0 then
          isDiff := true;
      end if;
      
      o差_手当D := curMonthRec.手当D - preMonthRec.手当D;
      if o差_手当D != 0 then
          isDiff := true;
      end if;
      
      o差_手当E := curMonthRec.手当E - preMonthRec.手当E;
      if o差_手当E != 0 then
          isDiff := true;
      end if;
      
      o差_手当F := curMonthRec.手当F - preMonthRec.手当F;
      if o差_手当F != 0 then
          isDiff := true;
      end if;
      
      o差_手当G := curMonthRec.手当G - preMonthRec.手当G;
      if o差_手当G != 0 then
          isDiff := true;
      end if;
      
      o差_手当H := curMonthRec.手当H - preMonthRec.手当H;
      if o差_手当H != 0 then
          isDiff := true;
      end if;
      
      o差_時間外A := curMonthRec.時間外A - preMonthRec.時間外A;
      if o差_時間外A != 0 then
          isDiff := true;
      end if;
      
      o差_時間外B := curMonthRec.時間外B - preMonthRec.時間外B;
      if o差_時間外B != 0 then
          isDiff := true;
      end if;
      
      o差_時間外C := curMonthRec.時間外C - preMonthRec.時間外C;
      if o差_時間外C != 0 then
          isDiff := true;
      end if;
      
      o差_時間外D := curMonthRec.時間外D - preMonthRec.時間外D;
      if o差_時間外D != 0 then
          isDiff := true;
      end if;
      
      o差_休日A := curMonthRec.休日A - preMonthRec.休日A;
      if o差_休日A != 0 then
          isDiff := true;
      end if;
      
      o差_休日B := curMonthRec.休日B - preMonthRec.休日B;
      if o差_休日B != 0 then
          isDiff := true;
      end if;
      
      o差_宿日直A := curMonthRec.宿日直A - preMonthRec.宿日直A;
      if o差_宿日直A != 0 then
          isDiff := true;
      end if;
      
      o差_宿日直B := curMonthRec.宿日直B - preMonthRec.宿日直B;
      if o差_宿日直B != 0 then
          isDiff := true;
      end if;
      
      o差_手当I := curMonthRec.手当I - preMonthRec.手当I;
      if o差_手当I != 0 then
          isDiff := true;
      end if;
      
      o差_手当J := curMonthRec.手当J - preMonthRec.手当J;
      if o差_手当J != 0 then
          isDiff := true;
      end if;
      
      o差_手当K := curMonthRec.手当K - preMonthRec.手当K;
      if o差_手当K != 0 then
          isDiff := true;
      end if;
      
      o差_手当L := curMonthRec.手当L - preMonthRec.手当L;
      if o差_手当L != 0 then
          isDiff := true;
      end if;
      
      o差_手当M := curMonthRec.手当M - preMonthRec.手当M;
      if o差_手当M != 0 then
          isDiff := true;
      end if;
      
      o差_手当N := curMonthRec.手当N - preMonthRec.手当N;
      if o差_手当N != 0 then
          isDiff := true;
      end if;
      
      o差_手当O := curMonthRec.手当O - preMonthRec.手当O;
      if o差_手当O != 0 then
          isDiff := true;
      end if;
      
      o差_通勤手当 := curMonthRec.通勤手当 - preMonthRec.通勤手当;
      if o差_通勤手当 != 0 then
          isDiff := true;
      end if;
      
      o差_別途支給 := curMonthRec.別途支給 - preMonthRec.別途支給;
      if o差_別途支給 != 0 then
          isDiff := true;
      end if;
      
      o差_支給額合計 := curMonthRec.支給額合計 - preMonthRec.支給額合計;
      if o差_支給額合計 != 0 then
          isDiff := true;
      end if;
      
      o差_家族療養付加金 := curMonthRec.家族療養付加金 - preMonthRec.家族療養付加金;
      if o差_家族療養付加金 != 0 then
          isDiff := true;
      end if;
      
      o差_給付金 := curMonthRec.給付金 - preMonthRec.給付金;
      if o差_給付金 != 0 then
          isDiff := true;
      end if;
      
      o差_その他1 := curMonthRec.その他1 - preMonthRec.その他1;
      if o差_その他1 != 0 then
          isDiff := true;
      end if;
      
      o差_非課税合計 := tmpCur非課税合計 - tmpPre非課税合計;
      if o差_非課税合計 != 0 then
          isDiff := true;
      end if;
      
      o差_課税合計 := tmpCur課税合計 - tmpPre課税合計;
      if o差_課税合計 != 0 then
          isDiff := true;
      end if;
      
      o差_総支給額 := tmpCur総支給額 - tmpPre総支給額;
      if o差_総支給額 != 0 then
          isDiff := true;
      end if;
      
      o差_差し引き支給額 := curMonthRec.差し引き支給額 - preMonthRec.差し引き支給額;
      if o差_差し引き支給額 != 0 then
          isDiff := true;
      end if;
  
      if  isDiff = true then
          odiffFlg := 1;
      end if;
      
      return retCd_OK;
  exception
      when others then
          oErrMsg := 'システムエラー発生[get経理用給与明細親番項目Data]。'
                     || 'SQLCODE=[' || SQLCODE || '] msg=[' || sqlerrm(SQLCODE) || '] '
                     || 'テーブル[経理用給与明細親番項目] 条件[' 
                     || '会社コード=' || i会社コード || ', '
                     || '給与支払年月_cur=' || i給与支払年月_cur || ', '
                     || '給与支払年月_pre=' || i給与支払年月_pre || ', '
                     || '社員番号=' || i社員番号 || ', '
                     || '税区分=' || i税区分
                     || ']';
          return retCd_NG;
  end get経理用給与明細親番項目Data;
  
    /**
  * 「給与明細変動項目」の差分データを取得する
  *
  * 戻り値
  *     retCd_OK：正常終了
  *     retCd_NG：例外発生
  */
  function get給与明細変動項目Data(
      i会社コード        in varchar2,
      i給与支払年月_cur  in number,
      i給与支払年月_pre  in number,
      i社員番号          in number,
      o変動データ金額Arr out 変動データ金額ArrType,
      onoCurYMFlg        out number,
      onoPreYMFlg        out number,
      odiffFlg           out number,
      oErrMsg            out varchar2)
  return number
  is
  
      --「給与明細変動項目」テーブルの抽出カーソル
      -- 「親番変動コード・枝番変動コード」は必ず出力CSVテーブルにある項目であること
      -- （余計な項目取得するとエラーになる：この枝番変動コードで動的にCSVテーブルの項目名を生成しているので）
      cursor 給与明細変動項目Cur(p会社コード varchar2, p給与支払年月 number, p社員番号 number) is
          select
            a.親番変動コード,
          	a.枝番変動コード,
          	sum(nvl(a.変動データ金額,0)) as 変動データ金額
          from
              給与明細変動項目 a
          where
              a.会社コード = p会社コード
          	and a.給与支払年月 = p給与支払年月
          	and a.社員番号 = p社員番号
          	and (
          	    (a.親番変動コード = '803' and a.枝番変動コード between '100' and '128')
          		or (a.親番変動コード = '806' and a.枝番変動コード between '130' and '145')
          		or (a.親番変動コード = '807' and a.枝番変動コード between '600' and '603')
          		or (a.親番変動コード = '808' and a.枝番変動コード between '630' and '658')
          		or (a.親番変動コード = '826' and a.枝番変動コード between '160' and '199')
          		or (a.親番変動コード = '828' and a.枝番変動コード between '480' and '487')
          		or (a.親番変動コード = '830' and a.枝番変動コード between '450' and '451')
                  )
          group by 
              a.親番変動コード,
              a.枝番変動コード
          order by 
              a.親番変動コード,
              a.枝番変動コード;
  
      curMonthRec 給与明細変動項目Cur%rowtype;  --当月データ
      preMonthRec 給与明細変動項目Cur%rowtype;  --前月データ
      
      tmpKey varchar2(10);
      
      tmpValCur number(9,0);
      tmpValPre number(9,0);
      
  begin
  
      --初期化
      onoCurYMFlg := 1;  --当月無し
      onoPreYMFlg := 1;  --前月無し
      odiffFlg := null;  --差分ありフラグ無効に
      
      --当月データ取得
      open 給与明細変動項目Cur(i会社コード, i給与支払年月_cur, i社員番号);
      loop
          fetch 給与明細変動項目Cur into curMonthRec;
          exit when 給与明細変動項目Cur%notfound;
          
          --データが１個でもあれば、当月ありに
          onoCurYMFlg := 0;
          
          --該当当月データを配列に保存
          tmpKey := curMonthRec.親番変動コード || curMonthRec.枝番変動コード;
          o変動データ金額Arr(tmpKey).親番変動コード := curMonthRec.親番変動コード;
          o変動データ金額Arr(tmpKey).枝番変動コード := curMonthRec.枝番変動コード;
          o変動データ金額Arr(tmpKey).変動データ金額_cur := curMonthRec.変動データ金額;  --当月金額
      end loop;
      close 給与明細変動項目Cur;
      
      --前月データ取得
       open 給与明細変動項目Cur(i会社コード, i給与支払年月_pre, i社員番号);
       loop
           fetch 給与明細変動項目Cur into preMonthRec;
           exit when 給与明細変動項目Cur%notfound;
           
           --データが１個でもあれば、前月ありに
           onoPreYMFlg := 0;
           
           --該当前月データを配列に保存
           tmpKey := preMonthRec.親番変動コード || preMonthRec.枝番変動コード;
           o変動データ金額Arr(tmpKey).親番変動コード := preMonthRec.親番変動コード;
           o変動データ金額Arr(tmpKey).枝番変動コード := preMonthRec.枝番変動コード;
           o変動データ金額Arr(tmpKey).変動データ金額_pre := preMonthRec.変動データ金額;  --当月金額
       end loop;
       close 給与明細変動項目Cur;
       
       if o変動データ金額Arr.count > 0 then
           --差分計算
           tmpKey := o変動データ金額Arr.first;
           loop
           
               if o変動データ金額Arr(tmpKey).変動データ金額_cur is null 
                  and o変動データ金額Arr(tmpKey).変動データ金額_pre is null then  --当月、前月同時にnull
              
                  --比較しない（比較する意味無し）
                  null;
               else  --両方、それとも何方かに値あり
               
                   if o変動データ金額Arr(tmpKey).変動データ金額_cur is null then
                       tmpValCur := 0;
                   else
                       tmpValCur := o変動データ金額Arr(tmpKey).変動データ金額_cur;
                   end if;
               
                   if o変動データ金額Arr(tmpKey).変動データ金額_pre is null then
                       tmpValPre := 0;
                   else
                       tmpValPre := o変動データ金額Arr(tmpKey).変動データ金額_pre;
                   end if;
                   
                   o変動データ金額Arr(tmpKey).変動データ金額_diff := tmpValCur - tmpValPre;
               
                   --１個でも差分あり時、差分ありフラグ設定
                   if o変動データ金額Arr(tmpKey).変動データ金額_diff <> 0 then
                       odiffFlg := 1;
                   end if;
               
                   end if;
               
               exit when tmpKey = o変動データ金額Arr.last;
               tmpKey := o変動データ金額Arr.next(tmpKey);
           end loop;
       end if;
  
      return retCd_OK;
  exception
      when others then
          oErrMsg := 'システムエラー発生[get給与明細変動項目Data()]。'
                     || 'SQLCODE=[' || SQLCODE || '] msg=[' || sqlerrm(SQLCODE) || '] '
                     || 'テーブル[給与明細変動項目] 条件[' 
                     || '会社コード=' || i会社コード || ', '
                     || '給与支払年月_cur=' || i給与支払年月_cur || ', '
                     || '給与支払年月_pre=' || i給与支払年月_pre || ', '
                     || '社員番号=' || i社員番号
                     || ']';
          return retCd_NG;
  end get給与明細変動項目Data;
  
  /**
  * 「C0930前月当月給与支給額比較」に新規登録
  *  ※注：「変動xxxx」項目は登録しない
  *
  * 戻り値
  *     retCd_OK：正常終了
  *     retCd_NG：例外発生
  */
  function C0930給与支給額比較登録(
      i会社コード                    in varchar2,
      i給与支払年月_cur              in number,
      i給与支払年月_pre              in number,
      C0930前月当月給与支給額比較Rec in C0930前月当月給与支給額比較%rowtype,
      oErrMsg                        out varchar2)
  return number
  is
  begin
  
      insert into C0930前月当月給与支給額比較(
          会社コード,
          給与支払年月,
          社員番号,
          差異,
          所属コード,
          所属名,
          通称氏名,
          通称氏名カナ,
          戸籍氏名,
          氏名,
          給与区分,
          基本文字5_5,
          基本文字5_1,
          基本文字5_2,
          誕生生年月日,
          年齢,
          入社年月日,
          入社年月日2,
          退職年月日,
          休職年月日,
          復職年月日,
          共通文字1_4,
          共通文字1_5,
          税区分,
          前_扶養人数,
          扶養人数,
          差_扶養人数,
          前_基本給,
          基本給,
          差_基本給,
          前_手当A,
          手当A,
          差_手当A,
          前_手当B,
          手当B,
          差_手当B,
          前_手当C,
          手当C,
          差_手当C,
          前_手当D,
          手当D,
          差_手当D,
          前_手当E,
          手当E,
          差_手当E,
          前_手当F,
          手当F,
          差_手当F,
          前_手当G,
          手当G,
          差_手当G,
          前_手当H,
          手当H,
          差_手当H,
          前_時間外A,
          時間外A,
          差_時間外A,
          前_時間外B,
          時間外B,
          差_時間外B,
          前_時間外C,
          時間外C,
          差_時間外C,
          前_時間外D,
          時間外D,
          差_時間外D,
          前_休日A,
          休日A,
          差_休日A,
          前_休日B,
          休日B,
          差_休日B,
          前_宿日直A,
          宿日直A,
          差_宿日直A,
          前_宿日直B,
          宿日直B,
          差_宿日直B,
          前_手当I,
          手当I,
          差_手当I,
          前_手当J,
          手当J,
          差_手当J,
          前_手当K,
          手当K,
          差_手当K,
          前_手当L,
          手当L,
          差_手当L,
          前_手当M,
          手当M,
          差_手当M,
          前_手当N,
          手当N,
          差_手当N,
          前_手当O,
          手当O,
          差_手当O,
          前_通勤手当,
          通勤手当,
          差_通勤手当,
          前_別途支給,
          別途支給,
          差_別途支給,
          前_支給額合計,
          支給額合計,
          差_支給額合計,
          前_家族療養付加金,
          家族療養付加金,
          差_家族療養付加金,
          前_給付金,
          給付金,
          差_給付金,
          前_その他1,
          その他1,
          差_その他1,
          前_非課税合計,
          非課税合計,
          差_非課税合計,
          前_課税合計,
          課税合計,
          差_課税合計,
          前_総支給額,
          総支給額,
          差_総支給額,
          前_差し引き支給額,
          差し引き支給額,
          差_差し引き支給額,
          登録日時,
          登録者)
      values(
          C0930前月当月給与支給額比較Rec.会社コード,
          C0930前月当月給与支給額比較Rec.給与支払年月,
          C0930前月当月給与支給額比較Rec.社員番号,
          C0930前月当月給与支給額比較Rec.差異,
          C0930前月当月給与支給額比較Rec.所属コード,
          C0930前月当月給与支給額比較Rec.所属名,
          C0930前月当月給与支給額比較Rec.通称氏名,
          C0930前月当月給与支給額比較Rec.通称氏名カナ,
          C0930前月当月給与支給額比較Rec.戸籍氏名,
          C0930前月当月給与支給額比較Rec.氏名,
          C0930前月当月給与支給額比較Rec.給与区分,
          C0930前月当月給与支給額比較Rec.基本文字5_5,
          C0930前月当月給与支給額比較Rec.基本文字5_1,
          C0930前月当月給与支給額比較Rec.基本文字5_2,
          C0930前月当月給与支給額比較Rec.誕生生年月日,
          C0930前月当月給与支給額比較Rec.年齢,
          C0930前月当月給与支給額比較Rec.入社年月日,
          C0930前月当月給与支給額比較Rec.入社年月日2,
          C0930前月当月給与支給額比較Rec.退職年月日,
          C0930前月当月給与支給額比較Rec.休職年月日,
          C0930前月当月給与支給額比較Rec.復職年月日,
          C0930前月当月給与支給額比較Rec.共通文字1_4,
          C0930前月当月給与支給額比較Rec.共通文字1_5,
          C0930前月当月給与支給額比較Rec.税区分,
          C0930前月当月給与支給額比較Rec.前_扶養人数,
          C0930前月当月給与支給額比較Rec.扶養人数,
          C0930前月当月給与支給額比較Rec.差_扶養人数,
          C0930前月当月給与支給額比較Rec.前_基本給,
          C0930前月当月給与支給額比較Rec.基本給,
          C0930前月当月給与支給額比較Rec.差_基本給,
          C0930前月当月給与支給額比較Rec.前_手当A,
          C0930前月当月給与支給額比較Rec.手当A,
          C0930前月当月給与支給額比較Rec.差_手当A,
          C0930前月当月給与支給額比較Rec.前_手当B,
          C0930前月当月給与支給額比較Rec.手当B,
          C0930前月当月給与支給額比較Rec.差_手当B,
          C0930前月当月給与支給額比較Rec.前_手当C,
          C0930前月当月給与支給額比較Rec.手当C,
          C0930前月当月給与支給額比較Rec.差_手当C,
          C0930前月当月給与支給額比較Rec.前_手当D,
          C0930前月当月給与支給額比較Rec.手当D,
          C0930前月当月給与支給額比較Rec.差_手当D,
          C0930前月当月給与支給額比較Rec.前_手当E,
          C0930前月当月給与支給額比較Rec.手当E,
          C0930前月当月給与支給額比較Rec.差_手当E,
          C0930前月当月給与支給額比較Rec.前_手当F,
          C0930前月当月給与支給額比較Rec.手当F,
          C0930前月当月給与支給額比較Rec.差_手当F,
          C0930前月当月給与支給額比較Rec.前_手当G,
          C0930前月当月給与支給額比較Rec.手当G,
          C0930前月当月給与支給額比較Rec.差_手当G,
          C0930前月当月給与支給額比較Rec.前_手当H,
          C0930前月当月給与支給額比較Rec.手当H,
          C0930前月当月給与支給額比較Rec.差_手当H,
          C0930前月当月給与支給額比較Rec.前_時間外A,
          C0930前月当月給与支給額比較Rec.時間外A,
          C0930前月当月給与支給額比較Rec.差_時間外A,
          C0930前月当月給与支給額比較Rec.前_時間外B,
          C0930前月当月給与支給額比較Rec.時間外B,
          C0930前月当月給与支給額比較Rec.差_時間外B,
          C0930前月当月給与支給額比較Rec.前_時間外C,
          C0930前月当月給与支給額比較Rec.時間外C,
          C0930前月当月給与支給額比較Rec.差_時間外C,
          C0930前月当月給与支給額比較Rec.前_時間外D,
          C0930前月当月給与支給額比較Rec.時間外D,
          C0930前月当月給与支給額比較Rec.差_時間外D,
          C0930前月当月給与支給額比較Rec.前_休日A,
          C0930前月当月給与支給額比較Rec.休日A,
          C0930前月当月給与支給額比較Rec.差_休日A,
          C0930前月当月給与支給額比較Rec.前_休日B,
          C0930前月当月給与支給額比較Rec.休日B,
          C0930前月当月給与支給額比較Rec.差_休日B,
          C0930前月当月給与支給額比較Rec.前_宿日直A,
          C0930前月当月給与支給額比較Rec.宿日直A,
          C0930前月当月給与支給額比較Rec.差_宿日直A,
          C0930前月当月給与支給額比較Rec.前_宿日直B,
          C0930前月当月給与支給額比較Rec.宿日直B,
          C0930前月当月給与支給額比較Rec.差_宿日直B,
          C0930前月当月給与支給額比較Rec.前_手当I,
          C0930前月当月給与支給額比較Rec.手当I,
          C0930前月当月給与支給額比較Rec.差_手当I,
          C0930前月当月給与支給額比較Rec.前_手当J,
          C0930前月当月給与支給額比較Rec.手当J,
          C0930前月当月給与支給額比較Rec.差_手当J,
          C0930前月当月給与支給額比較Rec.前_手当K,
          C0930前月当月給与支給額比較Rec.手当K,
          C0930前月当月給与支給額比較Rec.差_手当K,
          C0930前月当月給与支給額比較Rec.前_手当L,
          C0930前月当月給与支給額比較Rec.手当L,
          C0930前月当月給与支給額比較Rec.差_手当L,
          C0930前月当月給与支給額比較Rec.前_手当M,
          C0930前月当月給与支給額比較Rec.手当M,
          C0930前月当月給与支給額比較Rec.差_手当M,
          C0930前月当月給与支給額比較Rec.前_手当N,
          C0930前月当月給与支給額比較Rec.手当N,
          C0930前月当月給与支給額比較Rec.差_手当N,
          C0930前月当月給与支給額比較Rec.前_手当O,
          C0930前月当月給与支給額比較Rec.手当O,
          C0930前月当月給与支給額比較Rec.差_手当O,
          C0930前月当月給与支給額比較Rec.前_通勤手当,
          C0930前月当月給与支給額比較Rec.通勤手当,
          C0930前月当月給与支給額比較Rec.差_通勤手当,
          C0930前月当月給与支給額比較Rec.前_別途支給,
          C0930前月当月給与支給額比較Rec.別途支給,
          C0930前月当月給与支給額比較Rec.差_別途支給,
          C0930前月当月給与支給額比較Rec.前_支給額合計,
          C0930前月当月給与支給額比較Rec.支給額合計,
          C0930前月当月給与支給額比較Rec.差_支給額合計,
          C0930前月当月給与支給額比較Rec.前_家族療養付加金,
          C0930前月当月給与支給額比較Rec.家族療養付加金,
          C0930前月当月給与支給額比較Rec.差_家族療養付加金,
          C0930前月当月給与支給額比較Rec.前_給付金,
          C0930前月当月給与支給額比較Rec.給付金,
          C0930前月当月給与支給額比較Rec.差_給付金,
          C0930前月当月給与支給額比較Rec.前_その他1,
          C0930前月当月給与支給額比較Rec.その他1,
          C0930前月当月給与支給額比較Rec.差_その他1,
          C0930前月当月給与支給額比較Rec.前_非課税合計,
          C0930前月当月給与支給額比較Rec.非課税合計,
          C0930前月当月給与支給額比較Rec.差_非課税合計,
          C0930前月当月給与支給額比較Rec.前_課税合計,
          C0930前月当月給与支給額比較Rec.課税合計,
          C0930前月当月給与支給額比較Rec.差_課税合計,
          C0930前月当月給与支給額比較Rec.前_総支給額,
          C0930前月当月給与支給額比較Rec.総支給額,
          C0930前月当月給与支給額比較Rec.差_総支給額,
          C0930前月当月給与支給額比較Rec.前_差し引き支給額,
          C0930前月当月給与支給額比較Rec.差し引き支給額,
          C0930前月当月給与支給額比較Rec.差_差し引き支給額,
          sysdate,
          C0930前月当月給与支給額比較Rec.登録者
      );
  
      return retCd_OK;
  exception
      when others then
          oErrMsg := 'システムエラー発生[C0930給与支給額比較登録()]。'
                     || 'SQLCODE=[' || SQLCODE || '] msg=[' || sqlerrm(SQLCODE) || '] '
                     || 'テーブル[C0930前月当月給与支給額比較] へinsert ' 
                     || '会社コード=' || C0930前月当月給与支給額比較Rec.会社コード || ', '
                     || '給与支払年月_cur=' || C0930前月当月給与支給額比較Rec.給与支払年月 || ', '
                     || '給与支払年月_pre=' || i給与支払年月_pre || ', '
                     || '社員番号=' || C0930前月当月給与支給額比較Rec.社員番号
                     || ']';
          return retCd_NG;
  end C0930給与支給額比較登録;

END "KP930当月前月比較PKG";