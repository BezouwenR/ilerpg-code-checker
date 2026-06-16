import { Orchestrator } from '../build/orchestrator.js';

// D仕様書行をフィールド単位で正確に組み立てる
// col1-5空白, col6='D', col7-21=name(15), col22=ext, col23=dsType, col24-25=decl, col26-32=from(7), col33-39=size(7右詰), col40=type, col41-42=dec, col43=空白, col44-=keywords
function dline({ name = '', ext = ' ', dsType = ' ', decl = '  ', size = '', type = ' ', dec = '  ', kw = '' }) {
  return '     D' + name.padEnd(15) + ext + dsType + decl.padEnd(2) + ' '.repeat(7) +
    String(size).padStart(7) + type + dec.padStart(2) + ' ' + kw;
}

// --- 単一行ケース ---
const cases = [
  ['正常PSDS (col23=S)',          dline({ name: 'mypsds', dsType: 'S', decl: 'DS' }), null],
  ['正常データ域DS (col23=U)',     dline({ name: 'mydta', dsType: 'U', decl: 'DS', kw: 'DTAARA(MYDTA)' }), null],
  ['正常外部記述DS (col22=E)',     dline({ name: 'extds', ext: 'E', decl: 'DS', kw: "EXTNAME('MYFILE')" }), null],
  ['15文字ちょうどの名前',          dline({ name: 'ABCDEFGHIJKLMNO', decl: 'S', size: 10, type: 'I', dec: '0' }), null],
  ['名前あふれ14文字col9開始',      '     D  P_DBC_CONSUMED               10I 0 OPTIONS(*NOPASS)', 'D_SPEC_NAME_OVERFLOW'],
  ['名前あふれ16文字col7開始',      '     DABCDEFGHIJKLMNOP S             10I 0', 'D_SPEC_NAME_OVERFLOW'],
  ['宣言型空白行でcol23にS',        dline({ name: ' P_PARM', dsType: 'S', size: 10, type: 'I', dec: '0' }), 'D_SPEC_DS_TYPE_INVALID'],
  ['col23にSだが宣言型がDSでない',  dline({ name: 'myvar', dsType: 'S', decl: 'S ', size: 10, type: 'I', dec: '0' }), 'D_SPEC_DS_TYPE_INVALID'],
  ['col23に不正文字X',             dline({ name: 'myvar', dsType: 'X', decl: 'S ', size: 10, type: 'I', dec: '0' }), 'D_SPEC_DS_TYPE_INVALID'],
  ['col22に不正文字X',             dline({ name: 'myvar', ext: 'X', decl: 'S ', size: 10, type: 'I', dec: '0' }), 'D_SPEC_EXT_DESC_INVALID'],
  ['DSがcol22-23に誤配置',         '     D mapArr        DS                    DIM(4096)', 'D_SPEC_DECL_TYPE_MISPLACED'],
  // col22='E'の曖昧性解消（v0.0.12）
  ['外部記述DS: EXTNAMEなし+名前11文字以上', dline({ name: 'CUSTOMER_REC', ext: 'E', decl: 'DS' }), 'D_SPEC_EXTNAME_REQUIRED'],
  ['外部記述DS: EXTNAMEあり+名前11文字以上（正常）', dline({ name: 'CUSTOMER_REC', ext: 'E', decl: 'DS', kw: "EXTNAME('CUSFILE')" }), null],
  ['外部記述DS: EXTNAMEなし+名前10文字以内（正常: 名前=ファイル名）', dline({ name: 'CUSFILE', ext: 'E', decl: 'DS' }), null],
  ['PR/PI外のサブフィールドE+col21埋まり（曖昧なため検出対象外）', dline({ name: ' SUBFLD_LONGNAM', ext: 'E', kw: "EXTFLD('XYZ')" }), null],
];

// --- 複数行ケース（PR/PIブロック文脈が必要） ---
const PR_HEADER = "     D AIDBCSU         PR                  EXTPGM('AIDBCSU')";
const PI_HEADER = '     D AIMONR          PI';
const multiCases = [
  ['PRパラメータの名前あふれ末尾E',
    [PR_HEADER, '     D  P_DBC_RESPONSE               10I 0 OPTIONS(*NOPASS)'],
    'D_SPEC_NAME_OVERFLOW', 2],
  ['PRパラメータ行に意図的なE（col21空白）',
    [PR_HEADER, dline({ name: ' P_PARM', ext: 'E', size: 10, type: 'I', dec: '0' })],
    'D_SPEC_EXT_DESC_INVALID', 2],
  ['PIパラメータの名前あふれ末尾E',
    [PI_HEADER, '     D  P_LONG_VALUE_E               10A'],
    'D_SPEC_NAME_OVERFLOW', 2],
  ['PRブロック終了後（DS開始）のサブフィールドEは検出対象外',
    [PR_HEADER,
     dline({ name: ' P_PARM', size: 10, type: 'I', dec: '0' }),
     dline({ name: 'mydsname', decl: 'DS' }),
     dline({ name: ' SUBFLD_LONGNAM', ext: 'E', kw: "EXTFLD('XYZ')" })],
    null, -1],
  ['PRブロックは他仕様書（C仕様）でも終了する',
    [PR_HEADER,
     dline({ name: ' P_PARM', size: 10, type: 'I', dec: '0' }),
     '     C                   EVAL      X = 1',
     dline({ name: ' SUBFLD_LONGNAM', ext: 'E' })],
    null, -1],
];

const o = new Orchestrator();
const rules = ['D_SPEC_NAME_OVERFLOW', 'D_SPEC_EXT_DESC_INVALID', 'D_SPEC_DS_TYPE_INVALID', 'D_SPEC_DECL_TYPE_MISPLACED', 'D_SPEC_EXTNAME_REQUIRED'];
let ng = 0;
for (const [desc, line, expect] of cases) {
  const r = o.checkCode(line, 'standard');
  const hits = r.issues.filter(i => rules.includes(i.rule)).map(i => i.rule);
  const ok = expect ? (hits.length === 1 && hits[0] === expect) : hits.length === 0;
  if (!ok) ng++;
  console.log(`${ok ? 'OK' : 'NG'} ${desc}: [${hits.join(',')}] (期待: ${expect ?? 'なし'}) col22='${line[21] ?? ''}' col23='${line[22] ?? ''}' col24-25='${line.substring(23, 25)}'`);
}
for (const [desc, srcLines, expect, expectLine] of multiCases) {
  const r = o.checkCode(srcLines.join('\n'), 'standard');
  const hits = r.issues.filter(i => rules.includes(i.rule));
  const ok = expect
    ? (hits.length === 1 && hits[0].rule === expect && hits[0].line === expectLine)
    : hits.length === 0;
  if (!ok) ng++;
  console.log(`${ok ? 'OK' : 'NG'} ${desc}: [${hits.map(i => `L${i.line}:${i.rule}`).join(',')}] (期待: ${expect ? `L${expectLine}:${expect}` : 'なし'})`);
}
console.log(ng === 0 ? 'ALL OK' : `${ng} NG`);
