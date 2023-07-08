use config::Opcode;
use miette::Diagnostic;
pub use nand7400::config;
use nand7400::errors::AssemblerError as RustAssemblerError;
use nand7400::{config::AssemblerConfig, Assembler as RustAssembler};
use snafu::Snafu;
use std::sync::Mutex;

// Need to include this so that UniFFI scaffolding is generated.
uniffi::include_scaffolding!("ffi");

/// The FFI-safe version of the assembler from the `nand7400` crate.
pub struct Assembler {
    /// This is the inner assembler that is run in a mutex. The mutex is needed because UniFFI requires that all
    /// bound functions are Send, Sync, and have no mutable reference functions. The mutex is used to ensure that
    /// only one thread can access the inner assembler at a time, and also act like a RefCell so that the inner
    /// assembler can be mutated without using a mutable reference function.
    inner: Mutex<RustAssembler>,
}

/// Public API for the assembler.
impl Assembler {
    /// Create a new assembler with the given configuration.
    pub fn new(config: AssemblerConfig) -> Self {
        Self {
            inner: Mutex::new(RustAssembler::new(config)),
        }
    }

    /// Replaces the configuration of the assembler with the given one.
    pub fn set_config(&self, config: AssemblerConfig) {
        self.inner
            .lock()
            .as_mut()
            .expect("An internal Mutex was poisoned! Some thread must have panicked while holding onto this Mutex!") 
            .set_config(config);
    }

    /// Assembles the given assembly code into binary.
    pub fn assemble(&self, source: &str) -> Result<Vec<u8>, AssemblerError> {
        self.inner
            .lock()
            .as_mut()
            .expect("An internal Mutex was poisoned! Some thread must have panicked while holding onto this Mutex!")
            .assemble(source)
            .map_err(|err| AssemblerError::AssemblerError { source: err })
    }
}

/// The assembler error type. This is a wrapper around the error type from the `nand7400` crate. It has to be an
/// enum because UniFFI doesn't support dictionary errors yet.
#[derive(Clone, Debug, Snafu, Diagnostic)]
pub enum AssemblerError {
    /// Just a wrapper around an error.
    #[diagnostic()]
    #[snafu(display("{}", source))]
    AssemblerError {
        #[diagnostic_source]
        source: RustAssemblerError,
    },
}