%% 06_python_numpy_bridge.m
% =========================================================================
% MATLAB Fundamentals & Computational Environment: Python/NumPy Bridge
% =========================================================================
% Pedagogical Objective:
% Students entering Level 2 (Engineering Mathematics + MATLAB) have completed
% Level 1 (Python, NumPy, Matplotlib). This script serves as an exhaustive,
% side-by-side computational "Rosetta Stone".
%
% We systematically contrast the mental models, memory storage paradigms,
% syntax patterns, and operator rules between Python/NumPy and MATLAB.
%
% Structure:
%   Part 1: Foundational Mental Models & Architectural Differences
%   Part 2: Comprehensive Syntax Rosetta Stone (30+ Core Operations)
%   Part 3: Executable Side-by-Side Equivalence Demonstrations
%   Part 4: The 5 Most Dangerous Translation Traps for Python Developers
% =========================================================================

clearvars;
close all;
clc;

fprintf('====================================================\n');
fprintf(' MODULE 1: THE PYTHON/NUMPY -> MATLAB ROSETTA STONE\n');
fprintf('====================================================\n\n');

%% PART 1: ARCHITECTURAL & MENTAL MODEL COMPARISON
%
% 1. INDEXING ORIGIN:
%    - Python / NumPy : 0-based indexing. First element is A[0].
%    - MATLAB         : 1-based indexing. First element is A(1).
%
% 2. SLICING BOUNDARIES:
%    - Python / NumPy : A[start:stop:step] - Non-inclusive of 'stop'!
%                       Example: arr[0:5] extracts 5 elements (indices 0, 1, 2, 3, 4).
%    - MATLAB         : A(start:step:end)   - INCLUSIVE of 'end'!
%                       Example: arr(1:5) extracts 5 elements (indices 1, 2, 3, 4, 5).
%
% 3. ARRAY ORIENTATION & DIMENSIONALITY:
%    - Python / NumPy : 1D arrays have shape (N,). They are neither row nor column.
%                       Transposing a 1D array arr.T does NOTHING to shape (N,).
%    - MATLAB         : Everything has at least 2 dimensions!
%                       A row vector has size [1, N]. A column vector has size [N, 1].
%                       A scalar has size [1, 1]. Transposing row' gives column!
%
% 4. OPERATOR PHILOSOPHY:
%    - Python / NumPy : '*' is element-wise multiplication.
%                       '@' or np.dot() / np.matmul() is matrix multiplication.
%    - MATLAB         : '*' is linear algebra MATRIX multiplication.
%                       '.*' is element-wise HADAMARD multiplication.
%
% 5. MEMORY LAYOUT (CACHE ALIGNMENT):
%    - Python / NumPy : Defaults to Row-Major (C-order).
%                       Contiguous in memory along ROWS. Fast iteration over rows.
%    - MATLAB         : Strictly Column-Major (Fortran-order).
%                       Contiguous in memory along COLUMNS. Fast iteration down columns.
%
% 6. WORKSPACE & VARIABLE SCOPE:
%    - Python         : Scoped inside modules, scripts, or functions. Clean namespaces.
%    - MATLAB         : Scripts execute in and mutate the global Base Workspace.
%                       Functions possess private, encapsulated workspaces.

%% PART 2: THE 30-OPERATION ROSETTA TABLE (REFERENCE)
%
%  OPERATION                    NUMPY (PYTHON)                 MATLAB
%  ----------------------------------------------------------------------------------
%  Array creation (zeros)       np.zeros((3, 4))               zeros(3, 4)
%  Array creation (ones)        np.ones((3, 4))                ones(3, 4)
%  Identity matrix              np.eye(4)                      eye(4)
%  Linear spacing               np.linspace(0, 1, 11)          linspace(0, 1, 11)
%  Integer step range           np.arange(0, 10, 2)            0 : 2 : 8
%  Shape / Dimensions           arr.shape                      size(arr)
%  Total element count          arr.size                       numel(arr)
%  Matrix Transpose             A.T                            A.' (non-conj) or A' (conj)
%  Horizontal concatenate       np.hstack([A, B])              [A, B]
%  Vertical concatenate         np.vstack([A, B])              [A; B]
%  First element                arr[0]                         arr(1)
%  Last element                 arr[-1]                        arr(end)
%  Slice first 5 elements       arr[0:5]                       arr(1:5)
%  Every second element         arr[::2]                       arr(1:2:end)
%  Row slice                    A[i, :]                        A(i, :)
%  Column slice                 A[:, j]                        A(:, j)
%  Element-wise multiply        A * B                          A .* B
%  Matrix multiply              A @ B (or np.matmul(A, B))     A * B
%  Element-wise power           A ** 2                         A .^ 2
%  Matrix power                 np.linalg.matrix_power(A, 2)   A ^ 2
%  Element-wise divide          A / B                          A ./ B
%  Solve linear system Ax = b   np.linalg.solve(A, b)          x = A \ b
%  Dot product                  np.dot(u, v)                   dot(u, v) or u' * v
%  Cross product                np.cross(u, v)                 cross(u, v)
%  Vector norm (Euclidean)      np.linalg.norm(v)              norm(v)
%  Logical indexing (filter)    arr[arr > 5]                   arr(arr > 5)
%  Flatten to 1D vector         arr.flatten()                  arr(:)
%  Reshape dimensions           arr.reshape(3, 4)              reshape(arr, 3, 4)
%  Matrix inverse               np.linalg.inv(A)               inv(A)
%  Eigenvalues/vectors          np.linalg.eig(A)               [V, D] = eig(A)
%  2D line plot                 plt.plot(x, y); plt.show()     plot(x, y); grid on
%  Subplot creation             plt.subplot(2, 1, 1)           subplot(2, 1, 1)

