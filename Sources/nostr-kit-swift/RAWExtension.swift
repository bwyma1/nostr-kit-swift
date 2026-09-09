import RAW

extension RAW_encodable {
	/// v22 raw-pointer encode requirement default: funnels to the byte-pointer
	/// `RAW_encode(dest:)` form that this module's types implement.
	@discardableResult
	public func RAW_encode(_: UnsafeMutableRawPointer.Type, destination: UnsafeMutableRawPointer) -> UnsafeMutableRawPointer {
		return UnsafeMutableRawPointer(RAW_encode(dest: destination.assumingMemoryBound(to: UInt8.self)))
	}
}

extension RAW_staticbuff {
	/// v22's `@RAW_staticbuff` macro no longer generates a per-type
	/// `RAW_encode(count:)`, so every fixed-width type falls back to rawdog's
	/// assign-style default (`count = buffer.count`). That clobbers composite
	/// encoders that accumulate member sizes into an inout counter (the idiom
	/// used throughout this library and its macros). Add instead.
	public borrowing func RAW_encode(count: inout Int) {
		count += MemoryLayout<RAW_fixed_type>.size
	}
}

extension RAW_accessible_immutable where Self: RAW_encodable & RAW_decodable {
	/// Provides read-only access to the value's encoded bytes.
	///
	/// Encodes the value into a temporary buffer, runs `body` with a read-only view
	/// of those bytes, and rethrows any error thrown by `body`.
	public func RAW_access_immutable<R, E>(_: UnsafeRawBufferPointer.Type, _ body: (UnsafeRawBufferPointer) throws(E) -> R) throws(E) -> R where E: Swift.Error {
		var count = 0
		self.RAW_encode(count: &count)

		do {
			return try withUnsafeTemporaryAllocation(
				byteCount: count,
				alignment: MemoryLayout<UInt8>.alignment
			) { rawBuffer in
				let base = rawBuffer.baseAddress!
				_ = self.RAW_encode(UnsafeMutableRawPointer.self, destination: base)

				let buffer = UnsafeRawBufferPointer(start: base, count: count)
				return try body(buffer)
			}
		} catch {
			throw error as! E
		}
	}
}

extension RAW_accessible_mutable where Self: RAW_encodable & RAW_decodable {
	/// Provides read-write access to the value's encoded bytes.
	///
	/// Encodes the value into a temporary buffer, runs `body` with a mutable view of
	/// those bytes, then re-decodes the (possibly modified) bytes back into the
	/// value. If the modified bytes no longer decode to a valid value, the mutation
	/// is rejected with `RAWAccessError.invalidMutatedState`. Rethrows any error
	/// thrown by `body`.
	public mutating func RAW_access_mutable<R, E>(_: UnsafeMutableRawBufferPointer.Type, _ body: (UnsafeMutableRawBufferPointer) throws(E) -> R) throws(E) -> R where E: Swift.Error {
		var count = 0
		self.RAW_encode(count: &count)

		do {
			return try withUnsafeTemporaryAllocation(
				byteCount: count,
				alignment: MemoryLayout<UInt8>.alignment
			) { rawBuffer in
				let base = rawBuffer.baseAddress!
				_ = self.RAW_encode(UnsafeMutableRawPointer.self, destination: base)

				let buffer = UnsafeMutableRawBufferPointer(start: base, count: count)
				let result = try body(buffer)

				guard let decoded = Self(RAW_decode: UnsafeRawBufferPointer(start: base, count: count)) else {
					throw RAWAccessError.invalidMutatedState
				}

				self = decoded
				return result
			}
		} catch {
			throw error as! E
		}
	}
}

/// An error thrown when a raw-access mutation produces an invalid state.
public enum RAWAccessError: Error {
	/// The mutated bytes could not be decoded back into a valid value.
	case invalidMutatedState
}
