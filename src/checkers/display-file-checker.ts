/**
 * ILE-RPG Coding Standards Checker - Display File Checker
 * DSPF/DDSのA仕様書を対象に、位置指定・重なり・WINDOWレコードのチェックを行う
 */

import { ParsedLine, Issue, CheckLevel, Checker } from '../types/index.js';
import { DBCSHelper } from '../utils/dbcs-helper.js';

interface DisplayFieldInfo {
  line: ParsedLine;
  fieldName?: string;
  isRecordFormat: boolean;
  row?: number;
  column?: number;
  length?: number;
  endColumn?: number;
  hasWindow: boolean;
  hasOverlay: boolean;
  hasIndicatorControl?: boolean;
  dbcsAnalysis?: {
    byteLength: number;
    dbcsCount: number;
    shiftCharacters: number;
  };
}

export class DisplayFileChecker implements Checker {
  name = 'DisplayFileChecker';
  private considerDBCS: boolean;

  constructor(considerDBCS: boolean = false) {
    this.considerDBCS = considerDBCS;
  }

  check(lines: ParsedLine[], checkLevel: CheckLevel): Issue[] {
    const issues: Issue[] = [];
    const dspfLines = lines.filter(line => line.specificationType === 'A' && !line.isComment);
    if (dspfLines.length === 0) return issues;

    issues.push(...this.checkDSPFFieldDefinitions(dspfLines));
    issues.push(...this.checkDSPFWindowStyles(dspfLines));
    issues.push(...this.checkDSPFDBCSPositionShift(dspfLines));

    // 追加チェック: PSHBTN間隔、スクロールバー余白、フィールドのはみ出し
    issues.push(...this.checkPSHBTNSpacing(dspfLines));
    issues.push(...this.checkScrollbarMargins(dspfLines));
    issues.push(...this.checkFieldOverflow(dspfLines));

    return issues;
  }

  private checkDSPFFieldDefinitions(lines: ParsedLine[]): Issue[] {
    const issues: Issue[] = [];

    // DSPFは1ファイルに複数の独立したレコード様式(R)を持ち、別々のタイミングで
    // 表示される。異なるレコード様式のフィールドは同時に表示されないため、重なり
    // 判定はレコード様式単位で行う必要がある。ソース順に走査して様式ごとに分離する。
    let currentRecord = '(GLOBAL)';
    const recordFields = new Map<string, DisplayFieldInfo[]>();

    for (const line of lines) {
      const info = this.parseDisplayFieldInfo(line);
      if (!info) continue;
      if (info.isRecordFormat) {
        currentRecord = info.fieldName ?? `REC@${line.lineNumber}`;
        continue;
      }
      // 長さが明示されている名前付きフィールドのみを重なり判定対象にする。
      // 定数（リテラル）はDBCS表示幅などの不確定要素が大きく、誤検出の原因となる
      // ため対象外とする（真の重なりはCRTDSPFのCPD7866で検出する想定）。
      if (info.row === undefined || info.column === undefined || info.length === undefined) continue;
      if (!recordFields.has(currentRecord)) recordFields.set(currentRecord, []);
      recordFields.get(currentRecord)!.push(info);
    }

    for (const fields of recordFields.values()) {
      const groupedByRow = new Map<number, DisplayFieldInfo[]>();
      for (const info of fields) {
        const row = info.row!;
        if (!groupedByRow.has(row)) groupedByRow.set(row, []);
        groupedByRow.get(row)!.push(info);
      }

      for (const [row, rowFields] of groupedByRow.entries()) {
        rowFields.sort((a, b) => (a.column! - b.column!));
        for (let i = 0; i < rowFields.length - 1; i++) {
          const current = rowFields[i];
          const next = rowFields[i + 1];
          // 標識で条件付けされているフィールドは重なり判定から除外する
          if (current.hasIndicatorControl || next.hasIndicatorControl) continue;
          if (next.column! <= current.endColumn!) {
            const message = `DSPFフィールドが同一行(${row})で重なっています。` +
              ` '${current.fieldName ?? '(無名)'}' (col${current.column}-${current.endColumn}) と ` +
              `'${next.fieldName ?? '(無名)'}' (col${next.column}-${next.endColumn}) が重複します。`;
            issues.push({
              severity: 'error',
              category: 'structure',
              line: next.line.lineNumber,
              column: next.column,
              message,
              rule: 'DSPF_FIELD_OVERLAP',
              ruleDescription: '同一レコード様式・同一表示行内で列の重なりがあると、DSPFの表示フィールドが競合し、意図しない表示結果になる可能性があります。',
              suggestion: 'ROW/COL/LENGTHの値を見直し、重複が発生しないように調整してください。',
              codeSnippet: next.line.rawContent
            });
          }
        }
      }
    }

    return issues;
  }

