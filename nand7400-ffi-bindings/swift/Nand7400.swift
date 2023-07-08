// This file was autogenerated by some hot garbage in the `uniffi` crate.
// Trust me, you don't want to mess with it!
import Foundation

// Depending on the consumer's build setup, the low-level FFI code
// might be in a separate module, or it might be compiled inline into
// this module. This is a bit of light hackery to work with both.
#if canImport(Nand7400FFI)
    import Nand7400FFI
#endif

private extension RustBuffer {
    // Allocate a new buffer, copying the contents of a `UInt8` array.
    init(bytes: [UInt8]) {
        let rbuf = bytes.withUnsafeBufferPointer { ptr in
            RustBuffer.from(ptr)
        }
        self.init(capacity: rbuf.capacity, len: rbuf.len, data: rbuf.data)
    }

    static func from(_ ptr: UnsafeBufferPointer<UInt8>) -> RustBuffer {
        try! rustCall { ffi_Nand7400_rustbuffer_from_bytes(ForeignBytes(bufferPointer: ptr), $0) }
    }

    // Frees the buffer in place.
    // The buffer must not be used after this is called.
    func deallocate() {
        try! rustCall { ffi_Nand7400_rustbuffer_free(self, $0) }
    }
}

private extension ForeignBytes {
    init(bufferPointer: UnsafeBufferPointer<UInt8>) {
        self.init(len: Int32(bufferPointer.count), data: bufferPointer.baseAddress)
    }
}

// For every type used in the interface, we provide helper methods for conveniently
// lifting and lowering that type from C-compatible data, and for reading and writing
// values of that type in a buffer.

// Helper classes/extensions that don't change.
// Someday, this will be in a library of its own.

private extension Data {
    init(rustBuffer: RustBuffer) {
        // TODO: This copies the buffer. Can we read directly from a
        // Rust buffer?
        self.init(bytes: rustBuffer.data!, count: Int(rustBuffer.len))
    }
}

// Define reader functionality.  Normally this would be defined in a class or
// struct, but we use standalone functions instead in order to make external
// types work.
//
// With external types, one swift source file needs to be able to call the read
// method on another source file's FfiConverter, but then what visibility
// should Reader have?
// - If Reader is fileprivate, then this means the read() must also
//   be fileprivate, which doesn't work with external types.
// - If Reader is internal/public, we'll get compile errors since both source
//   files will try define the same type.
//
// Instead, the read() method and these helper functions input a tuple of data

private func createReader(data: Data) -> (data: Data, offset: Data.Index) {
    (data: data, offset: 0)
}

// Reads an integer at the current offset, in big-endian order, and advances
// the offset on success. Throws if reading the integer would move the
// offset past the end of the buffer.
private func readInt<T: FixedWidthInteger>(_ reader: inout (data: Data, offset: Data.Index)) throws -> T {
    let range = reader.offset ..< reader.offset + MemoryLayout<T>.size
    guard reader.data.count >= range.upperBound else {
        throw UniffiInternalError.bufferOverflow
    }
    if T.self == UInt8.self {
        let value = reader.data[reader.offset]
        reader.offset += 1
        return value as! T
    }
    var value: T = 0
    let _ = withUnsafeMutableBytes(of: &value) { reader.data.copyBytes(to: $0, from: range) }
    reader.offset = range.upperBound
    return value.bigEndian
}

// Reads an arbitrary number of bytes, to be used to read
// raw bytes, this is useful when lifting strings
private func readBytes(_ reader: inout (data: Data, offset: Data.Index), count: Int) throws -> [UInt8] {
    let range = reader.offset ..< (reader.offset + count)
    guard reader.data.count >= range.upperBound else {
        throw UniffiInternalError.bufferOverflow
    }
    var value = [UInt8](repeating: 0, count: count)
    value.withUnsafeMutableBufferPointer { buffer in
        reader.data.copyBytes(to: buffer, from: range)
    }
    reader.offset = range.upperBound
    return value
}

