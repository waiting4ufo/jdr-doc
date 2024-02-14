CREATE OR REPLACE 
PACKAGE KP930当月前月比較PKG AS 

  retCd_NG constant number := -1;
  retCd_OK constant number := 0;
  retCd_NoData constant number := 1;
  
  
  type 変動データ金額Rec is record (
      親番変動コード 給与明細変動項目.親番変動コード%type default null,
      枝番変動コード 給与明細変動項目.枝番変動コード%type default null,
      変動データ金額_cur number(9,0) default null,                       --当月変動データ金額
      変動データ金額_pre number(9,0) default null,                       --前月変動データ金額
      変動データ金額_diff number(9,0) default null                       --差分
  );
  
  --「変動データ金額Rec」型データ格納配列 （※親番変動コード & 枝番変動コード　をキーにする）
  type 変動データ金額ArrType is table of 変動データ金額Rec index by varchar2(10);

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
      ierrorMsg2        in varchar2);
  
  /**
  * 「C0930前月当月比較エラー」テーブルから指定エラー内容をクリアする
  */
  procedure clearError(
      iプログラムID     in varchar2,
      i会社コード       in varchar2);
      
  /**
  * CSVデータ格納テーブル「C0930前月当月給与支給額比較」の該当データをクリアする
  *
  * 引数
  *     i会社コード
  *     i給与支払年月_cur：給与支払年月(当月)
  */
  procedure csvDataClear(
      i会社コード       in varchar2,
      i給与支払年月_cur in number);
  
  /**
  * 「給与明細漢字データ項目」から所属名を取得する
  *
  * 引数
  *     i会社コード
  *     i給与支払年月：取得したいデータの給与支払年月
  *     i社員番号
  * 戻り値
  *     retCd_OK：取得済み
  *     retCd_NG：データ無し
  */
  function get所属名(
      i会社コード   in varchar2,
      i給与支払年月 in number,
      i社員番号     in number,
      o所属名       out 給与明細漢字データ項目.所属名%type,
      oErrMsg       out varchar2
  ) return number;
  
  /**
  * 「給与明細マスタ項目3」から通称氏名、通称氏名カナ、戸籍氏名を取得
  *
  * 引数
  *     i会社コード
  *     i給与支払年月：取得したいデータの給与支払年月
  *     i社員番号
  * 戻り値
  *     retCd_OK：取得済み
  *     retCd_NG：データ無し
  */
  function get給与明細マスタ項目3Data(
      i会社コード   in varchar2,
      i給与支払年月 in number,
      i社員番号     in number,
      o通称氏名     out 給与明細マスタ項目3.通称氏名%type,
      o通称氏名カナ out 給与明細マスタ項目3.通称氏名カナ%type,
      o戸籍氏名     out 給与明細マスタ項目3.戸籍氏名%type,
      oErrMsg       out varchar2
  ) return number;
  
  /**
  * 「給与明細付録項目」からデータ取得
  *
  * 戻り値
  *     retCd_OK：取得済み
  *     retCd_NG：データ無し
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
  ) return number;
  
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
  return number;
  
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
  *     retCd_NG：例外発生
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
  return number;
  
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
  return number;
  
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
  return number;
  
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
  return number;
  
END KP930当月前月比較PKG;