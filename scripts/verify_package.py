#!/usr/bin/env python3
"""
================================================================================
ENGINEERING MATHEMATICS TEACHING PACKAGE — SYNTAX & STRUCTURE AUDITOR
================================================================================
Zero-Proprietary-Dependency Verification Harness for MATLAB Courseware:
1. DirectoryStructureValidator: Manifest, layout hierarchy, file size thresholds
2. MarkdownLinkValidator: Relative links, image links, and heading slug anchors
3. MatlabSyntaxAuditor: Context-aware lexer (transpose vs strings), block balancing,
   delimiter balancing, 0-based indexing detection, comment ratio audit
4. ExerciseTierAuditor: 4-tier pedagogical progression & decoupled solutions audit
5. DatasetCapstoneValidator: CSV schema consistency, numeric validation, capstone assets
================================================================================
"""

import argparse
import csv
from dataclasses import dataclass, field
from enum import Enum
import json
import os
from pathlib import Path
import re
import sys
from typing import Any, Dict, List, Optional, Set, Tuple


# ==============================================================================
# DIAGNOSTIC DATA MODELS
# ==============================================================================

class Severity(Enum):
    INFO = "INFO"
    WARNING = "WARN"
    ERROR = "ERROR"


@dataclass
class Diagnostic:
    validator: str
    severity: Severity
    file_path: Path
    line_number: Optional[int] = None
    column_number: Optional[int] = None
    message: str = ""
    remediation: str = ""
    snippet: Optional[str] = None

    def to_dict(self) -> Dict[str, Any]:
        return {
            "validator": self.validator,
            "severity": self.severity.value,
            "file_path": str(self.file_path),
            "line_number": self.line_number,
            "column_number": self.column_number,
            "message": self.message,
            "remediation": self.remediation,
            "snippet": self.snippet,
        }


@dataclass
class AuditReport:
    total_checks: int = 0
    passed_checks: int = 0
    warning_count: int = 0
    error_count: int = 0
    diagnostics: List[Diagnostic] = field(default_factory=list)

    def add_diagnostic(self, diag: Diagnostic) -> None:
        self.diagnostics.append(diag)
        if diag.severity == Severity.ERROR:
            self.error_count += 1
        elif diag.severity == Severity.WARNING:
            self.warning_count += 1

    @property
    def is_success(self) -> bool:
        return self.error_count == 0


# ==============================================================================
# VALIDATOR 1: DIRECTORY STRUCTURE & MANIFEST VALIDATOR
# ==============================================================================

class DirectoryStructureValidator:
    """Validates existence, hierarchy, and minimum size of all curriculum modules."""

    REQUIRED_MODULES = [
        "matlab",
        "linear_algebra",
        "calculus",
        "probability",
        "simulink",
        "capstone",
        "ml_bridge",
        "assessments",
        "reference",
        "solutions",
        "scripts",
        "tests",
    ]

    REQUIRED_FILES: Dict[str, int] = {
        "README.md": 1000,
        "requirements.txt": 40,
        "matlab/README.md": 1500,
        "matlab/exercises.m": 200,
        "linear_algebra/README.md": 1500,
        "linear_algebra/exercises.m": 200,
        "calculus/README.md": 1500,
        "calculus/exercises.m": 200,
        "probability/README.md": 1500,
        "probability/exercises.m": 200,
        "simulink/README.md": 1500,
        "simulink/exercises.m": 200,
        "capstone/README.md": 1500,
        "ml_bridge/README.md": 1200,
        "assessments/FINAL_ASSESSMENT.md": 2500,
        "assessments/RUBRIC.md": 800,
    }

    # Alternative acceptable paths for specific required components
    ALTERNATIVE_FILES: Dict[str, List[str]] = {
        "reference/matlab_cheat_sheet.md": [
            "reference/matlab_cheatsheet.md",
            "reference/matlab_cheat_sheet.md",
        ],
        "reference/linear_algebra_cheat_sheet.md": [
            "reference/linear_algebra_cheatsheet.md",
            "reference/linear_algebra_cheat_sheet.md",
        ],
        "reference/calculus_cheat_sheet.md": [
            "reference/calculus_cheatsheet.md",
            "reference/calculus_cheat_sheet.md",
        ],
        "reference/probability_cheat_sheet.md": [
            "reference/probability_cheatsheet.md",
            "reference/probability_cheat_sheet.md",
        ],
        "telemetry_dataset": [
            "data/ev_telemetry.csv",
            "capstone/data/ev_telemetry.csv",
            "capstone/data/industrial_telemetry.csv",
            "datasets/industrial_telemetry.csv",
        ],
        "capstone_template": [
            "capstone/capstone_analysis_template.m",
            "capstone/starter_template.m",
        ],
        "capstone_solution": [
            "capstone/capstone_analysis_complete.m",
            "capstone/capstone_solution.m",
            "solutions/capstone_solution.m",
        ],
    }

    def __init__(self, root_dir: Path, report: AuditReport, target_module: Optional[str] = None):
        self.root_dir = root_dir.resolve()
        self.report = report
        self.target_module = target_module

    def validate(self) -> None:
        self.report.total_checks += 1
        if not self.root_dir.exists() or not self.root_dir.is_dir():
            self.report.add_diagnostic(Diagnostic(
                validator="DirectoryStructure",
                severity=Severity.ERROR,
                file_path=self.root_dir,
                message=f"Target package directory '{self.root_dir}' does not exist.",
                remediation="Ensure project directory is initialized properly."
            ))
            return
        self.report.passed_checks += 1

        # 1. Module directory checks
        modules_to_check = [self.target_module] if self.target_module else self.REQUIRED_MODULES
        for mod in modules_to_check:
            self.report.total_checks += 1
            mod_path = self.root_dir / mod
            if not mod_path.exists() or not mod_path.is_dir():
                self.report.add_diagnostic(Diagnostic(
                    validator="DirectoryStructure",
                    severity=Severity.ERROR,
                    file_path=mod_path,
                    message=f"Mandatory module directory '{mod}/' is missing.",
                    remediation=f"Create directory '{mod}/' with required curriculum artifacts."
                ))
            else:
                self.report.passed_checks += 1

        # Dataset directory check (data/ or datasets/)
        if not self.target_module or self.target_module in ("data", "datasets", "capstone"):
            self.report.total_checks += 1
            data_dir_1 = self.root_dir / "data"
            data_dir_2 = self.root_dir / "datasets"
            data_dir_3 = self.root_dir / "capstone" / "data"
            if not (data_dir_1.exists() or data_dir_2.exists() or data_dir_3.exists()):
                self.report.add_diagnostic(Diagnostic(
                    validator="DirectoryStructure",
                    severity=Severity.ERROR,
                    file_path=data_dir_1,
                    message="Mandatory dataset directory ('data/' or 'datasets/') is missing.",
                    remediation="Create 'data/' with telemetry datasets and schema."
                ))
            else:
                self.report.passed_checks += 1

        # 2. Required files checks
        for rel_path_str, min_size in self.REQUIRED_FILES.items():
            if self.target_module and not rel_path_str.startswith(f"{self.target_module}/"):
                continue

            self.report.total_checks += 1
            file_path = self.root_dir / rel_path_str
            if not file_path.exists():
                self.report.add_diagnostic(Diagnostic(
                    validator="DirectoryStructure",
                    severity=Severity.ERROR,
                    file_path=file_path,
                    message=f"Mandatory file '{rel_path_str}' is missing.",
                    remediation=f"Create '{rel_path_str}' conforming to curriculum specifications."
                ))
            else:
                size = file_path.stat().st_size
                if size == 0:
                    self.report.add_diagnostic(Diagnostic(
                        validator="DirectoryStructure",
                        severity=Severity.ERROR,
                        file_path=file_path,
                        message=f"File '{rel_path_str}' is empty (0 bytes).",
                        remediation="Populate file with authentic pedagogical or code content."
                    ))
                elif size < min_size:
                    self.report.add_diagnostic(Diagnostic(
                        validator="DirectoryStructure",
                        severity=Severity.WARNING,
                        file_path=file_path,
                        message=f"File '{rel_path_str}' size ({size} B) is below threshold ({min_size} B).",
                        remediation="Expand file to meet comprehensive pedagogical requirements."
                    ))
                else:
                    self.report.passed_checks += 1

        # 3. Check alternative-path files (cheat sheets, capstone files, telemetry)
        for label, candidate_paths in self.ALTERNATIVE_FILES.items():
            if self.target_module and not any(cand.startswith(f"{self.target_module}/") for cand in candidate_paths):
                continue
            self.report.total_checks += 1
            found = False
            for cand in candidate_paths:
                p = self.root_dir / cand
                if p.exists() and p.stat().st_size > 0:
                    found = True
                    break
            if not found:
                self.report.add_diagnostic(Diagnostic(
                    validator="DirectoryStructure",
                    severity=Severity.ERROR,
                    file_path=self.root_dir / candidate_paths[0],
                    message=f"Mandatory resource '{label}' missing (checked: {', '.join(candidate_paths)}).",
                    remediation=f"Create one of the candidate files: {', '.join(candidate_paths)}."
                ))
            else:
                self.report.passed_checks += 1


