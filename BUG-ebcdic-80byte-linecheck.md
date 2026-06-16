# バグ報告: EBCDIC 80 バイト超の行を検出できていない (RPG 行長チェック)

/ 報告元: IBM_i_and_AI プロジェクト (Claude)。2026-06-16。
/ ツール: `check_rpg_file` (MCP)、引数 `considerDBCS: true`, `language: 'ja'`。

## 症状
`check_rpg_file` で `src/AICHAT.sqlrpgle` を検査したところ **エラー0 / 警告2 (INDICATOR_USAGE *IN12 のみ) で「合格」**判定。
しかし下記コメント行は **EBCDIC (CCSID 1399 / IBM-1399) 換算で 83〜86 バイト**あり、**80 バイトを超過**している。
EBCDIC 換算 (SBCS=1 / DBCS=2 / SO(0x0E)・SI(0x0F) 各1) で 80 超を検出すべきところ、見逃している。

## 証拠 (authoritative: iconv で実 EBCDIC バイトを計測)
計測コマンド (IBM i PASE):
```
sed -n "<行番号>p" AICHAT.sqlrpgle | iconv -f UTF-8 -t IBM-1399 | wc -c   # 改行込みなので実バイトは -1
```
結果 (実バイト = wc -c から改行1を引いた値):

| 行 | 実 EBCDIC バイト | 行の内容 (コメント) |
|----|------:|------|
| 2513 | **86** | `//   (1) 先に「デモ専用 Excel (窓タイトル excel_*)」だけを taskkill で` |
| 2514 | **83** | `//       閉じる。デモの xlsx は excel_YYYYMMDD_HHMMSS.xlsx 命名のため` |
| 2515 | **84** | `//       タイトルが excel_* で一致。ユーザーの通常 Excel は別タイトル/` |
| 2516 | **85** | `//       別プロセスなので巻き込まない (= Chrome 全消し事故の再発防止)。` |

対照 (正しく問題にならない短い行): 行2539 `// (2) UNC を組み立て、読み取り専用 (excel /x /r) で開く` = **70 バイト** (≤80、検出不要)。

## 最小再現
以下4行 (各 >80 EBCDIC バイト) を含む RPG ソースを `check_rpg_file(considerDBCS:true, language:'ja')` にかけても行長エラーが出ない:
```
       //   (1) 先に「デモ専用 Excel (窓タイトル excel_*)」だけを taskkill で
       //       閉じる。デモの xlsx は excel_YYYYMMDD_HHMMSS.xlsx 命名のため
       //       タイトルが excel_* で一致。ユーザーの通常 Excel は別タイトル/
       //       別プロセスなので巻き込まない (= Chrome 全消し事故の再発防止)。
```

## 期待される動作
EBCDIC (SBCS=1 / DBCS=2 / SO・SI 各1) 換算で行が 80 バイトを超えたら警告 (または該当ルールのエラー) を出す。
(コメント行・機能行を問わず。DBCS 領域の SO/SI バイトを必ず加算すること。)

## 影響
DBCS が 80 バイトを超えるとコンパイルは通るが**コンパイルリストが文字化け**する (>100 バイトで CPYFRMSTMF が truncate しソース欠落)。
本チェックの見逃しにより開発者が事前に気づけない。`considerDBCS:true` 指定時に特に重要。

## 疑わしい箇所 (調査の起点)
RPG 行長チェッカー (おそらく `src/checkers/` 配下) の DBCS バイト換算。
表示桁数や UTF-8 文字数で 80 判定していると SO/SI 分を取りこぼし、本症状になる。