// Reads a float at the current offset.
private func readFloat(_ reader: inout (data: Data, offset: Data.Index)) throws -> Float {
    return try Float(bitPattern: readInt(&reader))
}

// Reads a float at the current offset.
private func readDouble(_ reader: inout (data: Data, offset: Data.Index)) throws -> Double {
    return try Double(bitPattern: readInt(&reader))
}

// Indicates if the offset has reached the end of the buffer.
private func hasRemaining(_ reader: (data: Data, offset: Data.Index)) -> Bool {
    return reader.offset < reader.data.count
}

// Define writer functionality.  Normally this would be defined in a class or
// struct, but we use standalone functions instead in order to make external
// types work.  See the above discussion on Readers for details.

private func createWriter() -> [UInt8] {
    return []
}

private func writeBytes<S>(_ writer: inout [UInt8], _ byteArr: S) where S: Sequence, S.Element == UInt8 {
    writer.append(contentsOf: byteArr)
}

// Writes an integer in big-endian order.
//
// Warning: make sure what you are trying to write
// is in the correct type!
private func writeInt<T: FixedWidthInteger>(_ writer: inout [UInt8], _ value: T) {
    var value = value.bigEndian
    withUnsafeBytes(of: &value) { writer.append(contentsOf: $0) }
}

private func writeFloat(_ writer: inout [UInt8], _ value: Float) {
    writeInt(&writer, value.bitPattern)
}

private func writeDouble(_ writer: inout [UInt8], _ value: Double) {
    writeInt(&writer, value.bitPattern)
}

// Protocol for types that transfer other types across the FFI. This is
// analogous go the Rust trait of the same name.
private protocol FfiConverter {
    associatedtype FfiType
    associatedtype SwiftType

    static func lift(_ value: FfiType) throws -> SwiftType
    static func lower(_ value: SwiftType) -> FfiType
    static func read(from buf: inout (data: Data, offset: Data.Index)) throws -> SwiftType
    static func write(_ value: SwiftType, into buf: inout [UInt8])
}

// Types conforming to `Primitive` pass themselves directly over the FFI.
private protocol FfiConverterPrimitive: FfiConverter where FfiType == SwiftType {}

extension FfiConverterPrimitive {
    public static func lift(_ value: FfiType) throws -> SwiftType {
        return value
    }

    public static func lower(_ value: SwiftType) -> FfiType {
        return value
    }
}

// Types conforming to `FfiConverterRustBuffer` lift and lower into a `RustBuffer`.
// Used for complex types where it's hard to write a custom lift/lower.
private protocol FfiConverterRustBuffer: FfiConverter where FfiType == RustBuffer {}

extension FfiConverterRustBuffer {
    public static func lift(_ buf: RustBuffer) throws -> SwiftType {
        var reader = createReader(data: Data(rustBuffer: buf))
        let value = try read(from: &reader)
        if hasRemaining(reader) {
            throw UniffiInternalError.incompleteData
        }
        buf.deallocate()
        return value
    }

    public static func lower(_ value: SwiftType) -> RustBuffer {
        var writer = createWriter()
        write(value, into: &writer)
        return RustBuffer(bytes: writer)
    }
}

// An error type for FFI errors. These errors occur at the UniFFI level, not
// the library level.
private enum UniffiInternalError: LocalizedError {
    case bufferOverflow
    case incompleteData
    case unexpectedOptionalTag
    case unexpectedEnumCase
    case unexpectedNullPointer
    case unexpectedRustCallStatusCode
    case unexpectedRustCallError
    case unexpectedStaleHandle
    case rustPanic(_ message: String)

    public var errorDescription: String? {
        switch self {
        case .bufferOverflow: return "Reading the requested value would read past the end of the buffer"
        case .incompleteData: return "The buffer still has data after lifting its containing value"
        case .unexpectedOptionalTag: return "Unexpected optional tag; should be 0 or 1"
        case .unexpectedEnumCase: return "Raw enum value doesn't match any cases"
        case .unexpectedNullPointer: return "Raw pointer value was null"
        case .unexpectedRustCallStatusCode: return "Unexpected RustCallStatus code"
        case .unexpectedRustCallError: return "CALL_ERROR but no errorClass specified"
        case .unexpectedStaleHandle: return "The object in the handle map has been dropped already"
        case let .rustPanic(message): return message
        }
    }
}