# ==============================================================================
# VALIDATOR 2: MARKDOWN CROSS-REFERENCE & LINK VALIDATOR
# ==============================================================================

class MarkdownLinkValidator:
    """Validates all relative links and section anchor slugs across Markdown files."""

    LINK_REGEX = re.compile(r'(?<!\!)\[([^\]]+)\]\(([^)]+)\)')
    IMG_REGEX = re.compile(r'!\[([^\]]*)\]\(([^)]+)\)')
    HEADING_REGEX = re.compile(r'^(#{1,6})\s+(.+)$', re.MULTILINE)

    def __init__(self, root_dir: Path, report: AuditReport, target_module: Optional[str] = None):
        self.root_dir = root_dir.resolve()
        self.report = report
        self.target_module = target_module
        self.heading_slug_cache: Dict[Path, Set[str]] = {}

    @staticmethod
    def slugify(heading_text: str) -> str:
        """Convert a markdown heading into a GitHub/CommonMark slug."""
        # Strip trailing formatting, markdown links, codes
        clean = re.sub(r'\[([^\]]+)\]\([^)]+\)', r'\1', heading_text)
        clean = re.sub(r'[`*_~]', '', clean)
        # Convert non-alphanumeric chars (except hyphens and spaces)
        clean = re.sub(r'[^\w\s-]', '', clean.strip().lower())
        # Replace whitespace and repeated hyphens with a single hyphen
        return re.sub(r'[-\s]+', '-', clean).strip('-')

    def get_heading_slugs(self, file_path: Path) -> Set[str]:
        if file_path in self.heading_slug_cache:
            return self.heading_slug_cache[file_path]

        slugs: Set[str] = set()
        if file_path.exists() and file_path.is_file():
            try:
                content = file_path.read_text(encoding='utf-8')
                for match in self.HEADING_REGEX.finditer(content):
                    heading_text = match.group(2).strip()
                    slugs.add(self.slugify(heading_text))
                    # Also accept raw lowercase alphanumeric representation
                    simple_slug = re.sub(r'[^a-z0-9]', '', heading_text.lower())
                    if simple_slug:
                        slugs.add(simple_slug)
            except Exception:
                pass
        self.heading_slug_cache[file_path] = slugs
        return slugs

    def validate_file(self, md_file: Path) -> None:
        try:
            content = md_file.read_text(encoding='utf-8')
        except Exception as e:
            self.report.add_diagnostic(Diagnostic(
                validator="MarkdownLinks",
                severity=Severity.ERROR,
                file_path=md_file,
                message=f"Failed to read Markdown file: {e}",
                remediation="Ensure file is valid UTF-8 text."
            ))
            return

        lines = content.splitlines()
        for line_idx, line in enumerate(lines, start=1):
            # Combine standard links and image links
            links = list(self.LINK_REGEX.finditer(line)) + list(self.IMG_REGEX.finditer(line))
            for match in links:
                self.report.total_checks += 1
                raw_target = match.group(2).strip()

                # Ignore external URLs, mailto, javascript, or empty anchors
                if not raw_target or raw_target.startswith(("http://", "https://", "mailto:", "ftp://", "javascript:")):
                    self.report.passed_checks += 1
                    continue

                # Ignore template placeholders like [path] or (TODO)
                if raw_target in ("#", "TODO", "TBD"):
                    self.report.passed_checks += 1
                    continue

                # Separate file path and anchor
                if "#" in raw_target:
                    target_file_str, anchor = raw_target.split("#", 1)
                else:
                    target_file_str, anchor = raw_target, None

                # Clean query strings if any
                if "?" in target_file_str:
                    target_file_str = target_file_str.split("?", 1)[0]

                # Resolve target file
                if target_file_str:
                    # Support absolute-looking paths relative to root or relative to file
                    if target_file_str.startswith("/"):
                        target_path = (self.root_dir / target_file_str.lstrip("/")).resolve()
                    else:
                        target_path = (md_file.parent / target_file_str).resolve()
                else:
                    target_path = md_file

                if not target_path.exists():
                    self.report.add_diagnostic(Diagnostic(
                        validator="MarkdownLinks",
                        severity=Severity.ERROR,
                        file_path=md_file,
                        line_number=line_idx,
                        message=f"Broken relative link '{raw_target}': target '{target_path.name}' does not exist.",
                        remediation=f"Verify relative path from '{md_file.name}' to '{target_path}'.",
                        snippet=line.strip()
                    ))
                    continue

                # Anchor verification
                if anchor:
                    clean_anchor = anchor.strip().lower()
                    slugs = self.get_heading_slugs(target_path)
                    simple_anchor = re.sub(r'[^a-z0-9]', '', clean_anchor)
                    if clean_anchor not in slugs and simple_anchor not in slugs:
                        self.report.add_diagnostic(Diagnostic(
                            validator="MarkdownLinks",
                            severity=Severity.WARNING,
                            file_path=md_file,
                            line_number=line_idx,
                            message=f"Broken section anchor '#{anchor}' in '{target_path.name}'.",
                            remediation="Check target heading text and matching slug format.",
                            snippet=line.strip()
                        ))
                        continue

                self.report.passed_checks += 1

    def validate(self) -> None:
        search_dir = self.root_dir / self.target_module if self.target_module else self.root_dir
        if not search_dir.exists():
            return
        for md_file in search_dir.rglob("*.md"):
            # Skip agent logs or internal git files
            if ".git" in md_file.parts or ".agents" in md_file.parts:
                continue
            self.validate_file(md_file)


