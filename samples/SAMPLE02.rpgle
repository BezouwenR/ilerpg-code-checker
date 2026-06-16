      *===============================================================
      * SAMPLE02 - サンプルモジュール
      * Version: 1.0.0
      * 固定形式の桁位置チェッカー回帰テスト用サンプル。
      *===============================================================
     H NOMAIN
      /COPY QSYSINC/QRPGLESRC,SYSTYPES
      /COPY QSYSINC/QRPGLESRC,SYSSTAT
      /COPY QSYSINC/QRPGLESRC,FCNTL
      /COPY QSYSINC/QRPGLESRC,UNISTD

      *-------------------------------------------------------------
      * 公開プロシージャ宣言
      *-------------------------------------------------------------
      * PROC01 - データ処理1（名前継続行の例）
     D PROC01...                                                                データ処理1
     D                 PR          4096A   VARYING
     D                                     EXTPROC(*CL:'PROC01')
     D   FLD01                         *   CONST                                入力項目ptr
     D   FLD02                         *   CONST                                入力項目ptr
     D   numItems                    10I 0 CONST                                項目数

      * PROC02 - データ処理2（複数行パラメータの例）
     D PROC02...                                                                データ処理2
     D                 PR          2048A   VARYING
     D                                     EXTPROC(*CL:'PROC02')
     D   FLD03                       64A   CONST VARYING                        名前項目
     D   FLD04                         *   CONST                                入力項目ptr
     D   FLD01                         *   CONST                                入力項目ptr
     D   numItems                    10I 0 CONST                                項目数
     D   objA...                                                                obj番号A
     D                               10I 0 CONST
     D   objB...                                                                obj番号B
     D                               10I 0 CONST

      * PROC03 - データ処理3
     D PROC03          PR          1024A   VARYING EXTPROC(*CL:'PROC03')        データ処理3
     D   FLD03                       64A   CONST VARYING                        名前項目
     D   objNum                      10I 0 CONST                                obj番号
     D   objRef                      10I 0 CONST                                参照obj番号

      *-------------------------------------------------------------
      * ユーティリティプロシージャ
      *-------------------------------------------------------------
     D PROC04          PR            10U 0 EXTPROC(*CL:'PROC04')                値取得
     D   FLD05                      256A   CONST VARYING                        入力文字列
     D   pos                         10I 0                                      走査位置

     D PROC05          PR             4A   EXTPROC(*CL:'PROC05')                4桁変換
     D   val                         10U 0 CONST                                変換元数値

      *-------------------------------------------------------------
      * 外部プロシージャ宣言
      *-------------------------------------------------------------
     D getValueA       PR            10I 0 EXTPROC(*CL:'getValueA')             値A取得
     D   FLD04                         *   CONST                                入力項目ptr
     D getValueB       PR            10I 0 EXTPROC(*CL:'getValueB')             値B取得
     D   FLD04                         *   CONST                                入力項目ptr
     D   itemId                      10I 0 CONST                                対象ID

      *===============================================================
      * PROC01 - データ処理1
      *===============================================================
     P PROC01...
     P                 B                   EXPORT
     D PROC01...                                                                データ処理1
     D                 PI          4096A    VARYING
     D   FLD01                         *   CONST                                入力項目ptr
     D   FLD02                         *   CONST                                入力項目ptr
     D   numItems                    10I 0 CONST                                項目数
     D result          S           4096A   VARYING                              出力結果
     D aArr            S             10I 0 DIM(65536)                           作業配列A
     D                                     BASED(FLD01)
     D bArr            S             10U 0 DIM(65536)                           作業配列B
     D                                     BASED(FLD02)
     D i               S             10I 0                                      ループ索引
     D hex4            S              4A                                        作業用
       // (処理省略)
       RETURN result;
     P                 E

      *===============================================================
      * PROC02 - データ処理2
      *===============================================================
     P PROC02...
     P                 B                   EXPORT
     D PROC02...                                                                データ処理2
     D                 PI          2048A    VARYING
     D   FLD03                       64A   CONST VARYING                        名前項目
     D   FLD04                         *   CONST                                入力項目ptr
     D   FLD01                         *   CONST                                入力項目ptr
     D   numItems                    10I 0 CONST                                項目数
     D   objA...                                                                obj番号A
     D                               10I 0 CONST
     D   objB...                                                                obj番号B
     D                               10I 0 CONST
     D result          S           2048A   VARYING                              出力結果
     D aArr            S             10I 0 DIM(65536)                           作業配列A
     D                                     BASED(FLD01)
     D upm             S             10I 0                                      作業値1
     D wid             S             10I 0                                      作業値2
     D i               S             10I 0                                      ループ索引
       // (処理省略)
       RETURN result;
     P                 E

      *===============================================================
      * PROC03 - データ処理3
      *===============================================================
     P PROC03...
     P                 B                   EXPORT
     D PROC03...                                                                データ処理3
     D                 PI          1024A    VARYING
     D   FLD03                       64A   CONST VARYING                        名前項目
     D   objNum                      10I 0 CONST                                obj番号
     D   objRef                      10I 0 CONST                                参照obj番号
     D result          S           1024A   VARYING                              出力結果
       // (処理省略)
       RETURN result;
     P                 E

      *===============================================================
      * PROC04 - 値取得（DS/OVERLAYの例）
      *===============================================================
     P PROC04          B                   EXPORT
     D PROC04          PI            10U 0                                      値取得
     D   FLD05                      256A   CONST VARYING                        入力文字列
     D   pos                         10I 0                                      走査位置
     D byteDS          DS                                                       バイト変換DS
     D  byteChar                      1A                                        1バイト
     D  byteVal                       3U 0 OVERLAY(byteDS:1)                    数値変換先
     D b1              S              3U 0                                      作業バイト
     D cp              S             10U 0                                      結果値
     D len             S             10I 0                                      文字列長
       // (処理省略)
       RETURN cp;
     P                 E

      *===============================================================
      * PROC05 - 4桁変換（INZ/%SUBSTの例）
      *===============================================================
     P PROC05          B                   EXPORT
     D PROC05          PI             4A                                        4桁変換
     D   val                         10U 0 CONST                                変換元数値
     D hexChars        S             16A   INZ('0123456789ABCDEF')              文字テーブル
     D result          S              4A                                        4桁結果
       // (処理省略)
       RETURN result;
     P                 E