%% PART 3: EXECUTABLE CODE EQUIVALENCE DEMONSTRATIONS

fprintf('--- DEMONSTRATION 1: ARRAY SHAPES AND SLICING ---\n');
% In NumPy:
%   x = np.linspace(0, 10, 6) # [0., 2., 4., 6., 8., 10.] -> shape (6,)
%   first_three = x[0:3]       # extracts indices 0, 1, 2 -> [0., 2., 4.]
% In MATLAB:
x_matlab = linspace(0, 10, 6); % Size: [1, 6]
first_three_matlab = x_matlab(1:3); % Extracts indices 1, 2, 3

fprintf('MATLAB linspace(0, 10, 6) size: [%d, %d]\n', size(x_matlab));
fprintf('First 3 elements in MATLAB x(1:3): ');
fprintf('%4.1f ', first_three_matlab);
fprintf('\n\n');

fprintf('--- DEMONSTRATION 2: MATRIX MULTIPLY VS ELEMENT-WISE ---\n');
% In NumPy:
%   A = np.array([[1, 2], [3, 4]])
%   B = np.array([[5, 6], [7, 8]])
%   elem_mult = A * B   # [[ 5, 12], [21, 32]]
%   mat_mult  = A @ B   # [[19, 22], [43, 50]]
% In MATLAB:
A_demo = [1, 2; 3, 4];
B_demo = [5, 6; 7, 8];

elem_mult_matlab = A_demo .* B_demo; % Element-wise: Hadamard product
mat_mult_matlab  = A_demo * B_demo;  % Matrix algebra: Linear composition

fprintf('MATLAB Element-wise A .* B (NumPy A * B):\n');
disp(elem_mult_matlab);

fprintf('MATLAB Matrix Algebra A * B (NumPy A @ B):\n');
disp(mat_mult_matlab);

fprintf('--- DEMONSTRATION 3: SOLVING Ax = b ---\n');
% In NumPy:
%   x = np.linalg.solve(A, b)
% In MATLAB:
A_sys = [3, 1; 1, 2];
b_sys = [9; 8];
x_sol = A_sys \ b_sys; % High-performance Gaussian elimination backslash

fprintf('MATLAB Backslash x = A \\ b (NumPy np.linalg.solve(A, b)):\n');
fprintf('  x1 = %5.2f, x2 = %5.2f\n\n', x_sol(1), x_sol(2));

%% PART 4: THE 5 MOST DANGEROUS TRANSLATION TRAPS FOR PYTHON DEVS
%
% TRAP 1: Zero-based indexing assumption
%   Python: arr[0] retrieves the first element.
%   MATLAB: arr(0) throws: 'Array indices must be positive integers.'
%   REMEMBER: First index is 1!
%
% TRAP 2: Using '*' when you need '.*'
%   Python: In NumPy, '*' is the default point-wise multiplier.
%   MATLAB: In MATLAB, '*' defaults to MATRIX multiplication.
%   Writing 'y = sin(t) * exp(-t)' fails immediately!
%   REMEMBER: Always include the dot for time-series arithmetic (.*, ./, .^).
%
% TRAP 3: Forgetting that Slicing includes the End
%   Python: arr[0:4] yields 4 items (indices 0, 1, 2, 3).
%   MATLAB: arr(1:4) yields 4 items (indices 1, 2, 3, 4).
%   Python developers often write arr(1:5) expecting 4 items, but get 5!
%
% TRAP 4: Dynamic List Appending in Loops
%   Python: list.append(x) is amortized O(1) time complexity.
%   MATLAB: arr(end+1) = x inside a loop forces memory reallocation and full
%   array copying on every iteration (O(N^2) disaster).
%   REMEMBER: Always preallocate with zeros(1, N) or zeros(N, M).
%
% TRAP 5: Modifying Function Arguments
%   Python: Passing a mutable object (like a dict or list) modifies the caller's object.
%   MATLAB: Functions have strictly copy-on-write pass-by-value semantics.
%   Modifications inside a function are completely lost unless explicitly returned!

fprintf('====================================================\n');
fprintf(' 06_python_numpy_bridge.m execution completed successfully.\n');