# ==============================================================================
# VALIDATOR 3: MATLAB SYNTAX & QUALITY AUDITOR
# ==============================================================================

class MatlabSyntaxAuditor:
    """Zero-dependency lexical analyzer, delimiter/block balancer, and semantic auditor."""

    MATLAB_KEYWORDS = {
        'function', 'end', 'for', 'parfor', 'while', 'if', 'elseif', 'else',
        'switch', 'case', 'otherwise', 'try', 'catch', 'return', 'break',
        'continue', 'global', 'persistent', 'classdef', 'properties', 'methods',
        'arguments', 'spmd'
    }

    BLOCK_OPENERS = {'function', 'for', 'parfor', 'while', 'if', 'switch', 'try', 'classdef', 'arguments', 'spmd'}
    DELIMITER_PAIRS = {'(': ')', '[': ']', '{': '}'}
    DELIMITER_CLOSERS = {')': '(', ']': '[', '}': '{'}

    # Built-in MATLAB functions where 0 or negative numbers are valid inputs/dimensions/coordinates
    BUILTIN_FUNCTIONS = {
        # Math & elementary functions
        'exp', 'log', 'log10', 'log2', 'sqrt', 'abs', 'sign', 'sin', 'cos', 'tan',
        'sind', 'cosd', 'tand', 'asind', 'acosd', 'atand', 'atan2d', 'cot', 'cotd',
        'sec', 'secd', 'csc', 'cscd',
        'asin', 'acos', 'atan', 'atan2', 'sinh', 'cosh', 'tanh', 'asinh', 'acosh', 'atanh',
        'sinc', 'erf', 'erfc', 'gamma', 'factorial', 'hypot', 'real', 'imag', 'angle', 'conj',
        # Linear algebra & matrix creation
        'zeros', 'ones', 'eye', 'rand', 'randn', 'randi', 'linspace', 'logspace',
        'diag', 'tril', 'triu', 'inv', 'pinv', 'det', 'rank', 'cond', 'rcond', 'trace',
        'norm', 'eig', 'eigs', 'svd', 'svds', 'lu', 'qr', 'chol', 'poly', 'polyval',
        'polyfit', 'roots', 'dot', 'cross', 'null', 'orth',
        # Graphics & plotting
        'plot', 'plot3', 'subplot', 'fplot', 'fplot3', 'quiver', 'quiver3', 'view',
        'stem', 'stem3', 'bar', 'barh', 'histogram', 'scatter', 'scatter3',
        'surf', 'surfc', 'mesh', 'meshc', 'contour', 'contourf', 'patch', 'line',
        'text', 'annotation', 'xlabel', 'ylabel', 'zlabel', 'title', 'legend',
        'grid', 'axis', 'xlim', 'ylim', 'zlim', 'colormap', 'colorbar',
        'hold', 'figure', 'clf', 'cla', 'close', 'shg',
        # Calculus, ODEs & Statistics
        'diff', 'gradient', 'del2', 'trapz', 'integral', 'integral2', 'integral3',
        'ode45', 'ode23', 'ode113', 'ode15s', 'ode23s', 'mean', 'median', 'std', 'var',
        'mode', 'cov', 'corrcoef', 'sum', 'prod', 'cumsum', 'cumprod', 'cumtrapz',
        'min', 'max', 'mod', 'rem', 'round', 'floor', 'ceil', 'fix', 'clamp',
        'repmat', 'reshape', 'circshift', 'flip', 'fliplr', 'flipud', 'rot90',
        'squeeze', 'permute', 'ipermute', 'size', 'length', 'numel', 'ndims',
        'find', 'sort', 'sortrows', 'unique', 'intersect', 'union', 'setdiff',
        'setxor', 'ismember', 'issorted',
        # I/O, Strings & System
        'disp', 'fprintf', 'sprintf', 'fscanf', 'sscanf', 'warning', 'error', 'assert',
        'pause', 'tic', 'toc', 'clear', 'clc', 'save', 'load', 'readtable', 'writetable',
        'readmatrix', 'writematrix', 'imread', 'imwrite', 'table', 'cell', 'struct',
        'string', 'char', 'double', 'single', 'int8', 'int16', 'int32', 'int64',
        'uint8', 'uint16', 'uint32', 'uint64', 'logical', 'isa', 'isnumeric',
        'isinteger', 'isfloat', 'islogical', 'ischar', 'isstring', 'iscell',
        'isstruct', 'istable', 'isempty', 'isnan', 'isinf', 'isfinite', 'isequal', 'isequaln'
    }

    def __init__(self, root_dir: Path, report: AuditReport, target_module: Optional[str] = None):
        self.root_dir = root_dir.resolve()
        self.report = report
        self.target_module = target_module

    def tokenize(self, code: str) -> List[Tuple[str, str, int, int]]:
        """
        Context-aware scanner that correctly distinguishes transpose (') from strings ('...').
        Returns list of (token_type, token_value, line, col).
        """
        pos = 0
        n = len(code)
        tokens: List[Tuple[str, str, int, int]] = []
        line = 1
        col = 1
        prev_token_type: Optional[str] = None

        while pos < n:
            c = code[pos]

            # 1. Newline
            if c == '\n':
                tokens.append(('NEWLINE', '\n', line, col))
                line += 1
                col = 1
                pos += 1
                continue

            # 2. Whitespace
            if c in ' \t\r':
                col += 1
                pos += 1
                continue

            # 3. Line continuation '...'
            if pos + 2 < n and code[pos:pos+3] == '...':
                start_col = col
                pos += 3
                col += 3
                # Line continuation consumes everything to the end of the line
                while pos < n and code[pos] != '\n':
                    pos += 1
                    col += 1
                tokens.append(('ELLIPSIS', '...', line, start_col))
                continue

            # 4. Block comment %{ ... %}
            # In MATLAB, %{ at start of line (after optional whitespace) begins a block comment
            if c == '%' and pos + 1 < n and code[pos+1] == '{':
                start_line, start_col = line, col
                pos += 2
                col += 2
                comment_buf = ['%{']
                closed = False
                while pos < n:
                    if code[pos] == '%' and pos + 1 < n and code[pos+1] == '}':
                        comment_buf.append('%}')
                        pos += 2
                        col += 2
                        closed = True
                        break
                    if code[pos] == '\n':
                        comment_buf.append('\n')
                        line += 1
                        col = 1
                    else:
                        comment_buf.append(code[pos])
                        col += 1
                    pos += 1
                tokens.append(('BLOCK_COMMENT', ''.join(comment_buf), start_line, start_col))
                continue

            # 5. Single-line comment %
            if c == '%':
                start_col = col
                comment_chars = []
                while pos < n and code[pos] != '\n':
                    comment_chars.append(code[pos])
                    pos += 1
                    col += 1
                tokens.append(('COMMENT', ''.join(comment_chars), line, start_col))
                continue

            # 6. Double-quoted string "..." (MATLAB 2016b+)
            if c == '"':
                start_col = col
                s_chars = ['"']
                pos += 1
                col += 1
                while pos < n:
                    if code[pos] == '"':
                        if pos + 1 < n and code[pos+1] == '"':
                            s_chars.append('""')
                            pos += 2
                            col += 2
                            continue
                        s_chars.append('"')
                        pos += 1
                        col += 1
                        break
                    if code[pos] == '\n':
                        break
                    s_chars.append(code[pos])
                    pos += 1
                    col += 1
                tokens.append(('STRING', ''.join(s_chars), line, start_col))
                prev_token_type = 'STRING'
                continue

            # 7. Non-conjugate array transpose operator (.')
            if c == '.' and pos + 1 < n and code[pos+1] == "'":
                tokens.append(('TRANSPOSE', ".'", line, col))
                prev_token_type = 'TRANSPOSE'
                pos += 2
                col += 2
                continue

            # 8. Single quote: Transpose (') vs Character Vector ('...')
            if c == "'":
                # In MATLAB, ' is a conjugate transpose operator if immediately preceded by an expression operand:
                # IDENT, NUMBER, CLOSE_PAREN, CLOSE_BRACKET, CLOSE_BRACE, TRANSPOSE, STRING, or CHAR_VEC
                if prev_token_type in (
                    'IDENT', 'NUMBER', 'CLOSE_PAREN', 'CLOSE_BRACKET',
                    'CLOSE_BRACE', 'TRANSPOSE', 'STRING', 'CHAR_VEC', 'KEYWORD_END'
                ):
                    tokens.append(('TRANSPOSE', "'", line, col))
                    prev_token_type = 'TRANSPOSE'
                    pos += 1
                    col += 1
                    continue
                else:
                    # Character vector literal: '...'
                    start_col = col
                    char_vec = ["'"]
                    pos += 1
                    col += 1
                    while pos < n:
                        if code[pos] == "'":
                            if pos + 1 < n and code[pos+1] == "'":
                                char_vec.append("''")
                                pos += 2
                                col += 2
                                continue
                            char_vec.append("'")
                            pos += 1
                            col += 1
                            break
                        if code[pos] == '\n':
                            break
                        char_vec.append(code[pos])
                        pos += 1
                        col += 1
                    tokens.append(('CHAR_VEC', ''.join(char_vec), line, start_col))
                    prev_token_type = 'CHAR_VEC'
                    continue

            # 9. Multi-character operators
            two_char = code[pos:pos+2]
            if two_char in ('.*', './', '.^', '.\\', '==', '~=', '<=', '>=', '&&', '||'):
                tokens.append(('OPERATOR', two_char, line, col))
                prev_token_type = 'OPERATOR'
                pos += 2
                col += 2
                continue

            # 10. Delimiters
            if c in '()[]{}':
                tag_map = {
                    '(': 'OPEN_PAREN', ')': 'CLOSE_PAREN',
                    '[': 'OPEN_BRACKET', ']': 'CLOSE_BRACKET',
                    '{': 'OPEN_BRACE', '}': 'CLOSE_BRACE'
                }
                tag = tag_map[c]
                tokens.append((tag, c, line, col))
                prev_token_type = tag
                pos += 1
                col += 1
                continue

            # 11. Identifiers and Keywords
            if c.isalpha() or c == '_':
                start_col = col
                ident_chars = []
                while pos < n and (code[pos].isalnum() or code[pos] == '_'):
                    ident_chars.append(code[pos])
                    pos += 1
                    col += 1
                ident = ''.join(ident_chars)
                if ident == 'end':
                    tokens.append(('KEYWORD_END', ident, line, start_col))
                    prev_token_type = 'KEYWORD_END'
                elif ident in self.MATLAB_KEYWORDS:
                    tokens.append(('KEYWORD', ident, line, start_col))
                    prev_token_type = 'KEYWORD'
                else:
                    tokens.append(('IDENT', ident, line, start_col))
                    prev_token_type = 'IDENT'
                continue

            # 12. Numbers
            if c.isdigit() or (c == '.' and pos + 1 < n and code[pos+1].isdigit()):
                start_col = col
                num_chars = []
                while pos < n and (code[pos].isalnum() or code[pos] in '.eE+-'):
                    if code[pos] in '+-' and (not num_chars or num_chars[-1] not in 'eE'):
                        break
                    num_chars.append(code[pos])
                    pos += 1
                    col += 1
                tokens.append(('NUMBER', ''.join(num_chars), line, start_col))
                prev_token_type = 'NUMBER'
                continue

            # 13. Other operators / punctuation
            tokens.append(('PUNCT', c, line, col))
            prev_token_type = 'PUNCT'
            pos += 1
            col += 1

        return tokens

    def audit_file(self, m_file: Path) -> None:
        try:
            content = m_file.read_text(encoding='utf-8')
        except Exception as e:
            self.report.add_diagnostic(Diagnostic(
                validator="MatlabSyntax",
                severity=Severity.ERROR,
                file_path=m_file,
                message=f"Could not read .m file: {e}",
                remediation="Ensure file is valid UTF-8."
            ))
            return

        tokens = self.tokenize(content)
        lines = content.splitlines()

        # ----------------------------------------------------------------------
        # 1. Delimiter & Block Balancing
        # ----------------------------------------------------------------------
        block_stack: List[Tuple[str, int, int]] = []
        delim_stack: List[Tuple[str, int, int]] = []
        paren_brace_depth = 0  # Tracks nesting inside () or {} for indexing

        for t_type, t_val, t_line, t_col in tokens:
            # Delimiters
            if t_type in ('OPEN_PAREN', 'OPEN_BRACE'):
                delim_stack.append((t_val, t_line, t_col))
                paren_brace_depth += 1
            elif t_type == 'OPEN_BRACKET':
                delim_stack.append((t_val, t_line, t_col))
            elif t_type in ('CLOSE_PAREN', 'CLOSE_BRACE'):
                if paren_brace_depth > 0:
                    paren_brace_depth -= 1
                expected_opener = self.DELIMITER_CLOSERS.get(t_val)
                if not delim_stack:
                    self.report.add_diagnostic(Diagnostic(
                        validator="MatlabSyntax",
                        severity=Severity.ERROR,
                        file_path=m_file,
                        line_number=t_line,
                        column_number=t_col,
                        message=f"Unmatched closing delimiter '{t_val}'.",
                        remediation="Check for mismatched parentheses or braces.",
                        snippet=lines[t_line - 1] if t_line <= len(lines) else None
                    ))
                else:
                    actual_opener, o_line, o_col = delim_stack.pop()
                    if actual_opener != expected_opener:
                        self.report.add_diagnostic(Diagnostic(
                            validator="MatlabSyntax",
                            severity=Severity.ERROR,
                            file_path=m_file,
                            line_number=t_line,
                            column_number=t_col,
                            message=f"Mismatched delimiter: expected '{self.DELIMITER_PAIRS[actual_opener]}' to match '{actual_opener}' from line {o_line}, got '{t_val}'.",
                            remediation="Ensure balanced pair of delimiters.",
                            snippet=lines[t_line - 1] if t_line <= len(lines) else None
                        ))
            elif t_type == 'CLOSE_BRACKET':
                if not delim_stack:
                    self.report.add_diagnostic(Diagnostic(
                        validator="MatlabSyntax",
                        severity=Severity.ERROR,
                        file_path=m_file,
                        line_number=t_line,
                        column_number=t_col,
                        message=f"Unmatched closing bracket ']'.",
                        remediation="Check for extraneous square brackets.",
                        snippet=lines[t_line - 1] if t_line <= len(lines) else None
                    ))
                else:
                    actual_opener, o_line, o_col = delim_stack.pop()
                    if actual_opener != '[':
                        self.report.add_diagnostic(Diagnostic(
                            validator="MatlabSyntax",
                            severity=Severity.ERROR,
                            file_path=m_file,
                            line_number=t_line,
                            column_number=t_col,
                            message=f"Mismatched delimiter: expected '{self.DELIMITER_PAIRS[actual_opener]}' from line {o_line}, got ']'.",
                            remediation="Ensure balanced square brackets.",
                            snippet=lines[t_line - 1] if t_line <= len(lines) else None
                        ))

            # Block Openers
            elif t_type == 'KEYWORD' and t_val in self.BLOCK_OPENERS:
                block_stack.append((t_val, t_line, t_col))

            # Block Closers ('end')
            elif t_type == 'KEYWORD_END':
                # Distinguish indexing 'end' (e.g. A(end) or x(1:end)) from block-closing 'end'
                # If inside parentheses () or curly braces {}, 'end' is an array index expression!
                if paren_brace_depth > 0:
                    continue

                if not block_stack:
                    self.report.add_diagnostic(Diagnostic(
                        validator="MatlabSyntax",
                        severity=Severity.ERROR,
                        file_path=m_file,
                        line_number=t_line,
                        column_number=t_col,
                        message="Dangling 'end' without matching block opener.",
                        remediation="Remove extraneous 'end' or add corresponding opener (if, for, while, etc.).",
                        snippet=lines[t_line - 1] if t_line <= len(lines) else None
                    ))
                else:
                    block_stack.pop()

        # Check for unclosed delimiters
        if delim_stack:
            unclosed_del, d_line, d_col = delim_stack[-1]
            self.report.add_diagnostic(Diagnostic(
                validator="MatlabSyntax",
                severity=Severity.ERROR,
                file_path=m_file,
                line_number=d_line,
                column_number=d_col,
                message=f"Unclosed delimiter '{unclosed_del}' opened at line {d_line}.",
                remediation=f"Add matching closing delimiter '{self.DELIMITER_PAIRS[unclosed_del]}'.",
                snippet=lines[d_line - 1] if d_line <= len(lines) else None
            ))

        # Check for unclosed blocks
        if block_stack:
            unclosed_op, u_line, u_col = block_stack[-1]
            self.report.add_diagnostic(Diagnostic(
                validator="MatlabSyntax",
                severity=Severity.ERROR,
                file_path=m_file,
                line_number=u_line,
                column_number=u_col,
                message=f"Unclosed '{unclosed_op}' block opened at line {u_line} (missing 'end').",
                remediation=f"Add 'end' statement to close '{unclosed_op}' block.",
                snippet=lines[u_line - 1] if u_line <= len(lines) else None
            ))

        # ----------------------------------------------------------------------
        # 2. Semantic Analysis: 0-based and negative indexing detection
        # ----------------------------------------------------------------------
        # Inspect token stream for: IDENT followed by OPEN_PAREN with 0 or negative index
        for idx in range(len(tokens) - 2):
            tok_ident = tokens[idx]
            tok_paren = tokens[idx + 1]
            tok_arg = tokens[idx + 2]

            if tok_ident[0] == 'IDENT' and tok_paren[0] == 'OPEN_PAREN':
                fn_name = tok_ident[1]
                if fn_name not in self.BUILTIN_FUNCTIONS:
                    # Check for literal 0 argument as first subscript: var(0...)
                    if tok_arg[0] == 'NUMBER' and tok_arg[1] in ('0', '0.0', '00'):
                        self.report.add_diagnostic(Diagnostic(
                            validator="MatlabSyntax",
                            severity=Severity.ERROR,
                            file_path=m_file,
                            line_number=tok_arg[2],
                            column_number=tok_arg[3],
                            message=f"Detected 0-based indexing attempt '{fn_name}(0)'. MATLAB indexing is strictly 1-based.",
                            remediation=f"Change index 0 to 1 or appropriate 1-based indexing expression in '{fn_name}'.",
                            snippet=lines[tok_arg[2] - 1] if tok_arg[2] <= len(lines) else None
                        ))
                    # Check for negative indexing: var(-1...)
                    elif tok_arg[0] == 'PUNCT' and tok_arg[1] == '-' and idx + 3 < len(tokens):
                        next_tok = tokens[idx + 3]
                        if next_tok[0] == 'NUMBER':
                            self.report.add_diagnostic(Diagnostic(
                                validator="MatlabSyntax",
                                severity=Severity.ERROR,
                                file_path=m_file,
                                line_number=tok_arg[2],
                                column_number=tok_arg[3],
                                message=f"Detected Python-style negative indexing '{fn_name}(-{next_tok[1]})'. In MATLAB use '{fn_name}(end)'.",
                                remediation="Use 'end' keyword for indexing from the end of an array.",
                                snippet=lines[tok_arg[2] - 1] if tok_arg[2] <= len(lines) else None
                            ))

        # ----------------------------------------------------------------------
        # 3. Engineering Comment Ratio Audit
        # ----------------------------------------------------------------------
        non_empty_lines = [l for l in lines if l.strip()]
        comment_lines = [l for l in lines if l.strip().startswith('%')]
        if len(non_empty_lines) > 10:
            ratio = len(comment_lines) / len(non_empty_lines)
            if ratio < 0.20:
                self.report.add_diagnostic(Diagnostic(
                    validator="MatlabSyntax",
                    severity=Severity.WARNING,
                    file_path=m_file,
                    message=f"Comment ratio ({ratio:.1%}) is below engineering threshold (>= 20%).",
                    remediation="Add comments explaining physical formulas, engineering intuition, and units."
                ))

        self.report.total_checks += 1
        self.report.passed_checks += 1

    def validate(self) -> None:
        search_dir = self.root_dir / self.target_module if self.target_module else self.root_dir
        if not search_dir.exists():
            return
        m_files = sorted(search_dir.rglob("*.m"))
        for m_file in m_files:
            if ".git" in m_file.parts or ".agents" in m_file.parts:
                continue
            self.audit_file(m_file)


