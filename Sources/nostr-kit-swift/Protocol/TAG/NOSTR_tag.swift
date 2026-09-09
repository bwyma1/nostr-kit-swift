import Foundation
import RAW

/// A value that can be used as the value portion of a `NOSTR_tag`.
///
/// Tag values are raw, encodable scalars such as strings, integers, dates, or
/// event references.
public protocol NOSTR_tag_value: Sendable, Hashable, Comparable, RAW_decodable, RAW_encodable, RAW_accessible { }

extension NOSTR_tag_value {
	/// Returns whether `self` and `other` encode to identical bytes.
	public func isEqual(to other: any NOSTR_tag_value) -> Bool {
		return self.RAW_access_immutable { aPtr in
			other.RAW_access_immutable { bPtr in
				guard aPtr.count == bPtr.count else { return false }
				return memcmp(aPtr.baseAddress!, bPtr.baseAddress!, aPtr.count) == 0
			}
		}
	}
}

/// A `NOSTR_tag` is an array of one or more items.
///
/// The first item is always an index field of type `NOSTR_tag_name`. Every
/// following item is a value associated with that index field; values may be any
/// type that conforms to `NOSTR_tag_value`. See `NOSTR_tag_generic_value` for an
/// example tag value.
///
/// - Note: Tags cannot be empty, and must have a name of at least one character.
public protocol NOSTR_tag: Sendable, Hashable, RAW_decodable, RAW_encodable, RAW_accessible {
	associatedtype tagValueType: NOSTR_tag_value

	var indexField: NOSTR_tag_name { get }

	var value: tagValueType { get set }

	var name: String? { get }
}

extension NOSTR_tag {
	/// The tag name, decoded from the index field as a Swift `String`.
	///
	/// Returns `nil` if the stored bytes are not valid UTF-8.
	public var name: String? {
		indexField.string
	}
}

extension NOSTR_tag {
	/// Unwraps the tag as the specified concrete tag type.
	///
	/// This is the primary way to convert a generalized `any NOSTR_tag` into a
	/// more concrete tag form. Returns `nil` if the bytes cannot be decoded as `T`.
	public func unwrap<T: NOSTR_tag>(as type: T.Type = T.self) -> T? {
		self.RAW_access_immutable { ptr in
			guard let unwrappedTag = T(RAW_decode: UnsafeRawBufferPointer(ptr)) else { return nil }
			return unwrappedTag
		}
	}
}

extension NOSTR_tag {
	/// Returns whether `self` and `other` encode to identical bytes.
	public func isEqual(to other: any NOSTR_tag) -> Bool {
		return self.RAW_access_immutable { aPtr in
			other.RAW_access_immutable { bPtr in
				guard aPtr.count == bPtr.count else { return false }
				return memcmp(aPtr.baseAddress!, bPtr.baseAddress!, aPtr.count) == 0
			}
		}
	}
}
