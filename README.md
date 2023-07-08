# nand7400

An assembler library for the nand7400 computer, created by me during my internship at [The WCL](https://thewcl.com).

This library is built in Rust, and also binds directly to Swift as well, so you can treat it like a standard Swift package (see [Usage](#usage)). Swift bindings are made because the nand7400 computer is mainly programmed via an iOS/MacOS app.

## Usage

### Rust

You can use this library as any other standard rust library, no strings attached. Just add it to your `Cargo.toml` and you're good to go.

### Swift

This library is _almost_ plug-and-play with `Xcode`. To use this with `Xcode`, you need to go into `Targets > (your build target) > Build Phases > Link Binary With Libraries` and add the `nand7400` framework inside the library (It's the icon that looks like a bank or museum under the package). Otherwise, you will get a `module not found` error, because `Xcode` doesn't know where to find the framework powering the library.

## Building

### Lay of the Land

To get started building, you should first familiarize yourself with the project structure. There are 3 main packages in this repository:

-   `nand7400`: The rust library itself. This contains bindings to `UniFFI` under the `uniffi` feature. The cargo workspace file for this is `Cargo.toml`.

-   `bindings/swift`: The Swift package that binds to the `nand7400` rust library. The package file for this is `Package.swift`.

-   `uniffi-bindgen`: A wrapper rust library that is used to execute `uniffi-bindgen` commands. The cargo workspace file for this is `Cargo.toml`.

### Rust

To build the rust library, simply run `cargo build` in the root directory of the project. You can use this library as any other standard rust library.

### Swift

> **_IMPORTANT!_**
>
> If you change the `uniffi` version in the `nand7400` package, you **_MUST_** change it **_EVERYWHERE_** else in the package. Otherwise, it will not compile correctly in Xcode (you will see a symbols missing/undefined error). There is a global `uniffi` version set in `Cargo.toml`, which is used by default and should mitigate this issue. However, it is still a good idea to keep this in mind.

To build this library for Swift, you'll need a Mac with Xcode 12 or later that has the standard rust toolchain (`rustup` and `cargo`) installed. To install certain Rust utilities and targets for building, run `make setup`. Then, to build, run `make package-swift`. This creates a `Nand7400FFI.xcframework` folder, a `Nand7400FFI.xcframework.zip` file, and a `Nand7400FFI.xcframework.zip.sha256` checksum in the `target` directory. You can then either upload `Nand7400FFI.xcframework.zip` to be downloaded by the package, or point the package binary target path to the `Nand7400FFI.xcframework` file.

## Resources on how I did this

These are the resources I used to help me learn how to bind Rust into Swift:

-   [Creating an XCFramework](https://rhonabwy.com/2023/02/10/creating-an-xcframework/)
-   [UniFFI](https://mozilla.github.io/uniffi-rs/)
-   [The YSwift repository](https://github.com/y-crdt/yswift)

These are the resources I used to help me work with Nom:

-   [Error recovery with parser combinators (using nom)](https://eyalkalderon.com/blog/nom-error-recovery/)

## TODO:

-   [ ] Labels are 16 bits wide, not 8 (and count as 2 arguments respectively).
-   [ ] Clean up code.