# ==============================================================================
# VALIDATOR 4: 4-TIER PROGRESSIVE EXERCISE AUDITOR
# ==============================================================================

class ExerciseTierAuditor:
    """Validates 4-tier progressive exercise structure and decoupled solutions."""

    TIER_PATTERNS = [
        re.compile(r'%%\s*(Level|Tier)\s*1\s*:\s*Recall', re.IGNORECASE),
        re.compile(r'%%\s*(Level|Tier)\s*2\s*:\s*Understanding', re.IGNORECASE),
        re.compile(r'%%\s*(Level|Tier)\s*3\s*:\s*Application', re.IGNORECASE),
        re.compile(r'%%\s*(Level|Tier)\s*4\s*:\s*Challenge', re.IGNORECASE),
    ]

    def __init__(self, root_dir: Path, report: AuditReport, target_module: Optional[str] = None):
        self.root_dir = root_dir.resolve()
        self.report = report
        self.target_module = target_module

    def audit_exercise_file(self, ex_file: Path) -> None:
        self.report.total_checks += 1
        try:
            content = ex_file.read_text(encoding='utf-8')
        except Exception as e:
            self.report.add_diagnostic(Diagnostic(
                validator="ExerciseTierAuditor",
                severity=Severity.ERROR,
                file_path=ex_file,
                message=f"Could not read exercise file: {e}",
                remediation="Ensure file is valid UTF-8 text."
            ))
            return

        # 1. Check all 4 Tiers
        for tier_num, pattern in enumerate(self.TIER_PATTERNS, start=1):
            if not pattern.search(content):
                self.report.add_diagnostic(Diagnostic(
                    validator="ExerciseTierAuditor",
                    severity=Severity.ERROR,
                    file_path=ex_file,
                    message=f"Missing mandatory Tier {tier_num} header in '{ex_file.name}'.",
                    remediation=f"Add cell divider header '%% Level {tier_num}: [Topic]'."
                ))

        # 2. Check for student TODO markers in exercise templates
        if "TODO" not in content and "TASK" not in content:
            self.report.add_diagnostic(Diagnostic(
                validator="ExerciseTierAuditor",
                severity=Severity.WARNING,
                file_path=ex_file,
                message=f"No '% TODO' or '% TASK' markers found in '{ex_file.name}'.",
                remediation="Add student prompts indicating where calculations should be performed."
            ))

        # 3. Locate matching reference solution
        module_name = ex_file.parent.name
        possible_solutions = [
            self.root_dir / "solutions" / f"{module_name}_exercises_solution.m",
            ex_file.parent / "solutions" / "exercises_solution.m",
            ex_file.parent / "exercises_solution.m",
            self.root_dir / "solutions" / f"{module_name}_solution.m",
        ]

        solution_file: Optional[Path] = None
        for sol_cand in possible_solutions:
            if sol_cand.exists():
                solution_file = sol_cand
                break

        if not solution_file:
            self.report.add_diagnostic(Diagnostic(
                validator="ExerciseTierAuditor",
                severity=Severity.ERROR,
                file_path=ex_file,
                message=f"Missing decoupled reference solution for '{ex_file.relative_to(self.root_dir)}'.",
                remediation=f"Create reference solution at 'solutions/{module_name}_exercises_solution.m'."
            ))
        else:
            try:
                sol_content = solution_file.read_text(encoding='utf-8')
                if len(sol_content.strip()) < 200:
                    self.report.add_diagnostic(Diagnostic(
                        validator="ExerciseTierAuditor",
                        severity=Severity.ERROR,
                        file_path=solution_file,
                        message=f"Solution file '{solution_file.name}' is too short ({len(sol_content)} B).",
                        remediation="Implement complete working reference solutions for all 4 tiers."
                    ))
                # Check for remaining unresolved TODOs
                todo_matches = re.findall(r'%\s*TODO.*', sol_content, re.IGNORECASE)
                if todo_matches:
                    self.report.add_diagnostic(Diagnostic(
                        validator="ExerciseTierAuditor",
                        severity=Severity.ERROR,
                        file_path=solution_file,
                        message=f"Solution file has {len(todo_matches)} unresolved TODO comments.",
                        remediation="Resolve all TODO placeholders in the reference solution."
                    ))
            except Exception as e:
                self.report.add_diagnostic(Diagnostic(
                    validator="ExerciseTierAuditor",
                    severity=Severity.ERROR,
                    file_path=solution_file,
                    message=f"Error reading solution file: {e}",
                    remediation="Ensure solution file is readable UTF-8."
                ))

        self.report.passed_checks += 1

    def validate(self) -> None:
        search_dir = self.root_dir / self.target_module if self.target_module else self.root_dir
        if not search_dir.exists():
            return
        exercise_files = sorted(search_dir.rglob("exercises.m"))
        for ex_file in exercise_files:
            if ".git" in ex_file.parts or ".agents" in ex_file.parts:
                continue
            self.audit_exercise_file(ex_file)


