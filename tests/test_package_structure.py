"""
================================================================================
E2E TEST SUITE: PACKAGE STRUCTURE, SYNTAX & VERIFICATION AUDIT
================================================================================
Pytest wrapper and unit/integration test suite for verify_package.py validators:
- DirectoryStructureValidator
- MarkdownLinkValidator
- MatlabSyntaxAuditor (Context-aware lexer, block/delimiter balance, 0-indexing)
- ExerciseTierAuditor
- DatasetCapstoneValidator
================================================================================
"""

import os
from pathlib import Path
import tempfile
import pytest

from scripts.verify_package import (
    AuditReport,
    Diagnostic,
    Severity,
    DirectoryStructureValidator,
    MarkdownLinkValidator,
    MatlabSyntaxAuditor,
    ExerciseTierAuditor,
    DatasetCapstoneValidator,
    VerificationRunner,
)


@pytest.fixture
def package_root() -> Path:
    """Returns the absolute Path to the engineering-mathematics package root."""
    return Path(__file__).resolve().parent.parent


# ==============================================================================
# 1. MATLAB SYNTAX AUDITOR TESTS (LEXER, BLOCKS, DELIMITERS, SEMANTICS)
# ==============================================================================

class TestMatlabSyntaxAuditor:
    """Rigorous unit and regression tests for MatlabSyntaxAuditor."""

    def test_lexer_distinguishes_transpose_from_character_vectors(self, package_root):
        """Verify context-aware lexer correctly classifies ' as transpose vs char vector."""
        auditor = MatlabSyntaxAuditor(package_root, AuditReport())
        code = """
        % Test cases for transpose vs character vectors
        v = [1, 2, 3]';               % Vector transpose
        M = A' * B;                   % Matrix transpose
        P = (x + y)';                 % Parenthetical transpose
        str1 = 'hello world';         % Character vector literal
        str2 = 'it''s MATLAB';        % Escaped quote in char vector
        B = A'';                      % Double transpose
        C = M.';                      % Non-conjugate array transpose
        msg = sprintf('Value: %d', x);
        """
        tokens = auditor.tokenize(code)
        
        # Check token types
        token_types = [t[0] for t in tokens]
        transposes = [t for t in tokens if t[0] == 'TRANSPOSE']
        char_vecs = [t for t in tokens if t[0] == 'CHAR_VEC']
        
        assert len(transposes) >= 4, f"Expected at least 4 transpose operators, found {len(transposes)}"
        assert any(t[1] == ".'" for t in transposes), "Array transpose .' was not recognized"
        assert len(char_vecs) >= 3, f"Expected at least 3 character vectors, found {len(char_vecs)}"
        assert any("it''s MATLAB" in t[1] for t in char_vecs), "Escaped quote char vector failed"

    def test_balanced_matlab_control_blocks_pass(self, package_root, tmp_path):
        """Verify well-formed MATLAB control blocks pass cleanly."""
        report = AuditReport()
        auditor = MatlabSyntaxAuditor(tmp_path, report)
        
        valid_code = """
        function result = compute_norm(v)
            % COMPUTATION_NORM Computes Euclidean norm of vector v.
            % Units: SI meters. Rationale: Standard L2 norm.
            n = length(v);
            sum_sq = 0;
            for i = 1:n
                if v(i) > 0
                    sum_sq = sum_sq + v(i)^2;
                elseif v(i) < 0
                    sum_sq = sum_sq + (-v(i))^2;
                else
                    continue;
                end
            end
            result = sqrt(sum_sq);
        end
        """
        test_file = tmp_path / "valid_code.m"
        test_file.write_text(valid_code, encoding="utf-8")
        
        auditor.audit_file(test_file)
        errors = [d for d in report.diagnostics if d.severity == Severity.ERROR]
        assert len(errors) == 0, f"Unexpected errors on valid code: {[d.message for d in errors]}"

    def test_block_balancer_detects_unclosed_block(self, package_root, tmp_path):
        """Verify unclosed 'for' or 'if' block triggers an ERROR."""
        report = AuditReport()
        auditor = MatlabSyntaxAuditor(tmp_path, report)
        
        unclosed_code = """
        function y = buggy_loop(x)
            % Buggy loop missing an end
            total = 0;
            for i = 1:10
                total = total + x(i);
            % Missing 'end' for the for loop
        end
        """
        test_file = tmp_path / "unclosed_block.m"
        test_file.write_text(unclosed_code, encoding="utf-8")
        
        auditor.audit_file(test_file)
        errors = [d for d in report.diagnostics if d.severity == Severity.ERROR]
        assert len(errors) > 0
        assert any("Unclosed" in d.message for d in errors)

    def test_block_balancer_detects_dangling_end(self, package_root, tmp_path):
        """Verify extraneous 'end' triggers an ERROR."""
        report = AuditReport()
        auditor = MatlabSyntaxAuditor(tmp_path, report)
        
        dangling_code = """
        x = 5;
        y = 10;
        end % Extraneous end without block
        """
        test_file = tmp_path / "dangling_end.m"
        test_file.write_text(dangling_code, encoding="utf-8")
        
        auditor.audit_file(test_file)
        errors = [d for d in report.diagnostics if d.severity == Severity.ERROR]
        assert len(errors) > 0
        assert any("Dangling 'end'" in d.message for d in errors)

    def test_block_balancer_ignores_indexing_end(self, package_root, tmp_path):
        """Verify that array indexing keyword 'end' inside () or {} is NOT treated as a block closer."""
        report = AuditReport()
        auditor = MatlabSyntaxAuditor(tmp_path, report)
        
        indexing_code = """
        function last_val = get_last(v)
            % GET_LAST Returns last element using 1-based indexing.
            % Formula: v(end)
            % Units: SI
            if ~isempty(v)
                last_val = v(end);        % Indexing end
                sub_vec = v(2:end);       % Slice to end
                rev_vec = v(end:-1:1);    % Reverse vector using end
            else
                last_val = NaN;
            end
        end
        """
        test_file = tmp_path / "indexing_end.m"
        test_file.write_text(indexing_code, encoding="utf-8")
        
        auditor.audit_file(test_file)
        errors = [d for d in report.diagnostics if d.severity == Severity.ERROR]
        assert len(errors) == 0, f"Indexing 'end' incorrectly flagged: {[d.message for d in errors]}"

    def test_delimiter_balancer_detects_mismatched_brackets(self, package_root, tmp_path):
        """Verify mismatched delimiters like (] or [) are caught."""
        report = AuditReport()
        auditor = MatlabSyntaxAuditor(tmp_path, report)
        
        mismatched_code = """
        x = (1 + 2]; % Error: '(' closed with ']'
        """
        test_file = tmp_path / "mismatch.m"
        test_file.write_text(mismatched_code, encoding="utf-8")
        
        auditor.audit_file(test_file)
        errors = [d for d in report.diagnostics if d.severity == Severity.ERROR]
        assert len(errors) > 0
        assert any("Mismatched delimiter" in d.message for d in errors)

    def test_semantic_zero_based_indexing_detected(self, package_root, tmp_path):
        """Verify student attempt at Python-style 0-based indexing is caught."""
        report = AuditReport()
        auditor = MatlabSyntaxAuditor(tmp_path, report)
        
        zero_index_code = """
        % Student code with 0-based indexing bug
        vec = [10, 20, 30];
        first_elem = vec(0); % BUG: MATLAB is 1-based!
        """
        test_file = tmp_path / "zero_idx.m"
        test_file.write_text(zero_index_code, encoding="utf-8")
        
        auditor.audit_file(test_file)
        errors = [d for d in report.diagnostics if d.severity == Severity.ERROR]
        assert len(errors) > 0
        assert any("0-based indexing" in d.message for d in errors)

    def test_semantic_builtins_with_zero_not_flagged(self, package_root, tmp_path):
        """Verify standard builtins with 0 or negative inputs are not falsely flagged."""
        report = AuditReport()
        auditor = MatlabSyntaxAuditor(tmp_path, report)
        
        builtins_code = """
        % Standard engineering functions taking 0 or negative numbers
        % Rationale: Valid domain calls
        % Units: SI
        z = zeros(0, 0);
        x_lin = linspace(0, 10, 100);
        y_exp = exp(-2.5);
        c = cosd(0);
        s = sind(0);
        v_az = view(-35, 40);
        quiver(0, 0, 1, 2, 0);
        quiver3(0, 0, 0, 1, 2, 3, 0);
        """
        test_file = tmp_path / "builtins.m"
        test_file.write_text(builtins_code, encoding="utf-8")
        
        auditor.audit_file(test_file)
        errors = [d for d in report.diagnostics if d.severity == Severity.ERROR]
        assert len(errors) == 0, f"Built-in function falsely flagged: {[d.message for d in errors]}"

    def test_existing_m_files_in_package_pass_syntax(self, package_root):
        """Verify that all existing MATLAB .m files in the package pass syntax check cleanly."""
        report = AuditReport()
        auditor = MatlabSyntaxAuditor(package_root, report)
        auditor.validate()
        
        errors = [d for d in report.diagnostics if d.severity == Severity.ERROR]
        assert len(errors) == 0, f"Syntax errors in courseware .m files:\n" + \
            "\n".join(f"- {d.file_path.name}:{d.line_number}: {d.message}" for d in errors)