  private checkDSPFWindowStyles(lines: ParsedLine[]): Issue[] {
    const issues: Issue[] = [];
    const windowLines = lines.filter(line => this.isWindowLine(line));
    const recordFormats = lines.filter(line => this.isRecordFormat(line));
    // OVERLAYはパラメータなしの単独形（OVERLAY）も有効なため、括弧の有無を問わず検出する。
    const overlayLines = lines.filter(line => /\bOVERLAY\b/i.test(line.rawContent));

    if (windowLines.length > 0 && recordFormats.length === 0) {
      issues.push({
        severity: 'error',
        category: 'structure',
        line: windowLines[0].lineNumber,
        column: 7,
        message: 'WINDOW指定がありますが、DSPFのレコードフォーマット(R)が見つかりません。',
        rule: 'DSPF_WINDOW_NO_RECORD_FORMAT',
        ruleDescription: 'WINDOWを使用するDSPFには専用のレコードフォーマット定義が必要になる場合があります。',
        suggestion: 'WINDOWを含むレコードに対応するレコードフォーマット行を追加してください。',
        codeSnippet: windowLines[0].rawContent
      });
    }

    // WINDOW定義（数値パラメータで枠を定義する形式）はウィンドウそのものの定義であり
    // OVERLAYを必須としない。*NOMSGLINや専用レコード様式を伴う正当なパターンも多いため、
    // OVERLAY要否の警告はWINDOW参照（WINDOW(*DFT)/WINDOW(レコード名)等）に限定する。
    const referenceWindows = windowLines.filter(line => !this.isWindowDefinition(line));
    if (referenceWindows.length > 0 && overlayLines.length === 0) {
      const target = referenceWindows[0];
      issues.push({
        severity: 'warning',
        category: 'structure',
        line: target.lineNumber,
        column: target.rawContent.toUpperCase().indexOf('WINDOW') + 1,
        message: 'WINDOW参照がありますが、OVERLAY指定が見つかりません。ウィンドウを参照するレコードではOVERLAYが必要になる場合があります。',
        rule: 'DSPF_WINDOW_WITHOUT_OVERLAY',
        ruleDescription: 'WINDOW(*DFT)やWINDOW(レコード名)でウィンドウを参照する場合、OVERLAYや専用のウィンドウレコード形式を組み合わせることが多いです。WINDOW定義行（数値パラメータ）はOVERLAY不要です。',
        suggestion: 'ウィンドウを参照するレコードに適切なOVERLAYを追加してください。WINDOW定義行であればこの警告は無視できます。',
        codeSnippet: target.rawContent
      });
    }

    return issues;
  }