# ==============================================================================
# VALIDATOR 5: DATASET & CAPSTONE VALIDATOR
# ==============================================================================

class DatasetCapstoneValidator:
    """Validates tabular dataset schemas, numerical integrity, and capstone assets."""

    EXPECTED_TELEMETRY_COLUMNS = {
        # Schema A: EV Powertrain (PROJECT.md)
        "ev": [
            "timestamp_s", "motor_speed_rpm", "motor_torque_nm",
            "battery_voltage_v", "battery_current_a", "inverter_temp_c", "ambient_temp_c"
        ],
        # Schema B: Industrial Pump (test_arch_report.md)
        "industrial": [
            "timestamp", "temperature_c", "vibration_rms",
            "motor_current_a", "pressure_kpa", "system_status"
        ]
    }

    def __init__(self, root_dir: Path, report: AuditReport, target_module: Optional[str] = None):
        self.root_dir = root_dir.resolve()
        self.report = report
        self.target_module = target_module

    def validate_csv(self, csv_file: Path, min_rows: int = 100) -> None:
        self.report.total_checks += 1
        try:
            with open(csv_file, 'r', encoding='utf-8') as f:
                reader = csv.reader(f)
                header = next(reader, None)
                if not header:
                    self.report.add_diagnostic(Diagnostic(
                        validator="DatasetValidator",
                        severity=Severity.ERROR,
                        file_path=csv_file,
                        message="CSV dataset is empty or missing header row.",
                        remediation="Populate dataset with header row and telemetry data."
                    ))
                    return

                col_count = len(header)
                row_count = 0
                for row_idx, row in enumerate(reader, start=2):
                    row_count += 1
                    if len(row) != col_count:
                        self.report.add_diagnostic(Diagnostic(
                            validator="DatasetValidator",
                            severity=Severity.ERROR,
                            file_path=csv_file,
                            line_number=row_idx,
                            message=f"Inconsistent column count: header has {col_count}, row {row_idx} has {len(row)}.",
                            remediation="Ensure every row contains exactly the header number of columns."
                        ))
                        return

                    # Verify numerical validity for numeric columns
                    for col_idx, val in enumerate(row):
                        col_name = header[col_idx].strip()
                        val_str = val.strip()
                        if col_name in ("status", "system_status", "mode", "label", "notes"):
                            continue
                        try:
                            float(val_str)
                        except ValueError:
                            self.report.add_diagnostic(Diagnostic(
                                validator="DatasetValidator",
                                severity=Severity.ERROR,
                                file_path=csv_file,
                                line_number=row_idx,
                                column_number=col_idx + 1,
                                message=f"Non-numeric value '{val_str}' in numeric column '{col_name}'.",
                                remediation="Ensure sensor telemetry columns contain valid floats."
                            ))
                            return

                if row_count < min_rows:
                    self.report.add_diagnostic(Diagnostic(
                        validator="DatasetValidator",
                        severity=Severity.WARNING,
                        file_path=csv_file,
                        message=f"Dataset has {row_count} rows, expected at least {min_rows}.",
                        remediation="Generate realistic time series with at least 100 sample intervals."
                    ))
                else:
                    self.report.passed_checks += 1

        except Exception as e:
            self.report.add_diagnostic(Diagnostic(
                validator="DatasetValidator",
                severity=Severity.ERROR,
                file_path=csv_file,
                message=f"Failed to read CSV dataset: {e}",
                remediation="Ensure file is valid comma-separated UTF-8 text."
            ))

    def validate_capstone_assets(self) -> None:
        capstone_dir = self.root_dir / "capstone"
        if not capstone_dir.exists():
            return

        self.report.total_checks += 1
        # Check generator script
        gen_scripts = [
            capstone_dir / "generate_capstone_data.py",
            capstone_dir / "generate_capstone_data.m",
            capstone_dir / "generate_telemetry.py",
        ]
        if not any(g.exists() for g in gen_scripts):
            self.report.add_diagnostic(Diagnostic(
                validator="DatasetValidator",
                severity=Severity.WARNING,
                file_path=capstone_dir,
                message="Telemetry generator script missing in capstone directory.",
                remediation="Provide reproducible Python or MATLAB generator script."
            ))
        else:
            self.report.passed_checks += 1

    def validate(self) -> None:
        if self.target_module and self.target_module not in ("capstone", "data", "datasets"):
            return

        # Find CSV files
        search_dirs = [self.root_dir / "data", self.root_dir / "datasets", self.root_dir / "capstone"]
        for s_dir in search_dirs:
            if s_dir.exists():
                for csv_file in s_dir.rglob("*.csv"):
                    self.validate_csv(csv_file)

        self.validate_capstone_assets()


