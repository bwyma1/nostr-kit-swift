import RAW
extension RAW_accessible where Self: RAW_encodable & RAW_decodable {
	/// Provides read-only access to the value's encoded bytes.
	///
	/// Encodes the value into a temporary buffer, runs `body` with a read-only view
	/// of those bytes, and rethrows any error thrown by `body`.
	public func RAW_access<R, E>(_ body: (UnsafeBufferPointer<UInt8>) throws(E) -> R) throws(E) -> R where E : Error {
		var count: RAW.size_t = 0
		self.RAW_encode(count: &count)

		do {
			return try withUnsafeTemporaryAllocation(
				byteCount: count,
				alignment: MemoryLayout<UInt8>.alignment
			) { rawBuffer in
				let base = rawBuffer.baseAddress!.assumingMemoryBound(to: UInt8.self)
				_ = self.RAW_encode(dest: base)

				let buffer = UnsafeBufferPointer(start: base, count: count)
				return try body(buffer)
			}
		} catch {
			throw error as! E
		}
	}

	/// Provides read-write access to the value's encoded bytes.
	///
	/// Encodes the value into a temporary buffer, runs `body` with a mutable view of
	/// those bytes, then re-decodes the (possibly modified) bytes back into the
	/// value. If the modified bytes no longer decode to a valid value, the mutation
	/// is rejected with `RAWAccessError.invalidMutatedState`. Rethrows any error
	/// thrown by `body`.
	public mutating func RAW_access_mutating<R, E>(_ body: (UnsafeMutableBufferPointer<UInt8>) throws(E) -> R) throws(E) -> R where E : Error {
		var count: RAW.size_t = 0
		self.RAW_encode(count: &count)

		do {
			return try withUnsafeTemporaryAllocation(
				byteCount: count,
				alignment: MemoryLayout<UInt8>.alignment
			) { rawBuffer in
				let base = rawBuffer.baseAddress!.assumingMemoryBound(to: UInt8.self)
				_ = self.RAW_encode(dest: base)

				let buffer = UnsafeMutableBufferPointer(start: base, count: count)
				let result = try body(buffer)

				let readPtr = UnsafeRawPointer(base)
				guard let decoded = Self(
					RAW_decode: readPtr,
					count: count
				) else {
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
