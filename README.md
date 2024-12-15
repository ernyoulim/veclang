# VecLang: A Programming Language for Coordinates and Matrices

VecLang is a programming language designed to simplify working with coordinates, matrices, and vector operations. Inspired by the descriptive vector graphics language Asymptote, VecLang offers an intuitive syntax and robust features tailored for developers who frequently manipulate vector and geometric data.

## Table of Contents

- [Key Features](#key-features)
- [Installation](#installation)
- [Getting Started](#getting-started)

---

## Key Features

### Supported Data Types

VecLang provides several specialized data types:

- **`num`**: Represents integer values.
- **`[num]`**: Dynamic arrays of integers with methods like:
  - Access: `arrayname[index]`
  - Add element: `arrayname.add(num)`
- **`point`**: Stores 3D coordinates (`x, y, z`).
- **`mat3x3`**: Handles 3x3 matrix operations with floating-point precision.
- **`shape`**: Organizes arrays of points into geometric structures with built-in methods like `shape.getPoints<index>`.

### Control Structures

- **Conditional Statements**:
  ```
  if_(x != 10) {
    // code
  } else {
    // code
  }
  ```
- **Switch-Case**:
  ```
  switch_(c) {
    case 0:
      print "Hello";
  }
  ```
- **Looping**:
  ```
  num i = 0;
  loop_(i != 5) {
    i = i + 1;
  }
  ```

### Functions

Define reusable blocks of code:

```
function_call generatePerm(x, y, z) {
  // logic
  generatePerm(x, y + 1, z);
}
generatePerm(x, y, z);
```

### Comments

Insert comments in your code for better readability:

```
/C This is a comment /C
```

### Arithmetic and Logical Operators

Perform operations based on operand types:

- Arithmetic: `+`, `-`, `*`, `%`
- Comparison: `<`, `>`, `==`, `!=`, `!`, `&`, `|`
- Examples:
  - Adding points: `point x = (1, 23, 1) + (2, 1, 10); // x = (3, 24, 11)`
  - Scaling a shape:
    ```
    mat3x3 scale = [2.0, 0.0, 0.0], [0.0, 2.0, 0.0], [0.0, 0.0, 0.0];
    shape scaledRectangle = rectangle * scale;
    ```

### Customizable Output Formats

VecLang allows versatile printing options:

```
print %d x;  // Decimal format
print "point x coordinates x: 1.0, y: 1.5, z: 0.1";  // Point data
```

### Special Keywords

- `getint`: Capture integer input.
- `return`: Exit from a function.
- `getrand(num1, num2)`: Generate a random integer between `num1` and `num2`.
- `print`: Display data or literals.

---

## Installation

1. Clone the repository:
   ```
   git clone https://github.com/yourusername/veclang.git
   ```
2. Navigate to the project directory:
   ```
   cd veclang
   ```
3. Build VecLang:
   ```
   make
   ```

---

## Getting Started

Here’s a simple VecLang program to demonstrate basic functionality:

```
/C Example program in VecLang /C
num x = 10;
if_(x == 10) {
  print "x is 10";
}

point p1 = (1.0, 2.0, 3.0);
point p2 = (4.0, 5.0, 6.0);
point result = p1 + p2;
print "Resultant Point: x: %d, y: %d, z: %d", result;
```

1. Save the code in a `.vl` file.
2. Compile and run using VecLang (compiler instructions to be provided).

---

