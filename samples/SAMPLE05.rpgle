     H NOMAIN
      *=====================================================================
      * Module: SAMPLE05 - サンプルモジュール
      * Description: 回帰テスト用の中立サンプル（固定形式ILE-RPG）
      * Version: 1.0.0
      *=====================================================================

      *-------------------------------------------------------------
      * 定数
      *-------------------------------------------------------------
     D CONST01         C                   4096                                 最大要素数
     D CONST02         C                   44032                                基準値A
     D CONST03         C                   4352                                 基準値B
     D CONST04         C                   4449                                 基準値C
     D CONST05         C                   4519                                 基準値D
     D CONST06         C                   19                                   件数A
     D CONST07         C                   21                                   件数B
     D CONST08         C                   28                                   件数C
     D CONST09         C                   588                                  件数D
     D CONST10         C                   11172                                件数E

      *-------------------------------------------------------------
      * 公開プロトタイプ
      *-------------------------------------------------------------
     D PROC01          PR            10I 0 EXTPROC('PROC01')                    データ処理
     D inArr                         10U 0 DIM(4096) CONST                      入力配列
     D inCount                       10I 0 CONST                                入力件数
     D outArr                        10U 0 DIM(4096)                            出力配列
     D maxOut                        10I 0 CONST                                出力最大件数

      *-------------------------------------------------------------
      * 内部プロトタイプ
      *-------------------------------------------------------------
     D PROC02          PR            10I 0                                      項目評価
     D val                           10U 0 CONST                                対象値

     D PROC03          PR            10U 0                                      項目合成
     D val1                          10U 0 CONST                                先行値
     D val2                          10U 0 CONST                                後続値

     D PROC04          PR                                                       並べ替え
     D arr                           10U 0 DIM(4096)                            配列(更新)
     D count                         10I 0 CONST                                配列件数

      *=====================================================================
      * PROC01 - データ処理
      *=====================================================================
     P PROC01          B                   EXPORT
     D PROC01          PI            10I 0                                      データ処理
     D inArr                         10U 0 DIM(4096) CONST                      入力配列
     D inCount                       10I 0 CONST                                入力件数
     D outArr                        10U 0 DIM(4096)                            出力配列
     D maxOut                        10I 0 CONST                                出力最大件数

     D i               S             10I 0                                      ループ添字
     D j               S             10I 0                                      内側添字
     D base            S             10U 0                                      基底値
     D cur             S             10I 0                                      現在値
     D outCnt          S             10I 0                                      出力件数

       IF inCount <= 0;
         RETURN 0;
       ENDIF;

       outCnt = 0;
       FOR i = 1 TO inCount;
         cur = PROC02(inArr(i));
         IF cur > 0 AND
            outCnt < maxOut;
           outCnt += 1;
           outArr(outCnt) = inArr(i);
         ENDIF;
       ENDFOR;

       PROC04(outArr: outCnt);
       base = PROC03(inArr(1):
                     inArr(inCount));
       IF base > 0;
         outCnt += 1;
       ENDIF;

       RETURN outCnt;
     P                 E

      *=====================================================================
      * PROC02 - 項目評価
      *=====================================================================
     P PROC02          B
     D PROC02          PI            10I 0                                      項目評価
     D val                           10U 0 CONST                                対象値

       * (処理省略)
       IF val >= 768 AND val <= 879;
         SELECT;
         WHEN val >= 768 AND val <= 788;
           RETURN 230;
         WHEN val >= 790 AND val <= 819;
           RETURN 220;
         OTHER;
           RETURN 230;
         ENDSL;
       ENDIF;

       SELECT;
       WHEN val = CONST02;
         RETURN 1;
       WHEN val = CONST03;
         RETURN 2;
       OTHER;
         RETURN 0;
       ENDSL;
     P                 E

      *=====================================================================
      * PROC03 - 項目合成
      *=====================================================================
     P PROC03          B
     D PROC03          PI            10U 0                                      項目合成
     D val1                          10U 0 CONST                                先行値
     D val2                          10U 0 CONST                                後続値

     D idx             S             10I 0                                      作業索引
     D accA            S             10I 0                                      作業値A
     D accB            S             10I 0                                      作業値B

       * (処理省略)
       IF val1 >= CONST02 AND
          val1 < CONST02 + CONST10;
         idx = val1 - CONST02;
         accA = CONST03 +
                %DIV(idx: CONST09);
         accB = CONST04 +
                %DIV(%REM(idx: CONST09):
                     CONST08);
         DOW idx > 0;
           idx -= CONST06;
           IF idx < 0;
             LEAVE;
           ENDIF;
         ENDDO;
         RETURN accA + accB;
       ENDIF;

       RETURN 0;
     P                 E

      *=====================================================================
      * PROC04 - 並べ替え
      *=====================================================================
     P PROC04          B
     D PROC04          PI                                                       並べ替え
     D arr                           10U 0 DIM(4096)                            配列(更新)
     D count                         10I 0 CONST                                配列件数

     D i               S             10I 0                                      外側添字
     D j               S             10I 0                                      内側添字
     D swapped         S              1N                                        交換フラグ
     D tmp             S             10U 0                                      一時変数

       IF count <= 1;
         RETURN;
       ENDIF;

       FOR i = 1 TO count - 1;
         swapped = *OFF;
         FOR j = 1 TO count - i;
           IF arr(j) > arr(j + 1);
             tmp = arr(j);
             arr(j) = arr(j + 1);
             arr(j + 1) = tmp;
             swapped = *ON;
           ENDIF;
         ENDFOR;
         IF NOT swapped;
           LEAVE;
         ENDIF;
       ENDFOR;
     P                 E
