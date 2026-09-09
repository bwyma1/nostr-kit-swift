import Foundation
import RAW

/// The name and index field of a `NOSTR_tag`.
///
/// The name is stored as a fixed-width, NUL-padded 8-byte field, so only names of
/// up to 8 UTF-8 bytes can be represented.
@RAW_staticbuff(bytes:8)
public struct NOSTR_tag_name:Sendable, Hashable, Comparable {
	/// The fixed width (in bytes) of the tag-name wire field.
	public static let maxNameBytes: Int = 8

	/// The tag name as a Swift `String`.
	///
	/// The name is stored in a fixed-width, NUL-padded 8-byte field. This decodes
	/// only the bytes up to the first NUL (the padding), so trailing zero bytes are
	/// never included. Returns `nil` if the stored bytes are not valid UTF-8.
	public var string: String? {
		self.RAW_access_immutable { (ptr: UnsafeBufferPointer<UInt8>) -> String? in
			guard let base = ptr.baseAddress else { return nil }
			let count = ptr.count
			var len = 0
			while len < count && base[len] != 0 {
				len += 1
			}
			guard len > 0 else { return "" } // all-NUL → empty name
			let slice = UnsafeBufferPointer(start: base, count: len)
			return String(bytes: slice, encoding: .utf8)
		}
	}
}

extension NOSTR_tag_name {
	/// Constructs a tag name from a Swift `String`.
	///
	/// Returns `nil` if the UTF-8 encoding of `string` is longer than `maxNameBytes`
	/// (the fixed width of the wire field) or cannot be UTF-8 encoded. It never
	/// silently truncates: a name too long to represent is rejected rather than
	/// corrupted. The stored bytes are zero-padded to the full 8-byte field width,
	/// so shorter names round-trip deterministically (no out-of-bounds reads and no
	/// garbage tail bytes).
	public init?(string: String) {
		guard let data = string.data(using: .utf8) else { return nil }
		guard data.count <= Self.maxNameBytes else { return nil }
		var bytes = [UInt8](repeating: 0, count: Self.maxNameBytes)
		for (index, byte) in data.enumerated() {
			bytes[index] = byte
		}
		self = bytes.withUnsafeBytes { (buf: UnsafeRawBufferPointer) in
			NOSTR_tag_name(RAW_staticbuff: buf.load(as: NOSTR_tag_name.RAW_fixed_type.self))
		}
	}
}