private let CALL_SUCCESS: Int8 = 0
private let CALL_ERROR: Int8 = 1
private let CALL_PANIC: Int8 = 2

private extension RustCallStatus {
    init() {
        self.init(
            code: CALL_SUCCESS,
            errorBuf: RustBuffer(
                capacity: 0,
                len: 0,
                data: nil
            )
        )
    }
}

private func rustCall<T>(_ callback: (UnsafeMutablePointer<RustCallStatus>) -> T) throws -> T {
    try makeRustCall(callback, errorHandler: nil)
}

private func rustCallWithError<T>(
    _ errorHandler: @escaping (RustBuffer) throws -> Error,
    _ callback: (UnsafeMutablePointer<RustCallStatus>) -> T
) throws -> T {
    try makeRustCall(callback, errorHandler: errorHandler)
}

private func makeRustCall<T>(
    _ callback: (UnsafeMutablePointer<RustCallStatus>) -> T,
    errorHandler: ((RustBuffer) throws -> Error)?
) throws -> T {
    uniffiEnsureInitialized()
    var callStatus = RustCallStatus()
    let returnedVal = callback(&callStatus)
    try uniffiCheckCallStatus(callStatus: callStatus, errorHandler: errorHandler)
    return returnedVal
}

private func uniffiCheckCallStatus(
    callStatus: RustCallStatus,
    errorHandler: ((RustBuffer) throws -> Error)?
) throws {
    switch callStatus.code {
    case CALL_SUCCESS:
        return

    case CALL_ERROR:
        if let errorHandler = errorHandler {
            throw try errorHandler(callStatus.errorBuf)
        } else {
            callStatus.errorBuf.deallocate()
            throw UniffiInternalError.unexpectedRustCallError
        }

    case CALL_PANIC:
        // When the rust code sees a panic, it tries to construct a RustBuffer
        // with the message.  But if that code panics, then it just sends back
        // an empty buffer.
        if callStatus.errorBuf.len > 0 {
            throw try UniffiInternalError.rustPanic(FfiConverterString.lift(callStatus.errorBuf))
        } else {
            callStatus.errorBuf.deallocate()
            throw UniffiInternalError.rustPanic("Rust panic")
        }

    default:
        throw UniffiInternalError.unexpectedRustCallStatusCode
    }
}

// Public interface members begin here.

private struct FfiConverterUInt8: FfiConverterPrimitive {
    typealias FfiType = UInt8
    typealias SwiftType = UInt8

    public static func read(from buf: inout (data: Data, offset: Data.Index)) throws -> UInt8 {
        return try lift(readInt(&buf))
    }

    public static func write(_ value: UInt8, into buf: inout [UInt8]) {
        writeInt(&buf, lower(value))
    }
}

private struct FfiConverterUInt16: FfiConverterPrimitive {
    typealias FfiType = UInt16
    typealias SwiftType = UInt16

    public static func read(from buf: inout (data: Data, offset: Data.Index)) throws -> UInt16 {
        return try lift(readInt(&buf))
    }

    public static func write(_ value: SwiftType, into buf: inout [UInt8]) {
        writeInt(&buf, lower(value))
    }
}

private struct FfiConverterUInt32: FfiConverterPrimitive {
    typealias FfiType = UInt32
    typealias SwiftType = UInt32

    public static func read(from buf: inout (data: Data, offset: Data.Index)) throws -> UInt32 {
        return try lift(readInt(&buf))
    }

    public static func write(_ value: SwiftType, into buf: inout [UInt8]) {
        writeInt(&buf, lower(value))
    }
}

private struct FfiConverterString: FfiConverter {
    typealias SwiftType = String
    typealias FfiType = RustBuffer

