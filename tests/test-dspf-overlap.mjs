// DSPF_FIELD_OVERLAP (CPD7866相当) の回帰テスト
// 実例: AIADMND.dspf TENFTR — 無条件定数 'F3/12=戻る  F5=再表示' (23 2, DBCS込み25バイト
// = col2-26) と標識77付き定数 'F6=追加' (23 26) の重なりが CPD7866 を出した。
// 一方、77/N77 の排他表示定数同士の重なり (CPD7865) は意図的なので検出しないこと。
import { Orchestrator } from '../build/orchestrator.js';
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

// --- ケース7: 先頭属性バイト衝突 (AITNTCFGD CTLWIN 行4 実例・CPD7866) ---
// '状態:' (4,2) = SO+状態+SI+':' = 7バイト → col2-8。'テナント' (4,9) の
// 先頭属性バイト位置 col8 に ':' のデータ → データは隣接で重ならないがCPD7866。
const attrCollision = [
  "     A          R CTLWIN",
  "     A                                  4  2'状態:'",
  "     A                                      COLOR(BLU)",
  "     A                                  4  9'テナント'",
  "     A                                      COLOR(BLU)",
  "     A            CWTNS          8O  O  4 21",
].join('\n');
check('attr-byte-collision-detected', attrCollision, o => o.length === 1 && o[0].line === 4);

// --- ケース8: 修正後 (テナント col10 = 属性バイト分1桁空き) → 0件 ---
const attrFixed = attrCollision.replace("4  9'テナント'", "4 10'テナント'");
check('attr-byte-gap1-clean', attrFixed, o => o.length === 0);

// --- ケース9: SBCS定数直後のフィールド開始も属性バイト衝突 (CWOPT 14,12 実例) ---
// '選択 ==>' = SO+選択+SI+' ==>' = 10バイト → col2-11。CWOPT col12開始は属性バイトがcol11の'>'に乗る。
const sbcsAttrCollision = [
  "     A          R CTLWIN",
  "     A                                 14  2'選択 ==>'",
  "     A            CWOPT          1A  B 14 12COLOR(WHT)",
].join('\n');
check('sbcs-attr-byte-collision-detected', sbcsAttrCollision, o => o.length === 1);
check('sbcs-attr-byte-gap-clean',
  sbcsAttrCollision.replace('14 12COLOR', '14 14COLOR'), o => o.length === 0);

// --- ケース10: 半角カタカナはSBCS(1バイト) — DBCS扱いの過大計上で偽陽性にしない (AIOPSD実例) ---
// '日次ﾄｰｸﾝ上限 (0=無制限):' = SO日次SI(6)+ﾄｰｸﾝ(4)+SO上限SI(6)+' (0='(4)+SO無制限SI(8)+'):'(2)
// = 30バイト → col2-31。UTTOK (7,34) の属性バイトはcol33で空き → 重なりなし。
const halfwidthKana = [
  "     A          R OPSCRN",
  "     A                                  7  2'日次ﾄｰｸﾝ上限 (0=無制限):'",
  "     A                                      COLOR(BLU)",
  "     A            UTTOK          9Y 0B  7 34",
].join('\n');
check('halfwidth-katakana-sbcs-clean', halfwidthKana, o => o.length === 0);

console.log(failed === 0 ? '\nAll tests passed.' : `\n${failed} test(s) FAILED.`);
process.exit(failed === 0 ? 0 : 1);
