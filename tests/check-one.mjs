// 単一ソースをチェックして error/warning 件数を表示する補助ツール。
// 使い方: node tests/check-one.mjs <path-to-source>
// build/ はモジュール位置基準で解決するので cwd 非依存。
import { Orchestrator } from '../build/orchestrator.js';
import fs from 'fs';

const file = process.argv[2];
if (!file) {
  console.error('usage: node tests/check-one.mjs <path-to-source>');
  process.exit(2);
}

const content = fs.readFileSync(file, 'utf-8');
const lineCount = content.split(/\r?\n/).length;
const orchestrator = new Orchestrator({ language: 'ja', considerDBCS: true });
const result = orchestrator.checkCode(content, 'standard', file);

const errors = result.issues.filter(i => i.severity === 'error');
const warnings = result.issues.filter(i => i.severity === 'warning');

console.log(`${file}: ${lineCount} lines, ${errors.length} errors, ${warnings.length} warnings`);
for (const e of errors) {
  console.log(`  ERROR L${e.line}: [${e.rule || 'unknown'}] ${e.message}`);
}
for (const w of warnings) {
  console.log(`  WARN  L${w.line}: [${w.rule || 'unknown'}] ${w.message}`);
}

process.exit(errors.length > 0 ? 1 : 0);