# ==============================================================================
# MASTER VERIFICATION RUNNER
# ==============================================================================

class VerificationRunner:
    """Coordinates execution of all validators and produces diagnostic reporting."""

    def __init__(
        self,
        root_dir: Path,
        json_out: Optional[Path] = None,
        verbose: bool = False,
        checks: Optional[Set[str]] = None,
        target_module: Optional[str] = None
    ):
        self.root_dir = root_dir.resolve()
        self.json_out = json_out
        self.verbose = verbose
        self.checks = checks or {"all"}
        self.target_module = target_module
        self.report = AuditReport()

    def run(self) -> int:
        print("=" * 80)
        print("ENGINEERING MATHEMATICS TEACHING PACKAGE — QUALITY VERIFICATION")
        print(f"Root Directory: {self.root_dir}")
        if self.target_module:
            print(f"Target Module : {self.target_module}")
        print("=" * 80)

        run_all = "all" in self.checks

        pipeline = []
        if run_all or "structure" in self.checks:
            pipeline.append(("Directory Structure", DirectoryStructureValidator(self.root_dir, self.report, self.target_module)))
        if run_all or "links" in self.checks:
            pipeline.append(("Markdown Links & Anchors", MarkdownLinkValidator(self.root_dir, self.report, self.target_module)))
        if run_all or "syntax" in self.checks:
            pipeline.append(("MATLAB Syntax & Quality", MatlabSyntaxAuditor(self.root_dir, self.report, self.target_module)))
        if run_all or "exercises" in self.checks:
            pipeline.append(("4-Tier Exercise Structure", ExerciseTierAuditor(self.root_dir, self.report, self.target_module)))
        if run_all or "dataset" in self.checks:
            pipeline.append(("Dataset & Capstone", DatasetCapstoneValidator(self.root_dir, self.report, self.target_module)))

        for name, validator in pipeline:
            print(f"[*] Running {name} Validator...")
            validator.validate()

        # Print Diagnostics
        print("\n" + "-" * 80)
        print("DIAGNOSTIC RESULTS SUMMARY")
        print("-" * 80)

        if not self.report.diagnostics:
            print("\033[92m[PASS] All verification checks passed cleanly! Zero errors or warnings.\033[0m")
        else:
            for diag in self.report.diagnostics:
                if diag.severity == Severity.ERROR:
                    prefix = "\033[91m[ERROR]\033[0m"
                elif diag.severity == Severity.WARNING:
                    prefix = "\033[93m[WARN ]\033[0m"
                else:
                    prefix = "[INFO ]"

                try:
                    rel_file = diag.file_path.relative_to(self.root_dir)
                except ValueError:
                    rel_file = diag.file_path.name

                loc = f"{rel_file}"
                if diag.line_number:
                    loc += f":{diag.line_number}"
                if diag.column_number:
                    loc += f":{diag.column_number}"

                print(f"{prefix} [{diag.validator}] {loc} — {diag.message}")
                if self.verbose or diag.severity == Severity.ERROR:
                    if diag.snippet:
                        print(f"        Code: {diag.snippet}")
                    if diag.remediation:
                        print(f"        Fix:  {diag.remediation}")

        # Summary box
        print("-" * 80)
        print(f"Total Checks Executed : {self.report.total_checks}")
        print(f"Passed Checks         : {self.report.passed_checks}")
        print(f"Warnings Emitted      : {self.report.warning_count}")
        print(f"Errors Found          : {self.report.error_count}")
        print("=" * 80)

        # JSON output
        if self.json_out:
            out_data = {
                "root_dir": str(self.root_dir),
                "is_success": self.report.is_success,
                "total_checks": self.report.total_checks,
                "passed_checks": self.report.passed_checks,
                "warning_count": self.report.warning_count,
                "error_count": self.report.error_count,
                "diagnostics": [d.to_dict() for d in self.report.diagnostics],
            }
            try:
                self.json_out.parent.mkdir(parents=True, exist_ok=True)
                self.json_out.write_text(json.dumps(out_data, indent=2), encoding='utf-8')
                print(f"Wrote JSON diagnostic report to: {self.json_out}")
            except Exception as e:
                print(f"Failed to write JSON output: {e}", file=sys.stderr)

        if self.report.is_success:
            print("\033[92m>>> VERIFICATION STATUS: SUCCESS (Package meets specification)\033[0m\n")
            return 0
        else:
            print("\033[91m>>> VERIFICATION STATUS: FAILED (Resolve errors listed above)\033[0m\n")
            return 1


