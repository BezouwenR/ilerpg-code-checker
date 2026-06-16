      *===============================================================
      * SAMPLE01 - サンプルモジュール
      * Version: 1.0.0
      * 静的解析ツール回帰テスト用の中立的なサンプルモジュール。
      *===============================================================
     H NOMAIN
      /COPY QSYSINC/QRPGLESRC,SYSTYPES
      /COPY QSYSINC/QRPGLESRC,FCNTL

      *-------------------------------------------------------------
      * 外部API - 文字コード変換（VALUE/CONST/ポインタ引数の例）
      *-------------------------------------------------------------
     D QtqIconvOpen    PR            52A                                        変換Open
     D                                     EXTPROC('QtqIconvOpen')
     D   toCode                      32A   CONST                                変換先定義
     D   fromCode                    32A   CONST                                変換元定義
     D iconv           PR            10U 0                                      データ処理
     D                                     EXTPROC('iconv')
     D   cd                          52A   VALUE                                記述子
     D   inBuf                         *                                        入力ptr
     D   inLeft                      10U 0                                      入力残数
     D   outBuf                        *                                        出力ptr
     D   outLeft                     10U 0                                      出力残数

      *-------------------------------------------------------------
      * 外部プロシージャ宣言 - EXTPROC(*CL:)/名前継続行の例
      *-------------------------------------------------------------
     D extProcA        PR              *   EXTPROC(*CL:'extProcA')              項目取得
     D   inPath                     256A   CONST VARYING                        入力パス
     D   inIndex                     10I 0 VALUE OPTIONS(*NOPASS)               添字
     D extProcLongName...                                                       項目変換
     D                 PR            10I 0 EXTPROC(*CL:'extProcLongName')
     D   inData                        *   CONST                                データptr
     D   inValue                     10U 0 CONST                                値
     D extProcB        PR            10I 0 EXTPROC(*CL:                         項目集計
     D                                     'extProcB')
     D   inData                        *   CONST                                データptr
     D   inId                        10I 0 CONST                                識別子
     D   outArr                        *   CONST                                出力配列
     D   maxItems                    10I 0 CONST                                最大数
     D extProcC        PR            10I 0 EXTPROC(*CL:'extProcC')              項目幅取得
     D   inData                        *   CONST                                データptr
     D   inId                        10I 0 CONST                                識別子
     D extProcD        PR              *   EXTPROC(*CL:'extProcD')              テーブル取得
     D   inData                        *   CONST                                データptr
     D   tag                          4A   CONST                                タグ4B
      *-------------------------------------------------------------
      * 外部プロシージャ宣言 - 単一CONST引数のゲッター群（戻り型違い）
      *-------------------------------------------------------------
     D getUnit         PR            10I 0 EXTPROC(*CL:'getUnit')               単位取得
     D   inData                        *   CONST                                データptr
     D getAttrA        PR            10I 0 EXTPROC(*CL:'getAttrA')              属性A取得
     D   inData                        *   CONST                                データptr
     D getAttrB        PR            10I 0 EXTPROC(*CL:'getAttrB')              属性B取得
     D   inData                        *   CONST                                データptr
     D getAttrC        PR            10I 0 EXTPROC(*CL:'getAttrC')              属性C取得
     D   inData                        *   CONST                                データptr
     D getName         PR          4096A   VARYING                              名称取得
     D                                     EXTPROC(*CL:'getName')
     D   inArr                         *   CONST                                配列ptr
     D   inCount                     10I 0 CONST                                要素数
     D getPos          PR            10U 0 EXTPROC(*CL:'getPos')                位置取得
     D   inStr                      256A   CONST VARYING                        入力文字列
     D   pos                         10I 0                                      走査位置
     D toHex4          PR             4A   EXTPROC(*CL:'toHex4')                4桁16進変換
     D   val                         10U 0 CONST                                変換元数値

      *-------------------------------------------------------------
      * 外部プロシージャ宣言 - 大文字EXTPROC/DIM(n) CONST配列引数の例
      *-------------------------------------------------------------
     D extProcE        PR            10I 0                                      項目処理
     D                                     EXTPROC('EXTPROCE')
     D inArr                         10U 0 DIM(4096) CONST                      入力配列
     D inCount                       10I 0 CONST                                入力数
     D outArr                        10U 0 DIM(4096)                            出力配列
     D maxOut                        10I 0 CONST                                出力最大数

      *-------------------------------------------------------------
      * 内部プロシージャ宣言
      *-------------------------------------------------------------
     D PROC06          PR            10I 0                                      データ処理
     D   inStr                      256A   CONST VARYING                        入力文字列
     D   outArr                        *   VALUE                                出力配列ptr
     D PROC07          PR            10I 0                                      文字列書込
     D   fd                          10I 0 CONST                                出力先FD
     D   str                      32767A   CONST VARYING                        書込み文字列
     D PROC08          PR            10I 0                                      Nバイト書込
     D   fd                          10I 0 CONST                                出力先FD
     D   buffer                        *   VALUE                                書込みptr
     D   length                      10U 0 CONST                                書込みバイト数
     D PROC09          PR            12A   VARYING                              整数→文字列
     D   val                         10I 0 CONST                                変換元整数値
     D PROC10          PR            12A   VARYING                              符号なし→文字
     D   val                         10U 0 CONST                                変換元符号なし値

      *-------------------------------------------------------------
      * 公開API プロトタイプ
      *-------------------------------------------------------------
     D PROC01          PR            10I 0 EXTPROC(*CL:'PROC01')                項目登録
     D   inPath                     256A   CONST VARYING                        入力パス
     D   inIndex                     10I 0 VALUE OPTIONS(*NOPASS)               添字
     D PROC02          PR            10I 0 EXTPROC(*CL:'PROC02')                項目追加
     D   width                       10I 0 VALUE OPTIONS(*NOPASS)               幅
     D   height                      10I 0 VALUE OPTIONS(*NOPASS)               高さ
     D PROC03          PR                   EXTPROC(*CL:'PROC03')               データ追加
     D   text                       256A   CONST VARYING                        文字列
     D   x                            7P 2 CONST                                X値
     D   y                            7P 2 CONST                                Y値
     D   dataSize                     5P 2 CONST                                サイズ
     D   itemId                      10I 0 CONST                                識別子
     D PROC05          PR            10I 0 EXTPROC(*CL:'PROC05')                データ保存
     D   outPath                    256A   CONST VARYING                        出力パス

      *-------------------------------------------------------------
      * 定数
      *-------------------------------------------------------------
     D MAX_ITEMS       C                   CONST(16)                            項目上限
     D MAX_PAGES       C                   CONST(100)                           ページ上限
     D MAX_OPS         C                   CONST(10000)                         操作上限

      *-------------------------------------------------------------
      * データ構造 - QUALIFIED TEMPLATE / 各種データ型の例
      *-------------------------------------------------------------
     D DS01            DS                  QUALIFIED TEMPLATE                   項目情報DS
     D   FLD01                         *                                        データptr
     D   FLD02                      256A   VARYING                              パス
     D   FLD03                       10I 0                                      添字
     D   FLD04                       64A   VARYING                              名称
     D   FLD05                       10I 0 DIM(4096)                            配列1
     D   FLD06                       10U 0 DIM(4096)                            配列2
     D   FLD07                       10I 0                                      件数
     D   FLD08                        1N                                        フラグ
     D DS02            DS                  QUALIFIED TEMPLATE                   操作情報DS
     D   text                       256A   VARYING                              文字列
     D   x                            7P 2                                      X値
     D   y                            7P 2                                      Y値
     D   dataSize                     5P 2                                      サイズ
     D   itemId                      10I 0                                      識別子
     D   pageId                      10I 0                                      ページID
     D DS03            DS                  QUALIFIED TEMPLATE                   ページ情報DS
     D   width                       10I 0                                      幅
     D   height                      10I 0                                      高さ

      *-------------------------------------------------------------
      * モジュールレベル変数 - LIKEDS/DIM/INZ/名前継続DIMの例
      *-------------------------------------------------------------
     D items           DS                  LIKEDS(DS01)                         項目情報配列
     D                                     DIM(16)
     D numItems        S             10I 0 INZ(0)                               登録項目数
     D pages           DS                  LIKEDS(DS03)                         ページ情報配列
     D                                     DIM(100)
     D numPages        S             10I 0 INZ(0)                               現在ページ数
     D ops             DS                  LIKEDS(DS02)                         操作情報配列
     D                                     DIM(10000)
     D numOps          S             10I 0 INZ(0)                               操作数

      *===============================================================
      * PROC01 - 項目登録（OPTIONS(*NOPASS)/%PARMS分岐の例）
      *===============================================================
     P PROC01          B                   EXPORT
     D PROC01          PI            10I 0                                      項目登録
     D   inPath                     256A   CONST VARYING                        入力パス
     D   inIndex                     10I 0 VALUE OPTIONS(*NOPASS)               添字
     D pData           S               *                                        結果ptr
     D idx             S             10I 0                                      配列添字
     D fIdx            S             10I 0                                      内番号
       // (処理省略)
       fIdx = 0;
       IF %PARMS >= 2;
         fIdx = inIndex;
       ENDIF;
       numItems = numItems + 1;
       idx = numItems;
       items(idx).FLD02 = inPath;
       items(idx).FLD03 = fIdx;
       items(idx).FLD08 = '1';
       RETURN idx;
     P                 E

      *===============================================================
      * PROC02 - 項目追加（既定値分岐の例）
      *===============================================================
     P PROC02          B                   EXPORT
     D PROC02          PI            10I 0                                      項目追加
     D   width                       10I 0 VALUE OPTIONS(*NOPASS)               幅
     D   height                      10I 0 VALUE OPTIONS(*NOPASS)               高さ
       // (処理省略)
       numPages = numPages + 1;
       IF %PARMS >= 2;
         pages(numPages).width = width;
         pages(numPages).height = height;
       ELSE;
         pages(numPages).width = 595;
         pages(numPages).height = 842;
       ENDIF;
       RETURN numPages;
     P                 E

      *===============================================================
      * PROC03 - データ追加（局所D仕様・配列宣言の例）
      *===============================================================
     P PROC03          B                   EXPORT
     D PROC03          PI                                                       データ追加
     D   text                       256A   CONST VARYING                        入力文字列
     D   x                            7P 2 CONST                                X値
     D   y                            7P 2 CONST                                Y値
     D   dataSize                     5P 2 CONST                                サイズ
     D   itemId                      10I 0 CONST                                識別子
     D pos             S             10I 0                                      配列位置
     D cp              S             10U 0                                      値
     D tid             S             10I 0                                      項目ID
     D i               S             10I 0                                      ループ添字
     D found           S              1N                                        重複検出
     D cpArr           S             10U 0 DIM(256)                             変換後配列
     D nCPs            S             10I 0                                      数
       // (処理省略)
       numOps = numOps + 1;
       ops(numOps).text = text;
       ops(numOps).x = x;
       ops(numOps).y = y;
       ops(numOps).dataSize = dataSize;
       ops(numOps).itemId = itemId;
       ops(numOps).pageId = numPages;
       IF itemId >= 1 AND itemId <= numItems;
         nCPs = PROC06(text: %ADDR(cpArr));
         FOR pos = 1 TO nCPs;
           cp = cpArr(pos);
           IF cp > 0;
             tid = extProcLongName(items(itemId).FLD01: cp);
             found = '0';
             FOR i = 1 TO items(itemId).FLD07;
               IF items(itemId).FLD05(i) = tid;
                 found = '1';
                 LEAVE;
               ENDIF;
             ENDFOR;
             IF NOT found;
               items(itemId).FLD07 = items(itemId).FLD07 + 1;
               i = items(itemId).FLD07;
               items(itemId).FLD05(i) = tid;
               items(itemId).FLD06(i) = cp;
             ENDIF;
           ENDIF;
         ENDFOR;
       ENDIF;
     P                 E

      *===============================================================
      * PROC05 - データ保存（OVERLAY/BASED/ポインタ操作の例）
      *===============================================================
     P PROC05          B                   EXPORT
     D PROC05          PI            10I 0                                      データ保存
     D   outPath                    256A   CONST VARYING                        出力パス
     D fd              S             10I 0                                      出力FD
     D oflag           S             10I 0                                      フラグ
     D omode           S             10U 0                                      モード
     D buf             S          32767A   VARYING                              出力バッファ
     D rc              S             10I 0                                      戻り値
     D pkDS            DS                                                       バイト変換
     D  pkChar                        1A                                        バイト文字
     D  pkVal                         3U 0 OVERLAY(pkDS:1)                      数値(0-255)
     D pBuf            S               *                                        作業ptr
     D bArr            S              1A   DIM(256)                             バイト配列
     D                                     BASED(pBuf)
     D f               S             10I 0                                      項目添字
     D p               S             10I 0                                      ページ添字
     D t               S             10I 0                                      操作添字
       // (処理省略)
       oflag = 106;
       omode = 420;
       fd = open(%TRIMR(outPath): oflag: omode: 65535);
       IF fd < 0;
         RETURN -1;
       ENDIF;
       buf = 'HDR' + x'0A';
       rc = PROC07(fd: buf);
       pBuf = %ADDR(buf);
       pkVal = 0;
       bArr(1) = pkChar;
       // 各ページの操作を出力（処理本体は省略）
       FOR p = 1 TO numPages;
         buf = 'PAGE ' + %CHAR(p) + x'0A';
         rc = PROC07(fd: buf);
         FOR t = 1 TO numOps;
           IF ops(t).pageId = p;
             buf = ops(t).text + x'0A';
             rc = PROC07(fd: buf);
           ENDIF;
         ENDFOR;
       ENDFOR;
       // 各項目データを開放
       FOR f = 1 TO numItems;
         IF items(f).FLD01 <> *NULL;
           items(f).FLD01 = *NULL;
         ENDIF;
       ENDFOR;
       callp close(fd);
       numItems = 0;
       numPages = 0;
       numOps = 0;
       RETURN 0;
     P                 E

      *===============================================================
      * PROC06 - データ処理（STATIC/INZ(*ALLX)/LIKEDS局所DSの例）
      *===============================================================
     P PROC06          B                   EXPORT
     D PROC06          PI            10I 0                                      データ処理
     D   inStr                      256A   CONST VARYING                        入力文字列
     D   pOutArr                       *   VALUE                                出力配列ptr
     D outArr          S             10U 0 DIM(256)                             出力配列
     D                                     BASED(pOutArr)
     D Code_t          DS                  QUALIFIED                            変換定義
     D   CCSID                       10I 0                                      コードID
     D   convAlt                     10I 0                                      代替1
     D   reserved                    12A                                        予約域
     D fromCode        DS                  LIKEDS(Code_t)                       変換元
     D                                     STATIC INZ
     D iconvCD         S             52A   STATIC                               記述子
     D                                     INZ(*ALLX'00')
     D opened          S              1N   INZ('0') STATIC                      初回判定
     D nChars          S             10I 0                                      変換文字数
     D j               S             10I 0                                      ループ添字
     D pUB             S               *                                        参照ptr
     D ubDS            DS                  BASED(pUB)                           バイト分解
     D  ubH                           3U 0                                      上位バイト
     D  ubL                           3U 0                                      下位バイト
       // (処理省略)
       IF NOT opened;
         fromCode = *ALLX'00';
         fromCode.CCSID = 5035;
         iconvCD = QtqIconvOpen(inStr: inStr);
         opened = '1';
       ENDIF;
       nChars = 0;
       FOR j = 1 TO nChars;
         pUB = %ADDR(iconvCD) + (j - 1) * 2;
         outArr(j) = ubH * 256 + ubL;
       ENDFOR;
       RETURN nChars;
     P                 E

      *===============================================================
      * PROC07 - 文字列書込（EXPORT無し内部・STATIC配列の例）
      *===============================================================
     P PROC07          B
     D PROC07          PI            10I 0                                      文字列書込
     D   fd                          10I 0 CONST                                出力先FD
     D   str                      32767A   CONST VARYING                        書込み文字列
     D rc              S             10I 0                                      戻り値
     D len             S             10U 0                                      文字列長
     D tmpBuf          S          32767A                                        変換作業域
     D pBuf            S               *                                        作業ptr
     D tbl             S              3U 0 DIM(256) STATIC                      変換表
     D i               S             10I 0                                      ループ添字
     D inited          S              1N   INZ('0') STATIC                      初回判定
       // (処理省略)
       IF NOT inited;
         FOR i = 1 TO 256;
           tbl(i) = 63;
         ENDFOR;
         inited = '1';
       ENDIF;
       len = %LEN(str);
       IF len > 0;
         tmpBuf = str;
         pBuf = %ADDR(tmpBuf);
         rc = write(fd: pBuf: len);
         RETURN rc;
       ENDIF;
       RETURN 0;
     P                 E

      * PROC08 - Nバイト書込（変換なし）
     P PROC08          B
     D PROC08          PI            10I 0                                      Nバイト書込
     D   fd                          10I 0 CONST                                出力先FD
     D   buffer                        *   VALUE                                書込みptr
     D   length                      10U 0 CONST                                書込みバイト数
     D rc              S             10I 0                                      戻り値
       // (処理省略)
       rc = write(fd: buffer: length);
       RETURN rc;
     P                 E

     P PROC09          B
     D PROC09          PI            12A   VARYING                              整数→文字列
     D   val                         10I 0 CONST                                変換元整数値
       // (処理省略)
       RETURN %CHAR(val);
     P                 E

     P PROC10          B
     D PROC10          PI            12A   VARYING                              符号なし→文字
     D   val                         10U 0 CONST                                変換元符号なし値
       // (処理省略)
       RETURN %CHAR(val);
     P                 E
