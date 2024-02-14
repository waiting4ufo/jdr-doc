create or replace 
function KP930A07給与支給比較
(
    i会社コード       in varchar2,
    i給与支払年月_cur in number,
    i給与支払年月_pre in number,
    iプログラムID     in varchar2,
    i担当者コード     in number,
    o処理件数         out number,
    o正常件数         out number,
    o異常件数         out number,
    oerrmsg           out varchar2
)
return number
/**
* KP930A07給与支給比較
*
* 引数
*     i会社コード
*     i給与支払年月_cur ：給与支払年月（当月）
*     i給与支払年月_pre ：給与支払年月（前月）
*     iプログラムID
*     i担当者コード
*     o処理件数         ：総処理件数（正常終了時）
*     o正常件数         ：正常処理件数（正常終了時）
*     o異常件数         ：異常処理件数（正常終了時）
*     oerrmsg           ：エラーメッセージ（異常終了時）
*
* 戻り値
*     0 :正常終了（データ無し）
*     1 :正常終了（データあり）
*     -1:異常終了
*/
is

    --戻り値定義
    retCd_NODATA constant number(1,0) := 0;
    retCd_OK     constant number(1,0) := 1;
    retCd_NG     constant number(1,0) := -1;
    
    retCd number := retCd_OK;
    
    致命エラー exception;
    
    --差異表示関連
    diffDisp_NONE constant varchar2(1) := '';
    diffDisp_HAVE constant varchar2(4) := 'あり';
    diffDisp_NOCURYM constant varchar2(8) := '当月なし';
    diffDisp_NOPREYM constant varchar2(8) := '前月なし';
    
    flg_OFF constant number := 0;
    flg_ON constant number := 1;
    
    noCurYMFlg number := flg_ON;  --当月なしフラグ(flg_OFF:当月あり；flg_ON：当月無し)
    noPreYMFlg number := flg_ON;  --前月無しフラグ(flg_OFF:前月あり；flg_ON：前月無し)
    diffFlg number := flg_OFF;    --差異ありフラグ (flg_OFF:差異無し；flg_ON：差異あり)
    
    --一時変数
    tmpNoCurYMFlg number;
    tmpNoPreYMFlg number;
    tmpDiffFlg    number;
    
    --メインカーソル >>>>>>>>>>>>>>>>>>>>
    cursor mainCur(p会社コード varchar2, p給与支払年月_cur number, p給与支払年月_pre number) is
        select  --当月データ
            0 as preOnly,
            a.給与支払年月,
        	a.社員番号,
        	(a.所属1 || a.所属2 || a.所属3 || a.所属4 || a.所属5) as 所属コード,
        	a.氏名,
        	a.給与区分,
        	a.誕生生年月日,
        	a.入社年月日,
        	a.退職年月日,
        	a.休職年月日,
        	a.復職年月日,
        	a.税区分
        from
            給与明細マスタ項目1 a
        where
            a.会社コード = p会社コード
            and a.給与支払年月 = p給与支払年月_cur  --当月
        union all
        select  --先月にのみあるデータ（当月データ無し）
            1 as preOnly,
            b.給与支払年月,
        	b.社員番号,
        	(b.所属1 || b.所属2 || b.所属3 || b.所属4 || b.所属5) as 所属コード,
        	b.氏名,
        	b.給与区分,
        	b.誕生生年月日,
        	b.入社年月日,
        	b.退職年月日,
        	b.休職年月日,
        	b.復職年月日,
        	b.税区分
        from
            給与明細マスタ項目1 b
        where
            b.会社コード = p会社コード
            and b.給与支払年月 = p給与支払年月_pre  --先月
        	and b.社員番号 not in(
           	    select
        		    c.社員番号
        		from
        		    給与明細マスタ項目1 c
        		where
        		    c.会社コード = p会社コード
        			and c.給与支払年月 = p給与支払年月_cur  --当月
        	);
    --<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
    
    --メインカーソル型レコード
    mainCurRec mainCur%rowtype;
    
    --CSVテーブルレコード
    C0930前月当月給与支給額比較Rec C0930前月当月給与支給額比較%rowtype;
    
    --各関数呼び出し結果一時保存用
    tmpRetCd number;
    tmp給与支払年月 number;
    
    --エラー有状態保持
    haveError boolean;
    
    tmpErrMsg1 varchar2(4000);
    tmpErrMsg2 varchar2(4000);
    
    --変動データ金額の差分情報格納
    変動データ金額Arr KP930当月前月比較PKG.変動データ金額ArrType;
    
    --変動データの差分情報update文
    変動データ差分update varchar2(30000) := null;
    
    tmpKey varchar2(10);
    isFirst boolean;
    
    tmpStr varchar2(20);
    
    --test
    idx number(9,0) := 0;