  private checkDSPFDBCSPositionShift(lines: ParsedLine[]): Issue[] {
    if (!this.considerDBCS) return [];

    const issues: Issue[] = [];
    for (const line of lines) {
      const info = this.parseDisplayFieldInfo(line);
      if (!info || info.isRecordFormat) continue;
      if (info.row === undefined || info.column === undefined) continue;

      // DBCS文字が機能（キーワード）領域（桁45以降）の定数リテラル内にあるだけの場合、
      // 表示行・列は固定桁（桁39-44）で明示されており位置はずれない。SO/SIはコンパイル時に
      // 処理され実機表示にも影響しないため、警告しない（実DSPFで大量の誤検出となるため）。
      // 桁ずれの実害があるのは固定桁領域（桁1-44）にDBCS文字が混入している異常時のみ。
      const fixedArea = line.rawContent.substring(0, Math.min(44, line.rawContent.length));
      if (!DBCSHelper.containsDBCS(fixedArea)) continue;

      const byteLength = DBCSHelper.calculateByteLength(line.rawContent);
      const shiftedBytes = byteLength - line.rawContent.length;
      if (shiftedBytes <= 0) continue;

      issues.push({
        severity: 'warning',
        category: 'structure',
        line: line.lineNumber,
        column: 7,
        message: `DSPF行の固定桁領域（桁1-44）にDBCS文字が含まれているため、EBCDIC変換後にROW/COL位置がずれる可能性があります。実際のバイト長は${byteLength}バイトです。`,
        rule: 'DSPF_DBCS_POSITION_SHIFT',
        ruleDescription: 'DSPFソースの固定桁領域内のDBCS文字はEBCDIC 5035変換後にSO/SIフレームを含むため、固定位置指定がずれる可能性があります。桁45以降の定数リテラル内のDBCSは位置に影響しません。',
        suggestion: 'フィールド名や位置指定の桁にDBCS文字が混入していないか確認してください。',
        codeSnippet: line.rawContent
      });
    }

    return issues;
  }