# ==============================================================================
# 2. MARKDOWN LINK & ANCHOR VALIDATOR TESTS
# ==============================================================================

class TestMarkdownLinkValidator:
    """Unit tests for MarkdownLinkValidator link extraction and slug resolution."""

    def test_slugify_algorithm(self):
        """Verify CommonMark / GitHub slug generation rules."""
        assert MarkdownLinkValidator.slugify("1. Learning Objectives") == "1-learning-objectives"
        assert MarkdownLinkValidator.slugify("Why Engineers Need This (Level 1 -> 2)") == "why-engineers-need-this-level-1-2"
        assert MarkdownLinkValidator.slugify("Mathematical Intuition: Rates & Change") == "mathematical-intuition-rates-change"
        assert MarkdownLinkValidator.slugify("MATLAB Implementation `x = A\\b`") == "matlab-implementation-x-ab"

    def test_detects_broken_relative_links(self, tmp_path):
        """Verify broken local relative links are detected."""
        report = AuditReport()
        validator = MarkdownLinkValidator(tmp_path, report)
        
        doc = tmp_path / "guide.md"
        doc.write_text("[Nonexistent](missing_chapter.md)\n", encoding="utf-8")
        
        validator.validate_file(doc)
        errors = [d for d in report.diagnostics if d.severity == Severity.ERROR]
        assert len(errors) > 0
        assert any("missing_chapter.md" in d.message for d in errors)

    def test_valid_relative_links_and_anchors_pass(self, tmp_path):
        """Verify valid cross-file relative links with anchors pass."""
        report = AuditReport()
        validator = MarkdownLinkValidator(tmp_path, report)
        
        target = tmp_path / "target.md"
        target.write_text("# Chapter 1\n\n## Summary\nContent here.\n", encoding="utf-8")
        
        source = tmp_path / "source.md"
        source.write_text("[Go to Summary](target.md#summary)\n", encoding="utf-8")
        
        validator.validate_file(source)
        errors = [d for d in report.diagnostics if d.severity == Severity.ERROR]
        assert len(errors) == 0, f"Unexpected link error: {[d.message for d in errors]}"


