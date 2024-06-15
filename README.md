# iSPASS

An open-source [`SPASS` Theorem Prover](https://www.mpi-inf.mpg.de/departments/automation-of-logic/software/spass-workbench/classic-spass-theorem-prover) app for iOS/iPadOS, written in SwiftUI and leveraging the `WkWebView` API (from WebKit) for headless execution.

SPASS is an automated theorem prover that can resolve the validity of formulas and display computed proofs using [first-order propositional logic](https://en.wikipedia.org/wiki/First-order_logic). iSPASS is powered by SPwasSm, a custom-built WebAssembly-based implementation of the SPASS command-line application which uses a minimal JavaScript polyfill to support the WASI API on the web, and some JavaScript for interoperation between Swift and WebAssembly. It provides great performance, thanks to JIT compilation of the WASM-compiled C code using Apple's native support for WASM binaries in WebKit.

In its present (prototype) state, iSPASS will successfully run `SPASS -DocProof` on any valid theorem file (`.spass` extension) via a built-in file picker, and should work on the same files as the desktop application.

Future versions will feature improved exception handling, a tailored theorem file editor with syntax highlighting and more.

I also plan to separate out and extend the functionality of the WASI-on-iOS engine into its own library, improving the polyfill's feature set in order to turn it into a fully-fledged standalone product for embedding platform-agnostic code targeting WASI (Rust, C, C++, etc.) in any iOS app.

Special thanks to [Dr. Nicolas Holzschuch](https://github.com/holzschu/) for inspiring this project and supporting me throughout this journey thus far 🙌