  private parseDisplayFieldInfo(line: ParsedLine): DisplayFieldInfo | null {
    if (!line.columnData) return null;
    const cd = line.columnData as any;
    const raw = line.rawContent;
    const keywords: string = cd.keywords ?? '';
    const isRecordFormat = this.isRecordFormat(line);
    const hasWindow = this.isWindowLine(line);
    const hasOverlay = /\bOVERLAY\b/i.test(raw);

    // 条件付け（標識）領域（桁7-16）に標識指定があるフィールドは、表示が
    // 条件付きであり同時に表示されない可能性があるため、重なり判定から除外する。
    const conditioning: string = cd.conditioning ?? '';
    const hasIndicatorControl = /\d/.test(conditioning) ||
      /\*IN\d{2}/i.test(keywords) || /\bIND\s*\(/i.test(keywords) || /\bINDICATOR\b/i.test(keywords);

    // 固定桁（DDS 表示装置ファイル）から行・列・長さを取得する。
    let row = this.toInt(cd.row);
    let column = this.toInt(cd.column);
    let length = this.toInt(cd.length);

    // 一部のDDSではキーワードでPOSITION()/ROW()/COL()/LENGTH()を指定する場合があるため補完する。
    const positionMatch = /\bPOSITION\s*\(\s*(\d+)(?:\s*,\s*(\d+))?\s*\)/i.exec(keywords);
    if (positionMatch) {
      if (row === undefined) row = parseInt(positionMatch[1], 10);
      if (positionMatch[2] && column === undefined) column = parseInt(positionMatch[2], 10);
    }
    const rowMatch = /\bROW\s*\(\s*(\d+)\s*\)/i.exec(keywords);
    if (rowMatch && row === undefined) row = parseInt(rowMatch[1], 10);
    const colMatch = /\bCOL(?:UMN)?\s*\(\s*(\d+)\s*\)/i.exec(keywords);
    if (colMatch && column === undefined) column = parseInt(colMatch[1], 10);
    const lengthMatch = /\bLEN(?:GTH)?\s*\(\s*(\d+)\s*\)/i.exec(keywords);
    if (lengthMatch && length === undefined) length = parseInt(lengthMatch[1], 10);

    const endColumn = column !== undefined && length !== undefined
      ? column + length - 1
      : undefined;

    const dbcsAnalysis = this.considerDBCS && DBCSHelper.containsDBCS(raw)
      ? DBCSHelper.analyzeString(raw)
      : undefined;

    return {
      line,
      fieldName: line.columnData.name,
      isRecordFormat,
      row,
      column,
      length,
      endColumn,
      hasWindow,
      hasOverlay,
      hasIndicatorControl,
      dbcsAnalysis: dbcsAnalysis ? {
        byteLength: DBCSHelper.calculateByteLength(raw),
        dbcsCount: dbcsAnalysis.dbcsCount,
        shiftCharacters: dbcsAnalysis.shiftCharacters
      } : undefined
    };
  }

  private isRecordFormat(line: ParsedLine): boolean {
    // DDS 表示装置ファイルでは桁17(idx16)が'R'ならレコード様式定義。
    return line.rawContent.length >= 17 && line.rawContent[16].toUpperCase() === 'R';
  }

  private isWindowLine(line: ParsedLine): boolean {
    return /WINDOW\b/i.test(line.rawContent);
  }

  /**
   * WINDOW定義行かどうか（WINDOW(行 列 高さ 幅 ...) のように数値で枠を定義する形式）。
   * 数値パラメータで枠を定義するWINDOWはウィンドウそのものの定義であり、
   * OVERLAY指定を必須としない。
   */
  private isWindowDefinition(line: ParsedLine): boolean {
    return /WINDOW\s*\(\s*[*]?\s*\d/i.test(line.rawContent);
  }

  private toInt(value: string | undefined): number | undefined {
    if (value === undefined) return undefined;
    const n = parseInt(value, 10);
    return Number.isNaN(n) ? undefined : n;
  }

  private checkPSHBTNSpacing(lines: ParsedLine[]): Issue[] {
    const issues: Issue[] = [];
    const fieldInfos = lines.map(l => this.parseDisplayFieldInfo(l)).filter(Boolean) as DisplayFieldInfo[];
    const fieldsWithPositions = fieldInfos.filter(f => !f.isRecordFormat && f.row !== undefined && f.column !== undefined && f.endColumn !== undefined);

    const grouped = new Map<number, DisplayFieldInfo[]>();
    for (const f of fieldsWithPositions) {
      const r = f.row!;
      if (!grouped.has(r)) grouped.set(r, []);
      grouped.get(r)!.push(f);
    }

    const minGap = 2; // ボタン間の最小間隔（列）
    for (const [row, arr] of grouped.entries()) {
      const buttons = arr.filter(f => /PSHBTN\b|PUSHBUTTON\b/i.test(f.line.rawContent));
      if (buttons.length <= 1) continue;
      buttons.sort((a, b) => (a.column! - b.column!));
      for (let i = 0; i < buttons.length - 1; i++) {
        const cur = buttons[i];
        const next = buttons[i + 1];
        const gap = next.column! - cur.endColumn! - 1;
        if (gap < minGap) {
          issues.push({
            severity: 'warning',
            category: 'structure',
            line: next.line.lineNumber,
            column: next.column,
            message: `PSHBTN（プッシュボタン）が同一行で近接しすぎています（間隔=${gap}列、最小推奨=${minGap}列）。`,
            rule: 'DSPF_PSHBTN_TOO_NARROW',
            ruleDescription: 'プッシュボタン間は少なくとも数列の間隔を空けることが望ましいです。',
            suggestion: `ボタン間のCOL値を調整して、最低${minGap}列の余白を確保してください。`,
            codeSnippet: next.line.rawContent
          });
        }
      }
    }

    return issues;
  }

  private checkScrollbarMargins(lines: ParsedLine[]): Issue[] {
    const issues: Issue[] = [];
    const fieldInfos = lines.map(l => this.parseDisplayFieldInfo(l)).filter(Boolean) as DisplayFieldInfo[];
    const fieldsWithPositions = fieldInfos.filter(f => !f.isRecordFormat && f.row !== undefined && f.column !== undefined && f.endColumn !== undefined);

    const grouped = new Map<number, DisplayFieldInfo[]>();
    for (const f of fieldsWithPositions) {
      const r = f.row!;
      if (!grouped.has(r)) grouped.set(r, []);
      grouped.get(r)!.push(f);
    }

    const margin = 1; // スクロールバーの前後に必要な最小空白
    for (const [row, arr] of grouped.entries()) {
      const scrolls = arr.filter(f => /SCROLL\b|SCROLLBAR\b/i.test(f.line.rawContent));
      if (scrolls.length === 0) continue;
      for (const s of scrolls) {
        // エッジからの余白
        if (s.column! <= margin) {
          issues.push({
            severity: 'warning',
            category: 'structure',
            line: s.line.lineNumber,
            column: s.column,
            message: `スクロールバーの左側に余白がありません（col=${s.column}）。少なくとも${margin}列の余白を推奨します。`,
            rule: 'DSPF_SCROLLBAR_NO_LEFT_MARGIN',
            suggestion: `スクロールバーの左に最低${margin}列の余白を確保してください。`,
            codeSnippet: s.line.rawContent
          });
        }
        if (s.endColumn! >= 80 - margin) {
          issues.push({
            severity: 'warning',
            category: 'structure',
            line: s.line.lineNumber,
            column: s.column,
            message: `スクロールバーの右側に余白がありません（endCol=${s.endColumn}）。少なくとも${margin}列の余白を推奨します。`,
            rule: 'DSPF_SCROLLBAR_NO_RIGHT_MARGIN',
            suggestion: `スクロールバーの右に最低${margin}列の余白を確保してください。`,
            codeSnippet: s.line.rawContent
          });
        }

        // 近接フィールドチェック
        for (const other of arr) {
          if (other === s) continue;
          if (other.column! > s.endColumn!) {
            const gap = other.column! - s.endColumn! - 1;
            if (gap < margin) {
              issues.push({
                severity: 'warning',
                category: 'structure',
                line: other.line.lineNumber,
                column: other.column,
                message: `スクロールバーの隣接フィールドに十分な余白がありません（間隔=${gap}列、推奨=${margin}列）。`,
                rule: 'DSPF_SCROLLBAR_NEAR_FIELD',
                suggestion: `スクロールバーとフィールドの間に最低${margin}列の余白を設けてください。`,
                codeSnippet: other.line.rawContent
              });
            }
          } else if (other.endColumn! < s.column!) {
            const gap = s.column! - other.endColumn! - 1;
            if (gap < margin) {
              issues.push({
                severity: 'warning',
                category: 'structure',
                line: other.line.lineNumber,
                column: other.column,
                message: `スクロールバーの隣接フィールドに十分な余白がありません（間隔=${gap}列、推奨=${margin}列）。`,
                rule: 'DSPF_SCROLLBAR_NEAR_FIELD',
                suggestion: `スクロールバーとフィールドの間に最低${margin}列の余白を設けてください。`,
                codeSnippet: other.line.rawContent
              });
            }
          }
        }
      }
    }

    return issues;
  }

  private checkFieldOverflow(lines: ParsedLine[]): Issue[] {
    const issues: Issue[] = [];
    const fieldInfos = lines.map(l => this.parseDisplayFieldInfo(l)).filter(Boolean) as DisplayFieldInfo[];

    for (const f of fieldInfos) {
      if (f.isRecordFormat) continue;
      // CNTFLD（連続フィールド）は指定幅で複数表示行に折り返す連続入力フィールドであり、
      // 論理長（LENGTH）が80桁を超えても表示は折り返されるため正常。行幅超過チェックから除外する。
      // 固定桁では列桁の数字とキーワードが密着する（例: "16CNTFLD"）ため、先頭の\bは付けない。
      const isContinuedField = /CNTFLD\s*\(/i.test(f.line.rawContent);
      if (!isContinuedField && f.endColumn !== undefined && f.endColumn > 80) {
        issues.push({
          severity: 'error',
          category: 'structure',
          line: f.line.lineNumber,
          column: f.column,
          message: `フィールドが行幅(80)を超えてはみ出しています（endCol=${f.endColumn}）。`,
          rule: 'DSPF_FIELD_OVERFLOW_LINE',
          ruleDescription: 'フィールドやリテラルが設定された列数を超えると、表示が次行に流れたり切れる可能性があります。',
          suggestion: 'LENGTHやCOLを見直し、80列以内に収めてください。CNTFLD（連続フィールド）の場合はこの限りではありません。',
          codeSnippet: f.line.rawContent
        });
      }

      // 行自体が80文字を超えている場合も警告（リテラル等のはみ出し）
      if (f.line.rawContent.length > 80) {
        issues.push({
          severity: 'warning',
          category: 'structure',
          line: f.line.lineNumber,
          column: 81,
          message: '行が80桁を超えています。フィールドやリテラルが次行にはみ出している可能性があります。',
          rule: 'DSPF_LINE_TOO_LONG',
          suggestion: '行を80桁以内に収めるか、表示位置を調整してください。',
          codeSnippet: f.line.rawContent
        });
      }
    }

    return issues;
  }
}
