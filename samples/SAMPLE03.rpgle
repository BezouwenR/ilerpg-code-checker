      *===============================================================
      * SAMPLE03 - サンプルモジュール
      * 固定形式ILE-RPGの桁位置チェック用サンプル。
      * 各種D仕様・F仕様・プロシージャ形式を最低1例ずつ含む。
      *===============================================================
     H NOMAIN
      /COPY QSYSINC/QRPGLESRC,SYSTYPES
      /COPY QSYSINC/QRPGLESRC,FCNTL

      *-------------------------------------------------------------
      * F仕様 - ファイル宣言（外部記述）
      *-------------------------------------------------------------
     FSAMPLEFILEIF   E             DISK    USROPN

      *-------------------------------------------------------------
      * 内部プロシージャ宣言
      *-------------------------------------------------------------
     D PROC01          PR             5U 0                                      内部処理1
     D   fd                          10I 0 CONST                                記述子
     D PROC02          PR            10I 0                                      内部処理2
     D   fd                          10I 0 CONST                                記述子
     D   buffer                        *   VALUE                                バッファ
     D   length                      10U 0 CONST                                バイト長
     D PROC03          PR              *                                        内部処理3
     D   fd                          10I 0 CONST                                記述子
     D   tblOffset                   10U 0 CONST                                開始位置
     D   tblLength                   10U 0 CONST                                バイト長
     D PROC04          PR             5I 0                                      内部処理4
     D   ptr                           *   CONST                                読取ptr
     D PROC05          PR            10U 0                                      内部処理5
     D   ptr                           *   CONST                                読取ptr
     D PROC20          PR                                                       内部処理20
     D   ds01p                         *   CONST                                構造体ptr

      *-------------------------------------------------------------
      * 公開プロシージャ宣言
      *-------------------------------------------------------------
     D PROC10          PR              *   EXTPROC(*CL:'PROC10')                公開処理10
     D   inPath                     256A   CONST VARYING                        入力パス
     D   inIndex                     10I 0 VALUE OPTIONS(*NOPASS)               任意番号
     D PROC11          PR            10I 0 EXTPROC(*CL:'PROC11')                公開処理11
     D   ds01p                         *   CONST                                構造体ptr
     D   tag                          4A   CONST                                タグ4B
      * 名前継続行（...）の例
     D PROC12...                                                                公開処理12
     D                 PR            10I 0 EXTPROC(*CL:'PROC12')
     D   ds01p                         *   CONST                                構造体ptr
     D   codepoint                   10U 0 CONST                                値
     D PROC13          PR                  EXTPROC(*CL:'PROC13')                公開処理13
     D   ds01p                         *                                        構造体ptr
      * EXTPROC名の継続行の例
     D PROC14          PR            10I 0 EXTPROC(*CL:                         公開処理14
     D                                     'PROC14')
     D   ds01p                         *   CONST                                構造体ptr
     D   paramId                     10I 0 CONST                                対象ID
     D   outArr1                       *   CONST                                出力配列1
     D   outArr2                       *   CONST                                出力配列2
     D   maxItems                    10I 0 CONST                                最大数

      *-------------------------------------------------------------
      * DS01 - 情報構造体（QUALIFIED TEMPLATE）
      *-------------------------------------------------------------
     D DS01            DS                  QUALIFIED TEMPLATE                   情報構造体
     D   signature                   10U 0                                      署名
     D   numTables                   10I 0                                      項目数
     D   entrySelector...                                                       選択子
     D                               10I 0
     D   tables                        *                                        配列ptr
     D   fileDescriptor...                                                      記述子
     D                               10I 0
     D   fldValue02                  10I 0                                      単位数
     D   extrData                      *                                        データptr
     D   extrLength                  10U 0                                      バイト長

      * DS02 - レコード（QUALIFIED TEMPLATE）
     D DS02            DS                  QUALIFIED TEMPLATE                   レコード
     D   tag                          4A                                        タグ4B
     D   checksum                    10U 0                                      検査値
     D   offset                      10U 0                                      位置
     D   length                      10U 0                                      バイト長
     D   data                          *                                        データptr

      * 定数宣言（C CONST）の例
     D CONST_A         C                   CONST(65536)                         定数A
     D CONST_B         C                   CONST(1330926671)                    定数B

      *===============================================================
      * PROC10 - 入力を開いて初期化し、DS01ポインタを返す
      *===============================================================
     P PROC10          B                   EXPORT
     D PROC10          PI              *                                        公開処理10
     D   inPath                     256A   CONST VARYING                        入力パス
     D   inIndex                     10I 0 VALUE OPTIONS(*NOPASS)               任意番号
     D ds01            DS                  LIKEDS(DS01)                         情報DS
     D                                     BASED(pDs01)
     D pDs01           S               *                                        構造体ポインタ
     D fd              S             10I 0                                      記述子
     D sig             S             10U 0                                      署名
     D numTbl          S             10I 0                                      項目数
     D i               S             10I 0                                      ループ索引
     D pTR             S               *                                        レコードptr
     D tr              DS                  LIKEDS(DS02)                         レコード1件
     D                                     BASED(pTR)
     D idxVal          S             10I 0                                      選択番号
     D oflag           S             10I 0                                      フラグ
       // (処理省略)
       oflag = 1;
       fd = open(%TRIMR(inPath): oflag);
       IF fd < 0;
         RETURN *NULL;
       ENDIF;
       idxVal = 0;
       IF %PARMS >= 2;
         idxVal = inIndex;
       ENDIF;
       sig = PROC01(fd);
       pDs01 = %ALLOC(%SIZE(DS01));
       ds01.fileDescriptor = fd;
       ds01.signature = sig;
       ds01.extrData = *NULL;
       ds01.extrLength = 0;
       numTbl = PROC01(fd);
       ds01.numTables = numTbl;
       ds01.tables = %ALLOC(numTbl * %SIZE(DS02));
       FOR i = 1 TO numTbl;
         pTR = ds01.tables + (i-1) * %SIZE(DS02);
         PROC02(fd: %ADDR(tr.tag): 4);
         tr.offset = PROC01(fd);
         tr.length = PROC01(fd);
         tr.data = *NULL;
       ENDFOR;
       RETURN pDs01;
     P                 E

      *===============================================================
      * PROC11 - 指定タグの項目を取得（遅延ロード方式）
      *===============================================================
     P PROC11          B                   EXPORT
     D PROC11          PI            10I 0                                      公開処理11
     D   ds01p                         *   CONST                                構造体ptr
     D   tag                          4A   CONST                                タグ4B
     D info            DS                  LIKEDS(DS01)                         情報参照
     D                                     BASED(ds01p)
     D i               S             10I 0                                      ループ索引
     D pTR             S               *                                        レコードptr
     D tr              DS                  LIKEDS(DS02)                         走査中レコード
     D                                     BASED(pTR)
       // (処理省略)
       FOR i = 1 TO info.numTables;
         pTR = info.tables + (i-1) * %SIZE(DS02);
         IF tr.tag = tag;
           RETURN tr.offset;
         ENDIF;
       ENDFOR;
       RETURN 0;
     P                 E

      *===============================================================
      * PROC12 - 値変換（名前継続行 ... を持つ実装）
      *===============================================================
     P PROC12...
     P                 B                   EXPORT
     D PROC12...                                                                公開処理12
     D                 PI            10I 0
     D   ds01p                         *   CONST                                構造体ptr
     D   codepoint                   10U 0 CONST                                値
     D info            DS                  LIKEDS(DS01)                         情報参照
     D                                     BASED(ds01p)
     D cPtr            S               *                                        データPtr
     D fmt             S              5U 0                                      フォーマット
     D gId             S             10I 0                                      算出ID
       // (処理省略)
       IF info.extrData = *NULL;
         RETURN 0;
       ENDIF;
       cPtr = info.extrData;
       fmt = PROC01(cPtr);
       gId = 0;
       RETURN gId;
     P                 E

      *===============================================================
      * PROC13 - 解放（FD閉じ、メモリ解放）
      *===============================================================
     P PROC13          B                   EXPORT
     D PROC13          PI                                                       公開処理13
     D   ds01p                         *                                        構造体ptr
     D info            DS                  LIKEDS(DS01)                         情報参照
     D                                     BASED(ds01p)
     D i               S             10I 0                                      ループ索引
     D pTR             S               *                                        レコードptr
     D tr              DS                  LIKEDS(DS02)                         走査中レコード
     D                                     BASED(pTR)
       // (処理省略)
       IF ds01p = *NULL;
         RETURN;
       ENDIF;
       FOR i = 1 TO info.numTables;
         pTR = info.tables + (i-1) * %SIZE(DS02);
         IF tr.data <> *NULL;
           DEALLOC tr.data;
         ENDIF;
       ENDFOR;
       IF info.tables <> *NULL;
         DEALLOC info.tables;
       ENDIF;
       callp close(info.fileDescriptor);
       DEALLOC ds01p;
       ds01p = *NULL;
     P                 E

      *===============================================================
      * PROC14 - レイヤー取得（OVERLAY/DIM/BASED配列の例）
      *===============================================================
     P PROC14          B                   EXPORT
     D PROC14          PI            10I 0                                      公開処理14
     D   ds01p                         *   CONST                                構造体ptr
     D   paramId                     10I 0 CONST                                対象ID
     D   outArr1                       *   CONST                                出力配列1
     D   outArr2                       *   CONST                                出力配列2
     D   maxItems                    10I 0 CONST                                最大数
     D info            DS                  LIKEDS(DS01)                         情報参照
     D                                     BASED(ds01p)
     D i               S             10I 0                                      ループ索引
     D pClr            S               *                                        色データPtr
     D cBytes          S              1A   DIM(4) BASED(pClr)                   各1byte
     D byteDS          DS                                                       変換用DS
     D  byteChar                      1A                                        1バイト文字
     D  byteVal                       3U 0 OVERLAY(byteDS:1)                    バイト数値
     D outG            S             10I 0 DIM(256)                             出力配列1
     D                                     BASED(outArr1)
     D outC            S             10U 0 DIM(256)                             出力配列2
     D                                     BASED(outArr2)
     D nOut            S             10I 0                                      出力数
       // (処理省略)
       nOut = 0;
       FOR i = 1 TO info.numTables;
         IF nOut > maxItems;
           LEAVE;
         ENDIF;
         byteVal = 0;
         byteChar = cBytes(1);
         outG(i) = byteVal;
         outC(i) = byteVal;
       ENDFOR;
       RETURN nOut;
     P                 E

      *-------------------------------------------------------------
      * 内部プロシージャ実装（NOMAIN内・EXPORTなし）
      *-------------------------------------------------------------
     P PROC01          B
     D PROC01          PI             5U 0                                      内部処理1
     D   fd                          10I 0 CONST                                記述子
     D buf             S              2A                                        読取バッファ
     D byteDS          DS                                                       変換用DS
     D  byteChar                      1A                                        1バイト文字
     D  byteVal                       3U 0 OVERLAY(byteDS:1)                    バイト数値
     D b1              S              3U 0                                      上位バイト値
     D b2              S              3U 0                                      下位バイト値
       // (処理省略)
       PROC02(fd: %ADDR(buf): 2);
       byteVal = 0;
       byteChar = %SUBST(buf:1:1);
       b1 = byteVal;
       byteVal = 0;
       byteChar = %SUBST(buf:2:1);
       b2 = byteVal;
       RETURN b1 * 256 + b2;
     P                 E

     P PROC02          B
     D PROC02          PI            10I 0                                      内部処理2
     D   fd                          10I 0 CONST                                記述子
     D   buffer                        *   VALUE                                バッファptr
     D   length                      10U 0 CONST                                バイト数
     D rc              S             10I 0                                      戻り値
       // (処理省略)
       rc = read(fd: buffer: length);
       RETURN rc;
     P                 E

     P PROC03          B
     D PROC03          PI              *                                        内部処理3
     D   fd                          10I 0 CONST                                記述子
     D   tblOffset                   10U 0 CONST                                開始位置
     D   tblLength                   10U 0 CONST                                バイト長
     D pData           S               *                                        確保メモリPtr
       // (処理省略)
       IF tblLength = 0 OR tblLength > 16000000;
         RETURN *NULL;
       ENDIF;
       pData = %ALLOC(tblLength);
       callp lseek(fd: tblOffset: 0);
       PROC02(fd: pData: tblLength);
       RETURN pData;
     P                 E

      * PROC04 - 符号付き変換（符号なし中間値→2の補数）
     P PROC04          B
     D PROC04          PI             5I 0                                      内部処理4
     D   ptr                           *   CONST                                読取ptr
     D uval            S              5U 0                                      符号なし中間値
     D ival            S             10I 0                                      符号付き結果値
       // (処理省略)
       uval = PROC05(ptr);
       ival = uval;
       IF ival >= 32768;
         ival = ival - 65536;
       ENDIF;
       RETURN ival;
     P                 E

      * PROC05 - メモリ上のバイト配列を数値化（DIM/BASED配列）
     P PROC05          B
     D PROC05          PI            10U 0                                      内部処理5
     D   ptr                           *   CONST                                読取ptr
     D bA              S              1A   DIM(4) BASED(ptr)                    バイト配列参照
     D byteDS          DS                                                       変換用DS
     D  byteChar                      1A                                        1バイト文字
     D  byteVal                       3U 0 OVERLAY(byteDS:1)                    バイト数値
     D b1              S             10U 0                                      第1バイト値
     D b2              S             10U 0                                      第2バイト値
       // (処理省略)
       byteVal = 0;
       byteChar = bA(1);
       b1 = byteVal;
       byteVal = 0;
       byteChar = bA(2);
       b2 = byteVal;
       RETURN b1 * 256 + b2;
     P                 E

      * PROC20 - 解析してDS01へ既定値を格納（ELSE分岐の例）
     P PROC20          B
     D PROC20          PI                                                       内部処理20
     D   ds01p                         *   CONST                                構造体ptr
     D info            DS                  LIKEDS(DS01)                         情報参照
     D                                     BASED(ds01p)
     D p               S               *                                        データPtr
       // (処理省略)
       p = PROC03(info.fileDescriptor: 0: 16);
       IF p <> *NULL;
         info.fldValue02 = PROC05(p);
       ELSE;
         info.fldValue02 = 1000;
       ENDIF;
     P                 E