# ==============================================================================
# CLI ENTRY POINT
# ==============================================================================

def main() -> None:
    parser = argparse.ArgumentParser(
        description="Audit and verify engineering-mathematics MATLAB teaching package."
    )
    parser.add_argument(
        "--root",
        type=Path,
        default=Path(__file__).resolve().parent.parent,
        help="Root directory of engineering-mathematics package"
    )
    parser.add_argument(
        "--module",
        type=str,
        default=None,
        help="Target specific module (e.g. matlab, linear_algebra, calculus)"
    )
    parser.add_argument(
        "--check-syntax",
        action="store_true",
        help="Run only MATLAB syntax auditor"
    )
    parser.add_argument(
        "--check-structure",
        action="store_true",
        help="Run only directory structure validator"
    )
    parser.add_argument(
        "--check-links",
        action="store_true",
        help="Run only markdown links & anchors validator"
    )
    parser.add_argument(
        "--check-exercises",
        action="store_true",
        help="Run only 4-tier progressive exercise auditor"
    )
    parser.add_argument(
        "--check-dataset",
        action="store_true",
        help="Run only dataset & capstone validator"
    )
    parser.add_argument(
        "--all",
        action="store_true",
        help="Run all verification checks (default)"
    )
    parser.add_argument(
        "--json",
        type=Path,
        default=None,
        help="Path to output JSON diagnostic report"
    )
    parser.add_argument(
        "-v", "--verbose",
        action="store_true",
        help="Enable verbose diagnostics with code snippets and remediation instructions"
    )

    args = parser.parse_args()

    checks: Set[str] = set()
    if args.check_syntax:
        checks.add("syntax")
    if args.check_structure:
        checks.add("structure")
    if args.check_links:
        checks.add("links")
    if args.check_exercises:
        checks.add("exercises")
    if args.check_dataset:
        checks.add("dataset")
    if args.all or not checks:
        checks = {"all"}

    runner = VerificationRunner(
        root_dir=args.root,
        json_out=args.json,
        verbose=args.verbose,
        checks=checks,
        target_module=args.module
    )
    sys.exit(runner.run())


if __name__ == "__main__":
    main()