begin
    --初期化処理
    o処理件数 := 0;
    o正常件数 := 0;
    o異常件数 := 0;
    
    oerrmsg := '';
    
    --エラー内容クリア
    KP930当月前月比較PKG.clearError(iプログラムID, i会社コード);
    
    -- 引数チェック
    IF i会社コード IS NULL OR i給与支払年月_cur IS NULL 
       OR i給与支払年月_pre IS NULL OR iプログラムID IS NULL OR i担当者コード IS NULL THEN
       
        oerrmsg := '引数エラーが発生しました。';
        RAISE 致命エラー;
    END IF;
    
    --前回作成したCSVデータをクリアする
    KP930当月前月比較PKG.csvDataClear(i会社コード, i給与支払年月_cur);
    
    open mainCur(i会社コード, i給与支払年月_cur, i給与支払年月_pre);
    loop
        fetch mainCur into mainCurRec;  --新しいレコード取得
        exit when mainCur%notfound;
        
        --総処理件数加算
        o処理件数 := o処理件数 + 1;
        
        --変数初期化
        noCurYMFlg := flg_ON;  --当月無しフラグ←当月無し
        noPreYMFlg := flg_ON;  --前月無しフラグ←前月無し
        diffFlg := flg_OFF;    --差異ありフラグ←差異無し
        
        --初期値：エラー無し
        haveError := false;
        
        if mainCurRec.preOnly = 1 then  --前月のみのデータ
            noPreYMFlg := flg_OFF;  --前月あり
        else
            noCurYMFlg := flg_OFF;  --当月あり
        end if;
        
        C0930前月当月給与支給額比較Rec.会社コード := i会社コード;
        C0930前月当月給与支給額比較Rec.給与支払年月 := i給与支払年月_cur;  --給与支払年月（当月）
        C0930前月当月給与支給額比較Rec.社員番号 := mainCurRec.社員番号;
        C0930前月当月給与支給額比較Rec.所属コード :=  mainCurRec.所属コード;
        C0930前月当月給与支給額比較Rec.氏名 := mainCurRec.氏名;
        C0930前月当月給与支給額比較Rec.給与区分 := mainCurRec.給与区分;
        C0930前月当月給与支給額比較Rec.誕生生年月日 := mainCurRec.誕生生年月日;
        C0930前月当月給与支給額比較Rec.入社年月日 := mainCurRec.入社年月日;
        C0930前月当月給与支給額比較Rec.退職年月日 := mainCurRec.退職年月日;
        C0930前月当月給与支給額比較Rec.休職年月日 := mainCurRec.休職年月日;
        C0930前月当月給与支給額比較Rec.復職年月日 := mainCurRec.復職年月日;
        C0930前月当月給与支給額比較Rec.税区分 := mainCurRec.税区分;
        
        tmp給与支払年月 := i給与支払年月_cur;
        if noCurYMFlg = flg_ON then
            tmp給与支払年月 := i給与支払年月_pre;  --当月データ無し時、前月の部署取得
        end if;
        
        --所属名取得
        tmpRetCd := KP930当月前月比較PKG.get所属名( 
                        i会社コード, 
                        tmp給与支払年月, 
                        C0930前月当月給与支給額比較Rec.社員番号,
                        C0930前月当月給与支給額比較Rec.所属名,
                        tmpErrMsg2);
                        
        --例外発生時、エラー。
        if tmpRetCd = KP930当月前月比較PKG.retCd_NG then
            o異常件数 := o異常件数 + 1;
            
            --エラー出力
            tmpErrMsg1 := 'KP930当月前月比較PKG.get所属名()エラー。戻り値：' || tmpRetCd; 
            KP930当月前月比較PKG.putError(
                iプログラムID, i会社コード, i給与支払年月_cur, i給与支払年月_pre,
                i担当者コード, C0930前月当月給与支給額比較Rec.社員番号,
                tmpErrMsg1,
                tmpErrMsg2);
            
            continue;
        elsif tmpRetCd = KP930当月前月比較PKG.retCd_NoData then  --データ無し。
        
            --警告出力
            tmpErrMsg1 := 'KP930当月前月比較PKG.get所属名() 警告'; 
            KP930当月前月比較PKG.putError(
                iプログラムID, i会社コード, i給与支払年月_cur, i給与支払年月_pre,
                i担当者コード, C0930前月当月給与支給額比較Rec.社員番号,
                tmpErrMsg1,
                tmpErrMsg2);
        end if;
        
        --通称氏名、通称氏名カナ、戸籍氏名取得
        tmpRetCd := KP930当月前月比較PKG.get給与明細マスタ項目3Data(
                        i会社コード, 
                        tmp給与支払年月, 
                        C0930前月当月給与支給額比較Rec.社員番号,
                        C0930前月当月給与支給額比較Rec.通称氏名,
                        C0930前月当月給与支給額比較Rec.通称氏名カナ,
                        C0930前月当月給与支給額比較Rec.戸籍氏名,
                        tmpErrMsg2);
                        
        --例外発生時、エラー。
        if tmpRetCd = KP930当月前月比較PKG.retCd_NG then
            o異常件数 := o異常件数 + 1;
            
            --エラー出力
            tmpErrMsg1 := 'KP930当月前月比較PKG.get給与明細マスタ項目3Data()エラー。戻り値：' || tmpRetCd; 
            KP930当月前月比較PKG.putError(
                iプログラムID, i会社コード, i給与支払年月_cur, i給与支払年月_pre,
                i担当者コード, C0930前月当月給与支給額比較Rec.社員番号,
                tmpErrMsg1,
                tmpErrMsg2);
            
            continue;
        elsif tmpRetCd = KP930当月前月比較PKG.retCd_NoData then  --データ無し。
        
            --警告出力
            tmpErrMsg1 := 'KP930当月前月比較PKG.get給与明細マスタ項目3Data() 警告'; 
            KP930当月前月比較PKG.putError(
                iプログラムID, i会社コード, i給与支払年月_cur, i給与支払年月_pre,
                i担当者コード, C0930前月当月給与支給額比較Rec.社員番号,
                tmpErrMsg1,
                tmpErrMsg2);
        end if;
                        
        --「給与明細付録項目」からデータ取得
        tmpRetCd := KP930当月前月比較PKG.get給与明細付録項目Data(
                        i会社コード, 
                        tmp給与支払年月, 
                        C0930前月当月給与支給額比較Rec.社員番号,
                        C0930前月当月給与支給額比較Rec.基本文字5_5,
                        C0930前月当月給与支給額比較Rec.基本文字5_1,
                        C0930前月当月給与支給額比較Rec.基本文字5_2,
                        C0930前月当月給与支給額比較Rec.入社年月日2,
                        C0930前月当月給与支給額比較Rec.共通文字1_4,
                        C0930前月当月給与支給額比較Rec.共通文字1_5,
                        tmpErrMsg2);
        --例外発生時、エラー。
        if tmpRetCd = KP930当月前月比較PKG.retCd_NG then
            o異常件数 := o異常件数 + 1;
            
            --エラー出力
            tmpErrMsg1 := 'KP930当月前月比較PKG.get給与明細付録項目Data()エラー。戻り値：' || tmpRetCd; 
            KP930当月前月比較PKG.putError(
                iプログラムID, i会社コード, i給与支払年月_cur, i給与支払年月_pre,
                i担当者コード, C0930前月当月給与支給額比較Rec.社員番号,
                tmpErrMsg1,
                tmpErrMsg2);
            
            continue;
        elsif tmpRetCd = KP930当月前月比較PKG.retCd_NoData then  --データ無し。
        
            --警告出力
            tmpErrMsg1 := 'KP930当月前月比較PKG.get給与明細付録項目Data() 警告'; 
            KP930当月前月比較PKG.putError(
                iプログラムID, i会社コード, i給与支払年月_cur, i給与支払年月_pre,
                i担当者コード, C0930前月当月給与支給額比較Rec.社員番号,
                tmpErrMsg1,
                tmpErrMsg2);
        end if;
        
        --年齢計算
        tmpRetCd := KP930当月前月比較PKG.calcAge(
                        to_date(to_char(tmp給与支払年月) || '01', 'YYYYMMDD'),
                        C0930前月当月給与支給額比較Rec.誕生生年月日,
                        tmpErrMsg2
                        );
        --例外発生時、エラー。
        if tmpRetCd = KP930当月前月比較PKG.retCd_NG then
            o異常件数 := o異常件数 + 1;
            
            C0930前月当月給与支給額比較Rec.年齢 := null;
            
            --エラー出力
            tmpErrMsg1 := 'KP930当月前月比較PKG.calcAge()エラー。戻り値：' || tmpRetCd; 
            KP930当月前月比較PKG.putError(
                iプログラムID, i会社コード, i給与支払年月_cur, i給与支払年月_pre,
                i担当者コード, C0930前月当月給与支給額比較Rec.社員番号,
                tmpErrMsg1,
                tmpErrMsg2);
            
            continue;
        else
            C0930前月当月給与支給額比較Rec.年齢 := tmpRetCd;
        end if;
        
        --扶養人数比較
        tmpNoCurYMFlg := 0;
        tmpNoPreYMFlg := 0;
        tmpDiffFlg := 0;
        
        tmpRetCd := KP930当月前月比較PKG.get扶養人数(
                        i会社コード, 
                        i給与支払年月_cur, 
                        i給与支払年月_pre,
                        C0930前月当月給与支給額比較Rec.社員番号,
                        C0930前月当月給与支給額比較Rec.前_扶養人数,
                        C0930前月当月給与支給額比較Rec.扶養人数,
                        C0930前月当月給与支給額比較Rec.差_扶養人数,
                        tmpNoCurYMFlg,
                        tmpNoPreYMFlg,
                        tmpDiffFlg,                        
                        tmpErrMsg2);
        --例外発生時、エラー。
        if tmpRetCd = KP930当月前月比較PKG.retCd_NG then
            o異常件数 := o異常件数 + 1;
            
            --エラー出力
            tmpErrMsg1 := 'KP930当月前月比較PKG.get扶養人数()エラー。戻り値：' || tmpRetCd; 
            KP930当月前月比較PKG.putError(
                iプログラムID, i会社コード, i給与支払年月_cur, i給与支払年月_pre,
                i担当者コード, C0930前月当月給与支給額比較Rec.社員番号,
                tmpErrMsg1,
                tmpErrMsg2);
                
            continue;
        end if;
        
        if tmpNoCurYMFlg = 0 then  --当月あり
            noCurYMFlg := flg_OFF;
        end if;
        if tmpNoPreYMFlg = 0 then  --前月あり
            noPreYMFlg := flg_OFF;
        end if;
        if tmpDiffFlg = 1 then  --差異あり
            diffFlg := flg_ON;
        end if;
        
        --「経理用給与明細親番項目」データ取得
        tmpNoCurYMFlg := 0;
        tmpNoPreYMFlg := 0;
        tmpDiffFlg := 0;
        
        tmpRetCd := KP930当月前月比較PKG.get経理用給与明細親番項目Data(
                        i会社コード, 
                        i給与支払年月_cur, 
                        i給与支払年月_pre,
                        C0930前月当月給与支給額比較Rec.社員番号,
                        C0930前月当月給与支給額比較Rec.税区分,
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
                        tmpNoCurYMFlg,
                        tmpNoPreYMFlg,
                        tmpDiffFlg,                        
                        tmpErrMsg2);
        --例外発生時、エラー。
        if tmpRetCd = KP930当月前月比較PKG.retCd_NG then
            o異常件数 := o異常件数 + 1;
            
            --エラー出力
            tmpErrMsg1 := 'KP930当月前月比較PKG.get経理用給与明細親番項目Data()エラー。戻り値：' || tmpRetCd; 
            KP930当月前月比較PKG.putError(
                iプログラムID, i会社コード, i給与支払年月_cur, i給与支払年月_pre,
                i担当者コード, C0930前月当月給与支給額比較Rec.社員番号,
                tmpErrMsg1,
                tmpErrMsg2);
            
            continue;
        end if;
        
        if tmpNoCurYMFlg = 0 then  --当月あり
            noCurYMFlg := flg_OFF;
        end if;
        if tmpNoPreYMFlg = 0 then  --前月あり
            noPreYMFlg := flg_OFF;
        end if;
        if tmpDiffFlg = 1 then  --差異あり
            diffFlg := flg_ON;
        end if;
        
        --「給与明細変動項目」の差分データを取得
        tmpNoCurYMFlg := 0;
        tmpNoPreYMFlg := 0;
        tmpDiffFlg := 0;
        
        tmpRetCd := KP930当月前月比較PKG.get給与明細変動項目Data(
                        i会社コード, 
                        i給与支払年月_cur, 
                        i給与支払年月_pre,
                        C0930前月当月給与支給額比較Rec.社員番号,
                        変動データ金額Arr,
                        tmpNoCurYMFlg,
                        tmpNoPreYMFlg,
                        tmpDiffFlg,                        
                        tmpErrMsg2);
        --例外発生時、エラー。
        if tmpRetCd = KP930当月前月比較PKG.retCd_NG then
            o異常件数 := o異常件数 + 1;
            
            --エラー出力
            tmpErrMsg1 := ' KP930当月前月比較PKG.get給与明細変動項目Data()エラー。戻り値：' || tmpRetCd; 
            KP930当月前月比較PKG.putError(
                iプログラムID, i会社コード, i給与支払年月_cur, i給与支払年月_pre,
                i担当者コード, C0930前月当月給与支給額比較Rec.社員番号,
                tmpErrMsg1,
                tmpErrMsg2);
            
            continue;
        end if;
        
        if tmpNoCurYMFlg = 0 then  --当月あり
            noCurYMFlg := flg_OFF;
        end if;
        if tmpNoPreYMFlg = 0 then  --前月あり
            noPreYMFlg := flg_OFF;
        end if;
        if tmpDiffFlg = 1 then  --差異あり
            diffFlg := flg_ON;
        end if;
        
        --insertデータ編集
        if noCurYMFlg = flg_ON then  --当月無し
            C0930前月当月給与支給額比較Rec.差異 := diffDisp_NOCURYM;
        elsif noPreYMFlg = flg_ON then  --前月無し
            C0930前月当月給与支給額比較Rec.差異 := diffDisp_NOPREYM;
        elsif diffFlg = flg_ON then  --差異あり
            C0930前月当月給与支給額比較Rec.差異 := diffDisp_HAVE;
        end if;
        
        C0930前月当月給与支給額比較Rec.登録者 := i担当者コード;
        
        isFirst := true;
        変動データ差分update := null;
        
        --insert処理
        tmpRetCd := KP930当月前月比較PKG.C0930給与支給額比較登録(
                                             i会社コード, 
                                             i給与支払年月_cur, 
                                             i給与支払年月_pre,
                                             C0930前月当月給与支給額比較Rec, 
                                             tmpErrMsg2);
        --例外発生時、エラー。
        if tmpRetCd = KP930当月前月比較PKG.retCd_NG then
            o異常件数 := o異常件数 + 1;

            --エラー出力
            tmpErrMsg1 := ' KP930当月前月比較PKG.C0930給与支給額比較登録()エラー。戻り値：' || tmpRetCd; 
            KP930当月前月比較PKG.putError(
                iプログラムID, i会社コード, i給与支払年月_cur, i給与支払年月_pre,
                i担当者コード, C0930前月当月給与支給額比較Rec.社員番号,
                tmpErrMsg1,
                tmpErrMsg2);
            
            continue;
        else  --データ登録OK
        -->>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>
            --update文準備(「変動xxxx」項目更新処理）
            if 変動データ金額Arr.count > 0 then
                変動データ差分update := 'update C0930前月当月給与支給額比較 set ';
            
                tmpKey := 変動データ金額Arr.first;
                loop
                
                    if isFirst = false then
                        変動データ差分update := 変動データ差分update || ',';
                    end if;
                    
                    isFirst := false;

                    tmpStr := 変動データ金額Arr(tmpKey).枝番変動コード;
                    
                    if 変動データ金額Arr(tmpKey).変動データ金額_pre is null then
                        変動データ差分update := 変動データ差分update 
                                                || ' 前_変動' || tmpStr || ' = null ';
                    else
                        変動データ差分update := 変動データ差分update 
                                                || ' 前_変動' || tmpStr || ' = ' 
                                                || 変動データ金額Arr(tmpKey).変動データ金額_pre;
                    end if;
                    
                    if 変動データ金額Arr(tmpKey).変動データ金額_cur is null then
                        変動データ差分update := 変動データ差分update 
                                                || ', 変動' || tmpStr || ' = null ';
                    else
                        変動データ差分update := 変動データ差分update 
                                                || ', 変動' || tmpStr || ' = ' 
                                                || 変動データ金額Arr(tmpKey).変動データ金額_cur;
                    end if;
                    
                    if 変動データ金額Arr(tmpKey).変動データ金額_diff is null then
                        変動データ差分update := 変動データ差分update 
                                                || ', 差_変動' || tmpStr || ' = null ';
                    else
                        変動データ差分update := 変動データ差分update 
                                                || ', 差_変動' || tmpStr || ' = ' 
                                                || 変動データ金額Arr(tmpKey).変動データ金額_diff;
                    end if;

                    --DBMS_OUTPUT.PUT_LINE('変動データ差分update->' || 変動データ差分update);
                    
                    --execute IMMEDIATE 変動データ差分update;
                    
                    exit when tmpKey = 変動データ金額Arr.last;
                    tmpKey := 変動データ金額Arr.next(tmpKey);
                end loop;
            
                --/*
                変動データ差分update := 変動データ差分update 
                                        || ', 更新日時 = sysdate, 更新者 = ' || i担当者コード
                                        || ' where 会社コード=' || i会社コード
                                        || '       and 給与支払年月=' || i給与支払年月_cur
                                        || '       and 社員番号=' || C0930前月当月給与支給額比較Rec.社員番号;
                --*/
            end if;
        
        
        --<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<<
            --DBMS_OUTPUT.PUT_LINE('変動データ差分update->' || 変動データ差分update);
            
            --update実行
            idx := idx + 1;
            
            --test
            /*
            if C0930前月当月給与支給額比較Rec.社員番号 = 47803625 then
                DBMS_OUTPUT.PUT_LINE('変動データ差分update->' || 変動データ差分update);
            end if;
            */
                    
            --更新
            --/*
            if 変動データ差分update is not null then
                execute IMMEDIATE 変動データ差分update;
            end if;
            --*/
        end if;
        
    end loop;
    close mainCur;
    
    commit;

    --正常件数計算
    o正常件数 := o処理件数 - o異常件数;

    if o処理件数 = 0 then  --処理件数0件(処理データ無し。空振り）
        retCd := retCd_NODATA;
    end if;
    
    return retCd;
exception
    when 致命エラー then
        return retCd_NG;
    when others then  --システムエラー
            
        oerrmsg := '例外発生。[C0930前月当月比較エラー]参照。 idx=' || idx
                   || ' SQLCODE=[' || SQLCODE || '] '
                   || ' SQLERRM=[' || sqlerrm(SQLCODE) || ']';
            
        return retCd_NG;
end KP930A07給与支給比較;
/