// 回帰テスト: COMMENT_LINE_EBCDIC_OVERFLOW
// コメント行（col7='*' / 行頭'//'）が EBCDIC 換算で 80 バイトを超えたら warning。
// 100 バイト超は LINE_LENGTH(error) に委ねて二重報告しないこと。
import { Orchestrator } from '../build/orchestrator.js';

let failures = 0;
const assert = (cond, msg) => {
  console.log(`  ${cond ? 'PASS' : 'FAIL'}: ${msg}`);
  if (!cond) failures++;
};
const run = (code, opts) =>
  new Orchestrator(opts).checkCode(code, 'standard').issues;
const has = (issues, rule, line) =>
  issues.some(i => i.rule === rule && (line === undefined || i.line === line));

// --- ケース1: バグレポートの4行（>80, <=100）+ 短い行（<=80, 非検出）---
const code1 = [
  '       //   (1) 先に「デモ専用 Excel (窓タイトル excel_*)」だけを taskkill で', // L1 >80
  '       //       閉じる。デモの xlsx は excel_YYYYMMDD_HHMMSS.xlsx 命名のため',   // L2 >80
  '       //       タイトルが excel_* で一致。ユーザーの通常 Excel は別タイトル/', // L3 >80
  '       //       別プロセスなので巻き込まない (= Chrome 全消し事故の再発防止)。', // L4 >80
  '       // (2) UNC を組み立て、読み取り専用 (excel /x /r) で開く',                // L5 <=80 非検出
  '     C* 固定形式コメント(col7=*)も対象で日本語をたくさん含む長いコメント行です',  // L6 >80
].join('\n');
const r1 = run(code1, { language: 'ja', considerDBCS: true });
for (const ln of [1, 2, 3, 4]) {
  assert(has(r1, 'COMMENT_LINE_EBCDIC_OVERFLOW', ln), `L${ln}: '//' コメント80超を検出`);
}
assert(!has(r1, 'COMMENT_LINE_EBCDIC_OVERFLOW', 5), 'L5: 80バイト以下の短いコメントは非検出');
assert(has(r1, 'COMMENT_LINE_EBCDIC_OVERFLOW', 6), 'L6: 固定形式(*)コメント80超を検出');

// --- ケース2: considerDBCS=false では検出しない ---
const r2 = run(code1, { language: 'ja', considerDBCS: false });
assert(!has(r2, 'COMMENT_LINE_EBCDIC_OVERFLOW'), 'considerDBCS=false では非検出');

// --- ケース3: 100バイト超は LINE_LENGTH(error)、COMMENT_LINE_EBCDIC_OVERFLOWは出さない ---
const code3 = '       // ' + 'あ'.repeat(50); // 10 + SO(1)+100+SI(1) = 112バイト
const r3 = run(code3, { language: 'ja', considerDBCS: true });
assert(has(r3, 'LINE_LENGTH'), '100超コメント行は LINE_LENGTH(error) を出す');
assert(!has(r3, 'COMMENT_LINE_EBCDIC_OVERFLOW'),
  '100超コメント行は COMMENT_LINE_EBCDIC_OVERFLOW を出さない（二重報告回避）');

// --- ケース4: コメント行以外（機能行）は対象外 ---
const code4 = '     C                   eval      x = ' + "'" + 'あ'.repeat(40) + "'"; // 長い機能行
const r4 = run(code4, { language: 'ja', considerDBCS: true });
assert(!has(r4, 'COMMENT_LINE_EBCDIC_OVERFLOW'), '機能行（コメントでない）は対象外');

console.log(`\n${failures === 0 ? 'ALL PASS' : failures + ' FAILED'}`);
process.exit(failures === 0 ? 0 : 1);