    public static func lift(_ value: RustBuffer) throws -> String {
        defer {
            value.deallocate()
        }
        if value.data == nil {
            return String()
        }
        let bytes = UnsafeBufferPointer<UInt8>(start: value.data!, count: Int(value.len))
        return String(bytes: bytes, encoding: String.Encoding.utf8)!
    }

    public static func lower(_ value: String) -> RustBuffer {
        return value.utf8CString.withUnsafeBufferPointer { ptr in
            // The swift string gives us int8_t, we want uint8_t.
            ptr.withMemoryRebound(to: UInt8.self) { ptr in
                // The swift string gives us a trailing null byte, we don't want it.
                let buf = UnsafeBufferPointer(rebasing: ptr.prefix(upTo: ptr.count - 1))
                return RustBuffer.from(buf)
            }
        }
    }

    public static func read(from buf: inout (data: Data, offset: Data.Index)) throws -> String {
        let len: Int32 = try readInt(&buf)
        return try String(bytes: readBytes(&buf, count: Int(len)), encoding: String.Encoding.utf8)!
    }

    public static func write(_ value: String, into buf: inout [UInt8]) {
        let len = Int32(value.utf8.count)
        writeInt(&buf, len)
        writeBytes(&buf, value.utf8)
    }
}

private struct FfiConverterData: FfiConverterRustBuffer {
    typealias SwiftType = Data

    public static func read(from buf: inout (data: Data, offset: Data.Index)) throws -> Data {
        let len: Int32 = try readInt(&buf)
        return try Data(bytes: readBytes(&buf, count: Int(len)))
    }

    public static func write(_ value: Data, into buf: inout [UInt8]) {
        let len = Int32(value.count)
        writeInt(&buf, len)
        writeBytes(&buf, value)
    }
}

public protocol AssemblerProtocol {
    func setConfig(config: AssemblerConfig)
    func assemble(source: String) throws -> Data
}

public class Assembler: AssemblerProtocol {
    fileprivate let pointer: UnsafeMutableRawPointer

    // TODO: We'd like this to be `private` but for Swifty reasons,
    // we can't implement `FfiConverter` without making this `required` and we can't
    // make it `required` without making it `public`.
    required init(unsafeFromRawPointer pointer: UnsafeMutableRawPointer) {
        self.pointer = pointer
    }

    public convenience init(config: AssemblerConfig) {
        self.init(unsafeFromRawPointer: try! rustCall {
            uniffi_Nand7400_fn_constructor_assembler_new(
                FfiConverterTypeAssemblerConfig.lower(config), $0
            )
        })
    }

    deinit {
        try! rustCall { uniffi_Nand7400_fn_free_assembler(pointer, $0) }
    }

    public func setConfig(config: AssemblerConfig) {
        try!
            rustCall {
                uniffi_Nand7400_fn_method_assembler_set_config(self.pointer,
                                                               FfiConverterTypeAssemblerConfig.lower(config), $0)
            }
    }

    public func assemble(source: String) throws -> Data {
        return try FfiConverterData.lift(
            rustCallWithError(FfiConverterTypeAssemblerError.lift) {
                uniffi_Nand7400_fn_method_assembler_assemble(self.pointer,
                                                             FfiConverterString.lower(source), $0)
            }
        )
    }
}

public struct FfiConverterTypeAssembler: FfiConverter {
    typealias FfiType = UnsafeMutableRawPointer
    typealias SwiftType = Assembler

    public static func read(from buf: inout (data: Data, offset: Data.Index)) throws -> Assembler {
        let v: UInt64 = try readInt(&buf)
        // The Rust code won't compile if a pointer won't fit in a UInt64.
        // We have to go via `UInt` because that's the thing that's the size of a pointer.
        let ptr = UnsafeMutableRawPointer(bitPattern: UInt(truncatingIfNeeded: v))
        if ptr == nil {
            throw UniffiInternalError.unexpectedNullPointer
        }
        return try lift(ptr!)
    }

