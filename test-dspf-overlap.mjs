// DSPF_FIELD_OVERLAP (CPD7866相当) の回帰テスト
// 実例: AIADMND.dspf TENFTR — 無条件定数 'F3/12=戻る  F5=再表示' (23 2, DBCS込み25バイト
// = col2-26) と標識77付き定数 'F6=追加' (23 26) の重なりが CPD7866 を出した。
// 一方、77/N77 の排他表示定数同士の重なり (CPD7865) は意図的なので検出しないこと。
import { Orchestrator } from './build/orchestrator.js';
import fs from 'fs';

const orchestrator = new Orchestrator({ language: 'ja', considerDBCS: true });
let failed = 0;

function check(name, content, expectFn) {
  const result = orchestrator.checkCode(content, 'standard', name + '.dspf');
  const overlaps = result.issues.filter(i => i.rule === 'DSPF_FIELD_OVERLAP');
  const ok = expectFn(overlaps);
  console.log(`${ok ? 'PASS' : 'FAIL'}: ${name} (DSPF_FIELD_OVERLAP=${overlaps.length})`);
  for (const i of overlaps) console.log(`    L${i.line}: ${i.message}`);
  if (!ok) failed++;
}

// --- ケース1: 修正前TENFTR相当 — 無条件定数 vs 標識付き定数 (col26) → 検出1件 ---
const before = [
  "     A          R TENFTR",
  "     A                                 23  2'F3/12=戻る  F5=再表示'",
  "     A                                      COLOR(BLU)",
  "     A  77                             23 26'F6=追加'",
  "     A                                      COLOR(BLU)",
].join('\n');
check('before-fix-overlap-detected', before, o => o.length === 1 && o[0].line === 4);

// --- ケース2: 修正後TENFTR相当 (col28) → 検出0件 ---
const after = before.replace("23 26'F6=追加'", "23 28'F6=追加'");
check('after-fix-no-overlap', after, o => o.length === 0);

// --- ケース3: 77/N77 排他表示の重なり (CPD7865相当・意図的) → 検出しない ---
const exclusive = [
  "     A          R TENCTL",
  "     A  77                              6  4'3=停止  4=削除  5=詳細  6=履歴'",
  "     A                                      COLOR(BLU)",
  "     A N77                              6  4'3=停止  5=詳細  6=履歴'",
  "     A                                      COLOR(BLU)",
].join('\n');
check('exclusive-indicators-not-reported', exclusive, o => o.length === 0);

// --- ケース4: DBCS定数(継続行)と名前付きフィールドの重なり (defect #42 パターン) ---
// '選択 ==>' (SO+選択4+SI + ' ==>' = 10バイト, col4-13) と MNOPT (15 12) の重なり
const constVsField = [
  "     A          R MENUSCR",
  "     A                                 15  4'選択 ==>'",
  "     A            MNOPT          1A  B 15 12",
].join('\n');
check('dbcs-const-vs-field-detected', constVsField, o => o.length === 1);

// --- ケース5: 継続リテラル('+'/'-')の長さ計算 — AIADMND row10見出し(無条件・単独行) → 0件
//     かつ '+'継続後の定数とフィールドの重なり → 検出 ---
const continuation = [
  "     A          R TESTSCR",
  "     A                                  5  2'オプションを入力して，実行キーを+",
  "     A                                      押してください。'",
  // 上: 24 DBCS連続 = SO+48+SI = 50バイト → col2-51
  "     A            FLD1           5A  O  5 40",
].join('\n');
check('continued-literal-overlap-detected', continuation, o => o.length === 1);

// --- ケース6: 現行 AIADMND.dspf 実ソース → 0件 ---
const aiadmnd = fs.readFileSync('E:/IBM_i_and_AI/src/AIADMND.dspf', 'utf-8');
check('current-AIADMND-clean', aiadmnd, o => o.length === 0);

console.log(failed === 0 ? '\nAll tests passed.' : `\n${failed} test(s) FAILED.`);
process.exit(failed === 0 ? 0 : 1);