# ==============================================================================
# 3. EXERCISE TIER AUDITOR TESTS
# ==============================================================================

class TestExerciseTierAuditor:
    """Unit tests for 4-tier progressive exercise structure and solution decoupling."""

    def test_detects_missing_tiers(self, tmp_path):
        """Verify exercise file missing Tier 4 is flagged."""
        report = AuditReport()
        auditor = ExerciseTierAuditor(tmp_path, report)
        
        incomplete_ex = tmp_path / "exercises.m"
        incomplete_ex.write_text("""
        %% Level 1: Recall
        % TODO: Task 1
        %% Level 2: Understanding
        % TODO: Task 2
        %% Level 3: Application
        % TODO: Task 3
        % Missing Level 4: Challenge!
        """, encoding="utf-8")
        
        auditor.audit_exercise_file(incomplete_ex)
        errors = [d for d in report.diagnostics if d.severity == Severity.ERROR]
        assert any("Tier 4" in d.message for d in errors)

    def test_detects_unresolved_todos_in_solution(self, tmp_path):
        """Verify reference solution with unresolved TODO markers is flagged."""
        report = AuditReport()
        auditor = ExerciseTierAuditor(tmp_path, report)
        
        mod_dir = tmp_path / "test_mod"
        sol_dir = tmp_path / "solutions"
        mod_dir.mkdir()
        sol_dir.mkdir()
        
        ex_file = mod_dir / "exercises.m"
        ex_file.write_text("""
        %% Level 1: Recall
        % TODO: Complete
        %% Level 2: Understanding
        % TODO: Complete
        %% Level 3: Application
        % TODO: Complete
        %% Level 4: Challenge
        % TODO: Complete
        """, encoding="utf-8")
        
        sol_file = sol_dir / "test_mod_exercises_solution.m"
        sol_file.write_text("""
        %% Level 1: Recall
        x = 1;
        % TODO: Forgot to finish this!
        %% Level 2: Understanding
        y = 2;
        %% Level 3: Application
        z = 3;
        %% Level 4: Challenge
        w = 4;
        """ * 10, encoding="utf-8")
        
        auditor.audit_exercise_file(ex_file)
        errors = [d for d in report.diagnostics if d.severity == Severity.ERROR]
        assert any("unresolved TODO" in d.message for d in errors)


