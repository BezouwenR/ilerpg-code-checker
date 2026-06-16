      *===============================================================
      * SAMPLE04 - サンプルモジュール
      * 固定形式ILE-RPGの構文多様性を確認するための検査用サンプル。
      *===============================================================
     H NOMAIN
      /COPY QSYSINC/QRPGLESRC,SYSTYPES
      /COPY QSYSINC/QRPGLESRC,SYSSTAT
      /COPY QSYSINC/QRPGLESRC,FCNTL
      /COPY QSYSINC/QRPGLESRC,UNISTD

      *-------------------------------------------------------------
      * 内部プロシージャ宣言 - 書き込みユーティリティ
      *-------------------------------------------------------------
     D writeU16BE      PR                                                       BE16bit書込
     D   fd                          10I 0 CONST                                出力先FD
     D   val                          5U 0 CONST                                書込み値
     D writeU32BE      PR                                                       BE32bit書込
     D   fd                          10I 0 CONST                                出力先FD
     D   val                         10U 0 CONST                                書込み値
     D writeN          PR            10I 0                                      Nバイト書込
     D   fd                          10I 0 CONST                                出力先FD
     D   buffer                        *   VALUE                                書込みバッファ
     D   length                      10U 0 CONST                                書込みバイト数
     D padTo4          PR                                                       4byte境界パッド
     D   fd                          10I 0 CONST                                出力先FD
     D   length                      10U 0 CONST                                元データ長

      *-------------------------------------------------------------
      * 検査値アキュムレーター宣言
      *-------------------------------------------------------------
     D csInit          PR                                                       CS初期化
     D csAddBytes      PR                                                       CSに加算
     D   dataPtr                       *   CONST                                入力データptr
     D   dataLen                     10U 0 CONST                                入力バイト数
     D csFlush         PR                                                       CS確定
     D csGet           PR            10U 0                                      CS取得

      *-------------------------------------------------------------
      * 外部プロシージャ宣言
      *-------------------------------------------------------------
     D getItem         PR              *   EXTPROC(*CL:'getItem')               項目取得
     D   src                           *   CONST                                入力データptr
     D   tag                          4A   CONST                                識別タグ4B
     D getItemOff      PR            10U 0 EXTPROC(*CL:'getItemOff')            項目位置取得
     D   src                           *   CONST                                入力データptr
     D   tag                          4A   CONST                                識別タグ4B
     D getItemLen      PR            10U 0 EXTPROC(*CL:'getItemLen')            項目長取得
     D   src                           *   CONST                                入力データptr
     D   tag                          4A   CONST                                識別タグ4B
     D getSrcFd        PR            10I 0 EXTPROC(*CL:'getSrcFd')              入力FD取得
     D   src                           *   CONST                                入力データptr
     D getItemCount...                                                          項目数取得
     D                 PR            10I 0 EXTPROC(*CL:'getItemCount')
     D   src                           *   CONST                                入力データptr
     D getUnitSize     PR            10I 0 EXTPROC(*CL:'getUnitSize')           単位サイズ取得
     D   src                           *   CONST                                入力データptr

      *-------------------------------------------------------------
      * 公開プロシージャ宣言
      *   src: 入力データ  ids: 対象ID配列  outPath: 出力先パス
      *   戻り値: 出力バイト数（エラー時負数）
      *-------------------------------------------------------------
     D PROC01          PR            10I 0 EXTPROC(*CL:'PROC01')                データ処理
     D   src                           *   CONST                                入力データptr
     D   ids                           *   CONST                                ID配列ptr
     D   numIds                      10I 0 CONST                                ID数
     D   outPath                    256A   CONST VARYING                        出力パス

     D readU16Buf      PR             5U 0                                      メモリBE16読取
     D   ptr                           *   CONST                                メモリ読取ptr
     D readU32Buf      PR            10U 0                                      メモリBE32読取
     D   ptr                           *   CONST                                メモリ読取ptr
     D writeU16Buf     PR                                                       メモリBE16書込
     D   ptr                           *   CONST                                書込み先ptr
     D   val                          5U 0 CONST                                書込み値

     D DS01            DS                  QUALIFIED TEMPLATE                   情報構造体
     D   signature                   10U 0                                      署名
     D   numItems                    10I 0                                      項目数
     D   searchRange                 10I 0                                      検索範囲
     D   entrySelector...                                                       エントリ選択子
     D                               10I 0
     D   rangeShift                  10I 0                                      範囲シフト
     D   items                         *                                        項目配列ptr
     D   fileDescriptor...                                                      ファイル記述子
     D                               10I 0
     D   unitCount                   10I 0                                      単位数
     D   itemCount                   10I 0                                      総項目数
     D   metricCount                 10I 0                                      メトリクス数
     D   indexFmt                    10I 0                                      索引形式(0/1)
     D   auxData                       *                                        補助データptr
     D   auxLength                   10U 0                                      補助バイト長

     D Rec01           DS                  QUALIFIED TEMPLATE                   レコード
     D   tag                          4A                                        識別タグ4B
     D   checksum                    10U 0                                      検査値
     D   offset                      10U 0                                      位置
     D   length                      10U 0                                      バイト長
     D   data                          *                                        データptr

      *-------------------------------------------------------------
      * 状態変数
      *  csActive/csSum: 検査値（各ブロック書き込み前にcsInit）
      *  4バイトバッファで端数を保持し、flushで確定する
      *-------------------------------------------------------------
     D csActive        S              1N   INZ(*OFF)                            CS有効フラグ
     D csSum           S             20U 0                                      CS累積値
     D csBufArr        S              1A   DIM(4)                               CS端数バッファ
     D csPos           S             10I 0 INZ(0)                               CS端数位置

      *===============================================================
      * PROC01 - データ処理
      *
      * 処理ステップ:
      *   1. 入力ID配列を作業配列に複写
      *   2. 旧ID→新IDの変換表を構築
      *   3. ヘッダー（目録）を書き出し
      *   4. 各ブロックを書き出し（検査値計算付き）
      *   5. 目録の検査値を上書き
      * （アルゴリズム本体は省略）
      *===============================================================
     P PROC01          B                    EXPORT
     D PROC01          PI            10I 0                                      データ処理
     D   src                           *   CONST                                入力データptr
     D   ids                           *   CONST                                ID配列ptr
     D   numIds                      10I 0 CONST                                ID数
     D   outPath                    256A   CONST VARYING                        出力パス

     D rec             DS                  LIKEDS(DS01)                         構造体参照
     D                                     BASED(src)
     D fd              S             10I 0                                      出力FD
     D oflag           S             10I 0                                      open()フラグ
     D omode           S             10U 0                                      open()許可
     D inArr           S             10I 0 DIM(65536)                           入力ID配列
     D                                     BASED(ids)
     D allId           S             10I 0 DIM(65536)                           作業ID配列
     D allCount        S             10I 0                                      作業ID数
     D idMap           S             10I 0 DIM(65536)                           旧→新ID変換表
     D itemPtr         S               *                                        項目先頭
     D auxPtr          S               *                                        補助項目先頭
     D auxLen          S             10U 0                                      補助項目長
     D srcFd           S             10I 0                                      入力FD
     D savedPos        S             10U 0                                      seek保存位置
     D baseOff         S             10U 0                                      ベース位置
     D dirOff          S             10U 0                                      目録位置
     D dataOff         S             10U 0                                      データ開始位置
     D curOff          S             10U 0                                      現在書込み位置
     D numBlk          S             10I 0                                      出力ブロック数
     D blkTag          S              4A   DIM(11)                              ブロックタグ配列
     D blkOff          S             10U 0 DIM(11)                              ブロック位置配列
     D blkLen          S             10U 0 DIM(11)                              ブロック長配列
     D blkCksum        S             10U 0 DIM(11)                              ブロックCS配列
     D buf             S               *                                        作業バッファ
     D bufArr          S              1A   DIM(65536)                           バイト配列
     D                                     BASED(buf)
     D i               S             10I 0                                      ループ変数i
     D j               S             10I 0                                      ループ変数j
     D t               S             10I 0                                      ブロックループ用
     D gid             S             10I 0                                      処理中ID
     D found           S              1N                                        検索結果フラグ
       // 出力ファイルをO_CREAT|O_WRONLY|O_TRUNCで開く
       oflag = 74;
       omode = 420;
       fd = open(%TRIMR(outPath): oflag: omode);
       IF fd < 0;
         RETURN -1;
       ENDIF;

       // 必要な項目をメモリにロード
       itemPtr = getItem(src: x'69746D31'); // 'itm1'位置
       auxPtr  = getItem(src: x'69746D32'); // 'itm2'補助
       IF auxPtr <> *NULL;
         auxLen = getItemLen(src: x'69746D32');
       ENDIF;

       // ベース位置と入力FDを取得
       baseOff = getItemOff(src: x'69746D33'); // 'itm3'
       srcFd = getSrcFd(src);

       // 必須項目が無ければエラー終了
       IF itemPtr = *NULL OR baseOff = 0;
         callp close(fd);
         RETURN -2;
       ENDIF;

       // ステップ1: 入力IDを作業配列に複写
       allCount = numIds;
       FOR i = 1 TO numIds;
         allId(i) = inArr(i);
       ENDFOR;

       // ステップ2: 旧ID→新ID変換マップ構築
       FOR i = 1 TO 65536;
         idMap(i) = 0;
       ENDFOR;
       FOR i = 1 TO allCount;
         gid = allId(i);
         IF gid >= 0 AND gid < 65536;
           idMap(gid + 1) = i - 1;
         ENDIF;
       ENDFOR;

       // ステップ3: ヘッダー（目録）を書き出し
       numBlk = 4;
       csActive = *OFF;
       writeU32BE(fd: 65536);
       writeU16BE(fd: numBlk);
       dirOff = 12;
       FOR t = 1 TO numBlk;
         writeU32BE(fd: 0);
         writeU32BE(fd: 0);
         writeU32BE(fd: 0);
         writeU32BE(fd: 0);
       ENDFOR;
       dataOff = 12 + numBlk * 16;
       curOff = dataOff;

       // ステップ4: 各ブロックを書き出し（処理は省略）
       FOR t = 1 TO numBlk;
         blkTag(t) = x'626C6B31'; // 'blk1'
         blkOff(t) = curOff;
         csInit();
         csActive = *ON;
         // * (処理省略)
         csFlush();
         csActive = *OFF;
         blkCksum(t) = csGet();
         blkLen(t) = 0;
       ENDFOR;

       // ステップ5: 目録を正式値で上書き
       callp lseek(fd: dirOff: 0);
       FOR t = 1 TO numBlk;
         writeN(fd: %ADDR(blkTag(t)): 4);
         writeU32BE(fd: blkCksum(t));
         writeU32BE(fd: blkOff(t));
         writeU32BE(fd: blkLen(t));
       ENDFOR;

       callp close(fd);
       RETURN 0;
     P                 E

      *-------------------------------------------------------------
      * 以下: バイナリ書き込みユーティリティ
      *-------------------------------------------------------------
      * writeU16BE - 2バイトBE符号なし整数を書き込み
     P writeU16BE      B
     D writeU16BE      PI                                                       BE16bit書込
     D   fd                          10I 0 CONST                                出力先FD
     D   val                          5U 0 CONST                                書込み値
     D buf             S              2A                                        BE 2byte出力用
     D byteDS          DS                                                       バイト変換用DS
     D  byteChar                      1A                                        1バイト文字
     D  byteVal                       3U 0 OVERLAY(byteDS:1)                    バイト数値
     D pB              S               *                                        バッファポインタ
     D bA              S              1A   DIM(2) BASED(pB)                     バイト配列ビュー
       pB = %ADDR(buf);
       byteVal = %DIV(val:256);
       bA(1) = byteChar;
       byteVal = %REM(val:256);
       bA(2) = byteChar;
       writeN(fd: %ADDR(buf): 2);
     P                 E

      * writeU32BE - 4バイトBE符号なし整数を書き込み
     P writeU32BE      B
     D writeU32BE      PI                                                       BE32bit書込
     D   fd                          10I 0 CONST                                出力先FD
     D   val                         10U 0 CONST                                書込み値
     D buf             S              4A                                        BE 4byte出力用
     D byteDS          DS                                                       バイト変換用DS
     D  byteChar                      1A                                        1バイト文字
     D  byteVal                       3U 0 OVERLAY(byteDS:1)                    バイト数値
     D pB              S               *                                        バッファポインタ
     D bA              S              1A   DIM(4) BASED(pB)                     バイト配列ビュー
       pB = %ADDR(buf);
       byteVal = %DIV(val:16777216);
       bA(1) = byteChar;
       byteVal=%REM(%DIV(val:65536):256);
       bA(2) = byteChar;
       byteVal=%REM(%DIV(val:256):256);
       bA(3) = byteChar;
       byteVal = %REM(val:256);
       bA(4) = byteChar;
       writeN(fd: %ADDR(buf): 4);
     P                 E

      * writeN - Nバイト書き込み(CS自動供給)
     P writeN          B
     D writeN          PI            10I 0                                      Nバイト書込
     D   fd                          10I 0 CONST                                出力先FD
     D   buffer                        *   VALUE                                書込みバッファ
     D   length                      10U 0 CONST                                書込みバイト数
     D rc              S             10I 0                                      write()戻り値
       IF csActive;
         csAddBytes(buffer: length);
       ENDIF;
       rc = write(fd: buffer: length);
       RETURN rc;
     P                 E

      * padTo4 - 4バイト境界までゼロパディング
     P padTo4          B
     D padTo4          PI                                                       4byte境界パッド
     D   fd                          10I 0 CONST                                出力先FD
     D   length                      10U 0 CONST                                元データ長
     D rem             S             10U 0                                      端数バイト数
     D pad             S              4A   INZ(x'00000000')                     ゼロパディング用
       rem = %REM(length: 4);
       IF rem > 0;
         writeN(fd: %ADDR(pad): 4-rem);
       ENDIF;
     P                 E

      * readU16Buf - メモリ上のBE 2バイト値を読み取り
     P readU16Buf      B
     D readU16Buf      PI             5U 0                                      メモリBE16読取
     D   ptr                           *   CONST                                メモリ読取ptr
     D bA              S              1A   DIM(2) BASED(ptr)                    BE 2byte配列
     D byteDS          DS                                                       バイト変換用DS
     D  byteChar                      1A                                        1バイト文字
     D  byteVal                       3U 0 OVERLAY(byteDS:1)                    バイト数値
     D b1              S              3U 0                                      上位バイト値
     D b2              S              3U 0                                      下位バイト値
       byteVal = 0;
       byteChar = bA(1);
       b1 = byteVal;
       byteVal = 0;
       byteChar = bA(2);
       b2 = byteVal;
       RETURN b1 * 256 + b2;
     P                 E

      * readU32Buf - メモリ上のBE 4バイト値を読み取り
     P readU32Buf      B
     D readU32Buf      PI            10U 0                                      メモリBE32読取
     D   ptr                           *   CONST                                メモリ読取ptr
     D bA              S              1A   DIM(4) BASED(ptr)                    BE 4byte配列
     D byteDS          DS                                                       バイト変換用DS
     D  byteChar                      1A                                        1バイト文字
     D  byteVal                       3U 0 OVERLAY(byteDS:1)                    バイト数値
     D b1              S             10U 0                                      第1バイト値
     D b2              S             10U 0                                      第2バイト値
     D b3              S             10U 0                                      第3バイト値
     D b4              S             10U 0                                      第4バイト値
       byteVal = 0;
       byteChar = bA(1);
       b1 = byteVal;
       byteVal = 0;
       byteChar = bA(2);
       b2 = byteVal;
       byteVal = 0;
       byteChar = bA(3);
       b3 = byteVal;
       byteVal = 0;
       byteChar = bA(4);
       b4 = byteVal;
       RETURN b1*16777216+b2*65536+b3*256+b4;
     P                 E

      * writeU16Buf - メモリ上にBE 2バイト値を書き込み
     P writeU16Buf     B
     D writeU16Buf     PI                                                       メモリBE16書込
     D   ptr                           *   CONST                                書込み先ptr
     D   val                          5U 0 CONST                                書込み値
     D bA              S              1A   DIM(2) BASED(ptr)                    BE 2byte配列
     D byteDS          DS                                                       バイト変換用DS
     D  byteChar                      1A                                        1バイト文字
     D  byteVal                       3U 0 OVERLAY(byteDS:1)                    バイト数値
       byteVal = %DIV(val:256);
       bA(1) = byteChar;
       byteVal = %REM(val:256);
       bA(2) = byteChar;
     P                 E

      *-------------------------------------------------------------
      * csInit - 検査値アキュムレーター初期化
      *-------------------------------------------------------------
     P csInit          B
     D csInit          PI                                                       CS初期化
       csSum = 0;
       csPos = 0;
       csBufArr(1) = x'00';
       csBufArr(2) = x'00';
       csBufArr(3) = x'00';
       csBufArr(4) = x'00';
     P                 E

      * csAddBytes - バイト列を検査値に供給
      * 4byteバッファ(csBufArr)に蓄積し、4byte毎に加算。
      * 端数はcsFlush()でゼロ埋めして確定する。（本体は省略）
     P csAddBytes      B
     D csAddBytes      PI                                                       CSに加算
     D   dataPtr                       *   CONST                                入力データptr
     D   dataLen                     10U 0 CONST                                入力バイト数
     D srcArr          S              1A   DIM(65535)                           入力バイト配列
     D                                     BASED(dataPtr)
     D ww              S             10U 0                                      4byte合成値
     D idx             S             10U 0                                      バイト走査位置
       FOR idx = 1 TO dataLen;
         csPos = csPos + 1;
         csBufArr(csPos) = srcArr(idx);
         IF csPos >= 4;
           // * (処理省略)
           csPos = 0;
         ENDIF;
       ENDFOR;
     P                 E

      * csFlush - 端数バイトをゼロパディングして確定（本体は省略）
     P csFlush         B
     D csFlush         PI                                                       CS確定
     D ww              S             10U 0                                      4byte合成値
       IF csPos > 0;
         DOW csPos < 4;
           csPos = csPos + 1;
           csBufArr(csPos) = x'00';
         ENDDO;
         csPos = 0;
       ENDIF;
     P                 E

      * csGet - 32ビットチェックサム値を返す
     P csGet           B
     D csGet           PI            10U 0                                      CS取得
       RETURN %REM(csSum: 4294967296);
     P                 E
