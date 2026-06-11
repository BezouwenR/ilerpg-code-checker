import { Orchestrator } from './build/orchestrator.js';

// D仕様書行をフィールド単位で正確に組み立てる
// col1-5空白, col6='D', col7-21=name(15), col22=ext, col23=dsType, col24-25=decl, col26-32=from(7), col33-39=size(7右詰), col40=type, col41-42=dec, col43=空白, col44-=keywords
function dline({ name = '', ext = ' ', dsType = ' ', decl = '  ', size = '', type = ' ', dec = '  ', kw = '' }) {
  return '     D' + name.padEnd(15) + ext + dsType + decl.padEnd(2) + ' '.repeat(7) +
    String(size).padStart(7) + type + dec.padStart(2) + ' ' + kw;
}

const cases = [
  ['正常PSDS (col23=S)',          dline({ name: 'mypsds', dsType: 'S', decl: 'DS' }), null],
  ['正常データ域DS (col23=U)',     dline({ name: 'mydta', dsType: 'U', decl: 'DS', kw: 'DTAARA(MYDTA)' }), null],
  ['正常外部記述DS (col22=E)',     dline({ name: 'extds', ext: 'E', decl: 'DS', kw: "EXTNAME('MYFILE')" }), null],
  ['15文字ちょうどの名前',          dline({ name: 'ABCDEFGHIJKLMNO', decl: 'S', size: 10, type: 'I', dec: '0' }), null],
  ['名前あふれ14文字col9開始',      '     D  P_DBC_CONSUMED               10I 0 OPTIONS(*NOPASS)', 'D_SPEC_NAME_OVERFLOW'],
  ['名前あふれ16文字col7開始',      '     DABCDEFGHIJKLMNOP S             10I 0', 'D_SPEC_NAME_OVERFLOW'],
  ['パラメータ行でcol23にS',        dline({ name: ' P_PARM', dsType: 'S', size: 10, type: 'I', dec: '0' }), 'D_SPEC_DS_TYPE_INVALID'],
  ['col23にSだが宣言型がDSでない',  dline({ name: 'myvar', dsType: 'S', decl: 'S ', size: 10, type: 'I', dec: '0' }), 'D_SPEC_DS_TYPE_INVALID'],
  ['col23に不正文字X',             dline({ name: 'myvar', dsType: 'X', decl: 'S ', size: 10, type: 'I', dec: '0' }), 'D_SPEC_DS_TYPE_INVALID'],
  ['col22に不正文字X',             dline({ name: 'myvar', ext: 'X', decl: 'S ', size: 10, type: 'I', dec: '0' }), 'D_SPEC_EXT_DESC_INVALID'],
  ['DSがcol22-23に誤配置',         '     D mapArr        DS                    DIM(4096)', 'D_SPEC_DECL_TYPE_MISPLACED'],
];

const o = new Orchestrator();
const rules = ['D_SPEC_NAME_OVERFLOW', 'D_SPEC_EXT_DESC_INVALID', 'D_SPEC_DS_TYPE_INVALID', 'D_SPEC_DECL_TYPE_MISPLACED'];
let ng = 0;
for (const [desc, line, expect] of cases) {
  const r = o.checkCode(line, 'standard');
  const hits = r.issues.filter(i => rules.includes(i.rule)).map(i => i.rule);
  const ok = expect ? (hits.length === 1 && hits[0] === expect) : hits.length === 0;
  if (!ok) ng++;
  console.log(`${ok ? 'OK' : 'NG'} ${desc}: [${hits.join(',')}] (期待: ${expect ?? 'なし'}) col22='${line[21] ?? ''}' col23='${line[22] ?? ''}' col24-25='${line.substring(23, 25)}'`);
}
console.log(ng === 0 ? 'ALL OK' : `${ng} NG`);
