# Examples from Rust0 and Oxide0

This document contains examples in Rust0 with their compiled forms in Oxide0.

## Valid Programs

### Simple Points

#### Rust
```rust
struct Point {
    x: u32,
    y: u32,
}

let x = 5;
let y = 9;
Point {
    x, y
}
```

#### Oxide
```rust
struct Point {
    x: u32,
    y: u32,
}

// We require `mut` here because moves and mutable borrows are the same.
let mut x = alloc 5;
let mut y = alloc 9;
Point {
    x: borrow mut x,
    y: borrow mut y,
}
```

### Nested Structures

#### Rust
```rust
struct Point {
    x: u32,
    y: u32,
}

struct Rect(Point, Point)

Rect(
    Point {
        x: 0,
        y: 0,
    },
    Point {
        x: 4,
        y: 4,
    },
)
```

#### Oxide
```rust
struct Point {
    x: u32,
    y: u32,
}

struct Rect(Point, Point)

Rect(
    alloc Point {
        x: alloc 0,
        y: alloc 0,
    },
    alloc Point {
        x: alloc 4,
        y: alloc 4,
    },
)
```

### Mutation

#### Rust
```rust
struct Point {
    x: u32,
    y: u32,
}

let mut x = 5;
x = 4;
Point {
    x, y: 9,
}
```

#### Oxide
```rust
struct Point {
    x: u32,
    y: u32,
}

let mut x = 5;
x.ε := 4;
Point {
    x: borrow mut x,
    y: alloc 9,
}
```

### Mutating a struct with references

#### Rust
```rust
#![feature(nll)]

struct PointRef<'a> {
    x: &'a mut u32,
    y: &'a mut u32,
}

let mut x = 5;
let mut y = 6;
let mut point = PointRef {
    x: &mut x,
    y: &mut y,
};
let mut z = 3;
point.x = &mut z;
```

#### Oxide
```rust
struct PointRef<ϱ_x, ζ_x, ϱ_y, ζ_y> {
    x: &ϱ_x ζ_x u32,
    y: &ϱ_y ζ_y u32,
}

let mut x = alloc 5;
let mut y = alloc 6;
let mut brw_x = borrow mut x;
let mut brw_y = borrow mut y;
let mut point = PointRef::<rgn of brw_x, cap of brw_x, rgn of brw_y, cap of brw_y> {
    x: borrow mut brw_x,
    y: borrow mut brw_y,
};
let mut z = alloc 3;
point.x := borrow mut z;
```

## Invalid Programs

### Partial Borrows

#### Rust
```rust
struct Foo;

struct Point {
    x: Foo,
    y: Foo,
}

let pt = Point {
    x: Foo,
    y: Foo,
};

// error[E0382]: use of partially moved value: `pt`
let foo = pt.x;
//  --- value moved here
let pt2 = pt;
//  ^^^ value used here after move
```

#### Oxide
```rust
struct Foo;

struct Point {
    x: Foo,
    y: Foo,
}

// Ρ: {}
let mut pt = alloc Point {
    x: alloc Foo(),
    // Ρ ∪ { ρ_x ↦ Foo ⊗ 1 ⊗ { ε ↦ Foo } }
    y: alloc Foo(),
    // Ρ ∪ { ρ_y ↦ Foo ⊗ 1 ⊗ { ε ↦ Foo } }
};
// Ρ ∪ { ρ_pt ↦ Point ⊗ 1 ⊗ { x ↦ ρ_x, y ↦ ρ_y } }

/* Ρ: {
 *   ρ_x ↦ Foo ⊗ 1 ⊗ { ε ↦ Foo },
 *   ρ_y ↦ Foo ⊗ 1 ⊗ { ε ↦ Foo },
 *   ρ_pt ↦ Point ⊗ 1 ⊗ { x ↦ ρ_x, y ↦ ρ_y },
 * }
 */
let mut foo = borrow mut pt.x;
/* Ρ: {
 *   ρ_x ↦ Foo ⊗ 1 / 2 ⊗ { ε ↦ Foo },
 *   ρ_y ↦ Foo ⊗ 1 ⊗ { ε ↦ Foo },
 *   ρ_pt ↦ Point ⊗ 1 ⊗ { x ↦ ρ_x, y ↦ ρ_y },
 *   foo ↦ Foo ⊗ 1 / 2 ⊗ { ε ↦ Foo },
 * }
 */
let mut pt2 = borrow mut pt;
//            ^^^^^^^^^^^^^ cannot borrow mut because `ρ_pt` subpath `ρ_x` capability ≠ `1`.
()
```