    public static func write(_ value: Assembler, into buf: inout [UInt8]) {
        // This fiddling is because `Int` is the thing that's the same size as a pointer.
        // The Rust code won't compile if a pointer won't fit in a `UInt64`.
        writeInt(&buf, UInt64(bitPattern: Int64(Int(bitPattern: lower(value)))))
    }

    public static func lift(_ pointer: UnsafeMutableRawPointer) throws -> Assembler {
        return Assembler(unsafeFromRawPointer: pointer)
    }

    public static func lower(_ value: Assembler) -> UnsafeMutableRawPointer {
        return value.pointer
    }
}

public func FfiConverterTypeAssembler_lift(_ pointer: UnsafeMutableRawPointer) throws -> Assembler {
    return try FfiConverterTypeAssembler.lift(pointer)
}

public func FfiConverterTypeAssembler_lower(_ value: Assembler) -> UnsafeMutableRawPointer {
    return FfiConverterTypeAssembler.lower(value)
}

public struct AssemblerConfig {
    public var opcodes: [Opcode]

    // Default memberwise initializers are never public by default, so we
    // declare one manually.
    public init(opcodes: [Opcode]) {
        self.opcodes = opcodes
    }
}

extension AssemblerConfig: Equatable, Hashable {
    public static func == (lhs: AssemblerConfig, rhs: AssemblerConfig) -> Bool {
        if lhs.opcodes != rhs.opcodes {
            return false
        }
        return true
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(opcodes)
    }
}

public struct FfiConverterTypeAssemblerConfig: FfiConverterRustBuffer {
    public static func read(from buf: inout (data: Data, offset: Data.Index)) throws -> AssemblerConfig {
        return try AssemblerConfig(
            opcodes: FfiConverterSequenceTypeOpcode.read(from: &buf)
        )
    }

    public static func write(_ value: AssemblerConfig, into buf: inout [UInt8]) {
        FfiConverterSequenceTypeOpcode.write(value.opcodes, into: &buf)
    }
}

public func FfiConverterTypeAssemblerConfig_lift(_ buf: RustBuffer) throws -> AssemblerConfig {
    return try FfiConverterTypeAssemblerConfig.lift(buf)
}

public func FfiConverterTypeAssemblerConfig_lower(_ value: AssemblerConfig) -> RustBuffer {
    return FfiConverterTypeAssemblerConfig.lower(value)
}

public struct Opcode {
    public var mnemonic: String
    public var binary: UInt8
    public var numArgs: UInt32

    // Default memberwise initializers are never public by default, so we
    // declare one manually.
    public init(mnemonic: String, binary: UInt8, numArgs: UInt32) {
        self.mnemonic = mnemonic
        self.binary = binary
        self.numArgs = numArgs
    }
}

extension Opcode: Equatable, Hashable {
    public static func == (lhs: Opcode, rhs: Opcode) -> Bool {
        if lhs.mnemonic != rhs.mnemonic {
            return false
        }
        if lhs.binary != rhs.binary {
            return false
        }
        if lhs.numArgs != rhs.numArgs {
            return false
        }
        return true
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(mnemonic)
        hasher.combine(binary)
        hasher.combine(numArgs)
    }
}

public struct FfiConverterTypeOpcode: FfiConverterRustBuffer {
    public static func read(from buf: inout (data: Data, offset: Data.Index)) throws -> Opcode {
        return try Opcode(
            mnemonic: FfiConverterString.read(from: &buf),
            binary: FfiConverterUInt8.read(from: &buf),
            numArgs: FfiConverterUInt32.read(from: &buf)
        )
    }

    public static func write(_ value: Opcode, into buf: inout [UInt8]) {
        FfiConverterString.write(value.mnemonic, into: &buf)
        FfiConverterUInt8.write(value.binary, into: &buf)
        FfiConverterUInt32.write(value.numArgs, into: &buf)
    }
}

public func FfiConverterTypeOpcode_lift(_ buf: RustBuffer) throws -> Opcode {
    return try FfiConverterTypeOpcode.lift(buf)
}