# ==============================================================================
# 4. DATASET & CAPSTONE VALIDATOR TESTS
# ==============================================================================

class TestDatasetCapstoneValidator:
    """Unit tests for CSV telemetry integrity."""

    def test_valid_telemetry_csv_passes(self, tmp_path):
        """Verify well-formed CSV dataset with >= 100 rows passes."""
        report = AuditReport()
        validator = DatasetCapstoneValidator(tmp_path, report)
        
        csv_file = tmp_path / "telemetry.csv"
        rows = [["timestamp_s", "motor_speed_rpm", "motor_torque_nm", "battery_voltage_v", "battery_current_a", "inverter_temp_c", "ambient_temp_c"]]
        for i in range(120):
            rows.append([str(i * 0.1), str(3000 + i), str(150.0), "380.5", "45.2", "65.0", "22.0"])
            
        with open(csv_file, "w", encoding="utf-8") as f:
            for r in rows:
                f.write(",".join(r) + "\n")
                
        validator.validate_csv(csv_file, min_rows=100)
        errors = [d for d in report.diagnostics if d.severity == Severity.ERROR]
        assert len(errors) == 0

    def test_corrupt_column_count_detected(self, tmp_path):
        """Verify jagged rows in CSV trigger an error."""
        report = AuditReport()
        validator = DatasetCapstoneValidator(tmp_path, report)
        
        csv_file = tmp_path / "bad.csv"
        csv_file.write_text("t,v1,v2\n1.0,2.0,3.0\n2.0,4.0\n", encoding="utf-8")
        
        validator.validate_csv(csv_file, min_rows=1)
        errors = [d for d in report.diagnostics if d.severity == Severity.ERROR]
        assert len(errors) > 0
        assert any("Inconsistent column count" in d.message for d in errors)


# ==============================================================================
# 5. CLI & PROGRESSIVE STRUCTURAL VERIFICATION
# ==============================================================================

def test_verify_package_cli_syntax_flag(package_root):
    """Verify CLI --check-syntax runs and returns 0 on current codebase."""
    runner = VerificationRunner(root_dir=package_root, checks={"syntax"})
    exit_code = runner.run()
    assert exit_code == 0, "CLI --check-syntax failed on repository code"


def test_existing_modules_readmes_meet_size_threshold(package_root):
    """Verify README.md in any existing module directory meets pedagogical minimum size."""
    candidate_modules = ["matlab", "linear_algebra", "calculus", "probability", "simulink", "capstone", "ml_bridge"]
    for mod in candidate_modules:
        readme = package_root / mod / "README.md"
        if readme.exists():
            assert readme.stat().st_size >= 1500, f"Module '{mod}/README.md' is under 1500 bytes ({readme.stat().st_size} B)"
