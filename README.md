Built following the [wasm-4 snake
tutorial](https://wasm4.org/docs/tutorials/snake/goal), but in
[zig](https://ziglang.org/) instead of
[AssemblyScript](https://www.assemblyscript.org/).

## Running locally

Build:

```
$ zig version
0.9.0
$ zig build
```

Play locally (requires [w4](https://wasm4.org/docs/getting-started/setup)):

```
$ w4 -V
2.0.0
$ w4 run zig-out/lib/cart.wasm
```

You can also play in w4's wasm engine instead of a browser. For me this fails
mysteriously on debug builds (but works when compiling with e.g.
`-Drelease-small=true`).

```
$ w4 run-native zig-out/lib/cart.wasm
```

## Thoughts

I'm new to zig, wasm, and wasm4, so this is mostly just a learning exercise.

While zig's error reporting for undefined behavior in debug builds is pretty
good normally, I haven't been able to get anything useful in this environment.
Pretty much just `line 1 > WebAssembly.instantiate:2930`.

Other than that I had fun playing with zig, and appreciated the control over
memory for this kind of constrained environment. I had fun playing a bit with
compile-time logic while writing a logging hook that works without a heap. (I
know I could've wired up a standard allocator to a fixed-size buffer, but I
wanted to control memory usage more tightly)