public func FfiConverterTypeOpcode_lower(_ value: Opcode) -> RustBuffer {
    return FfiConverterTypeOpcode.lower(value)
}

public struct Position {
    public var start: UInt32
    public var end: UInt32

    // Default memberwise initializers are never public by default, so we
    // declare one manually.
    public init(start: UInt32, end: UInt32) {
        self.start = start
        self.end = end
    }
}

extension Position: Equatable, Hashable {
    public static func == (lhs: Position, rhs: Position) -> Bool {
        if lhs.start != rhs.start {
            return false
        }
        if lhs.end != rhs.end {
            return false
        }
        return true
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(start)
        hasher.combine(end)
    }
}

public struct FfiConverterTypePosition: FfiConverterRustBuffer {
    public static func read(from buf: inout (data: Data, offset: Data.Index)) throws -> Position {
        return try Position(
            start: FfiConverterUInt32.read(from: &buf),
            end: FfiConverterUInt32.read(from: &buf)
        )
    }

    public static func write(_ value: Position, into buf: inout [UInt8]) {
        FfiConverterUInt32.write(value.start, into: &buf)
        FfiConverterUInt32.write(value.end, into: &buf)
    }
}

public func FfiConverterTypePosition_lift(_ buf: RustBuffer) throws -> Position {
    return try FfiConverterTypePosition.lift(buf)
}

public func FfiConverterTypePosition_lower(_ value: Position) -> RustBuffer {
    return FfiConverterTypePosition.lower(value)
}

public enum AssemblerError {
    case Unexpected(negatives: [String], positives: [String], span: Position)
    case Overflow(literal: String, span: Position)
    case WrongNumArgs(mnemonic: String, expected: UInt16, given: UInt16, opcodeSpan: Position, argsSpan: Position)
    case OpcodeDne(mnemonic: String, span: Position)
    case LabelDne(mnemonic: String, span: Position)

    fileprivate static func uniffiErrorHandler(_ error: RustBuffer) throws -> Error {
        return try FfiConverterTypeAssemblerError.lift(error)
    }
}

public struct FfiConverterTypeAssemblerError: FfiConverterRustBuffer {
    typealias SwiftType = AssemblerError

    public static func read(from buf: inout (data: Data, offset: Data.Index)) throws -> AssemblerError {
        let variant: Int32 = try readInt(&buf)
        switch variant {
        case 1: return try .Unexpected(
                negatives: FfiConverterSequenceString.read(from: &buf),
                positives: FfiConverterSequenceString.read(from: &buf),
                span: FfiConverterTypePosition.read(from: &buf)
            )
        case 2: return try .Overflow(
                literal: FfiConverterString.read(from: &buf),
                span: FfiConverterTypePosition.read(from: &buf)
            )
        case 3: return try .WrongNumArgs(
                mnemonic: FfiConverterString.read(from: &buf),
                expected: FfiConverterUInt16.read(from: &buf),
                given: FfiConverterUInt16.read(from: &buf),
                opcodeSpan: FfiConverterTypePosition.read(from: &buf),
                argsSpan: FfiConverterTypePosition.read(from: &buf)
            )
        case 4: return try .OpcodeDne(
                mnemonic: FfiConverterString.read(from: &buf),
                span: FfiConverterTypePosition.read(from: &buf)
            )
        case 5: return try .LabelDne(
                mnemonic: FfiConverterString.read(from: &buf),
                span: FfiConverterTypePosition.read(from: &buf)
            )

        default: throw UniffiInternalError.unexpectedEnumCase
        }
    }

