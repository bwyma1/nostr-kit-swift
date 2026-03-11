import RAW
extension RAW_accessible where Self: RAW_encodable & RAW_decodable {
	public func RAW_access<R, E>(_ body: (UnsafeBufferPointer<UInt8>) throws(E) -> R) throws(E) -> R where E : Error {
		var count: RAW.size_t = 0
		self.RAW_encode(count: &count)
		
		return try! withUnsafeTemporaryAllocation(
			byteCount: count,
			alignment: MemoryLayout<UInt8>.alignment
		) { rawBuffer in
			let base = rawBuffer.baseAddress!.assumingMemoryBound(to: UInt8.self)
			_ = self.RAW_encode(dest: base)

			let buffer = UnsafeBufferPointer(start: base, count: count)
			return try body(buffer)
		}
	}
	
	public mutating func RAW_access_mutating<R, E>(_ body: (UnsafeMutableBufferPointer<UInt8>) throws(E) -> R) throws(E) -> R where E : Error {
		var count: RAW.size_t = 0
		self.RAW_encode(count: &count)

		return try! withUnsafeTemporaryAllocation(
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
				fatalError("RAW_access_mutating produced invalid state")
			}

			self = decoded
			return result
		}
	}
}