    public static func write(_ value: AssemblerError, into buf: inout [UInt8]) {
        switch value {
        case let .Unexpected(negatives, positives, span):
            writeInt(&buf, Int32(1))
            FfiConverterSequenceString.write(negatives, into: &buf)
            FfiConverterSequenceString.write(positives, into: &buf)
            FfiConverterTypePosition.write(span, into: &buf)

        case let .Overflow(literal, span):
            writeInt(&buf, Int32(2))
            FfiConverterString.write(literal, into: &buf)
            FfiConverterTypePosition.write(span, into: &buf)

        case let .WrongNumArgs(mnemonic, expected, given, opcodeSpan, argsSpan):
            writeInt(&buf, Int32(3))
            FfiConverterString.write(mnemonic, into: &buf)
            FfiConverterUInt16.write(expected, into: &buf)
            FfiConverterUInt16.write(given, into: &buf)
            FfiConverterTypePosition.write(opcodeSpan, into: &buf)
            FfiConverterTypePosition.write(argsSpan, into: &buf)

        case let .OpcodeDne(mnemonic, span):
            writeInt(&buf, Int32(4))
            FfiConverterString.write(mnemonic, into: &buf)
            FfiConverterTypePosition.write(span, into: &buf)

        case let .LabelDne(mnemonic, span):
            writeInt(&buf, Int32(5))
            FfiConverterString.write(mnemonic, into: &buf)
            FfiConverterTypePosition.write(span, into: &buf)
        }
    }
}

extension AssemblerError: Equatable, Hashable {}

extension AssemblerError: Error {}

private struct FfiConverterSequenceString: FfiConverterRustBuffer {
    typealias SwiftType = [String]

    public static func write(_ value: [String], into buf: inout [UInt8]) {
        let len = Int32(value.count)
        writeInt(&buf, len)
        for item in value {
            FfiConverterString.write(item, into: &buf)
        }
    }

    public static func read(from buf: inout (data: Data, offset: Data.Index)) throws -> [String] {
        let len: Int32 = try readInt(&buf)
        var seq = [String]()
        seq.reserveCapacity(Int(len))
        for _ in 0 ..< len {
            try seq.append(FfiConverterString.read(from: &buf))
        }
        return seq
    }
}

private struct FfiConverterSequenceTypeOpcode: FfiConverterRustBuffer {
    typealias SwiftType = [Opcode]

    public static func write(_ value: [Opcode], into buf: inout [UInt8]) {
        let len = Int32(value.count)
        writeInt(&buf, len)
        for item in value {
            FfiConverterTypeOpcode.write(item, into: &buf)
        }
    }

    public static func read(from buf: inout (data: Data, offset: Data.Index)) throws -> [Opcode] {
        let len: Int32 = try readInt(&buf)
        var seq = [Opcode]()
        seq.reserveCapacity(Int(len))
        for _ in 0 ..< len {
            try seq.append(FfiConverterTypeOpcode.read(from: &buf))
        }
        return seq
    }
}

private enum InitializationResult {
    case ok
    case contractVersionMismatch
    case apiChecksumMismatch
}

// Use a global variables to perform the versioning checks. Swift ensures that
// the code inside is only computed once.
private var initializationResult: InitializationResult {
    // Get the bindings contract version from our ComponentInterface
    let bindings_contract_version = 22
    // Get the scaffolding contract version by calling the into the dylib
    let scaffolding_contract_version = ffi_Nand7400_uniffi_contract_version()
    if bindings_contract_version != scaffolding_contract_version {
        return InitializationResult.contractVersionMismatch
    }
    if uniffi_Nand7400_checksum_method_assembler_set_config() != 8975 {
        return InitializationResult.apiChecksumMismatch
    }
    if uniffi_Nand7400_checksum_method_assembler_assemble() != 16022 {
        return InitializationResult.apiChecksumMismatch
    }
    if uniffi_Nand7400_checksum_constructor_assembler_new() != 22757 {
        return InitializationResult.apiChecksumMismatch
    }

    return InitializationResult.ok
}

private func uniffiEnsureInitialized() {
    switch initializationResult {
    case .ok:
        break
    case .contractVersionMismatch:
        fatalError("UniFFI contract version mismatch: try cleaning and rebuilding your project")
    case .apiChecksumMismatch:
        fatalError("UniFFI API checksum mismatch: try cleaning and rebuilding your project")
    }
}
