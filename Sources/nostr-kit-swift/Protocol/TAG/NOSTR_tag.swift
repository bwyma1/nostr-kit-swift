import Foundation
import RAW

public protocol NOSTR_tag_value: Sendable, Hashable, Comparable, RAW_convertible, RAW_accessible { }

extension NOSTR_tag_value {
	public func isEqual(to other: any NOSTR_tag_value) -> Bool {
		return self.RAW_access { aPtr in
			other.RAW_access { bPtr in
				guard aPtr.count == bPtr.count else { return false }
				return memcmp(aPtr.baseAddress!, bPtr.baseAddress!, aPtr.count) == 0
			}
		}
	}
}

/// A `NOSTR_tag` is an array of one or more items
/// The first item in a `NOSTR_tag` will always be an index field with a type `NOSTR_tag_name`
/// Every other item following the index field is a value associated to the specified index field.
/// The values must be any type that conforms to `RAW_convertible`.
/// See `NOSTR_tag_generic_value` for an example tag value.
/// - examples of tags include:
/// 	- as attached to nostr events
/// 		- `["challenge", "some-challenge-string"]`
/// 		- `["auth", "some-auth-token"]`
/// 		- `["#p", "dynamic tag name"]`
///		- as attached to relay filters (dynamic tags only)
///			- `{"#p", "dynamic tag name"...}`
/// - note: tags cannot be empty, and must have a name of at least one character.
public protocol NOSTR_tag: Sendable, Hashable, RAW_convertible, RAW_accessible {
	associatedtype tagValueType: NOSTR_tag_value
	
	var indexField: NOSTR_tag_name { get }
	
	var value: tagValueType { get set }
	
	var name: String? { get }
}

extension NOSTR_tag {
	public var name: String? {
		indexField.string
	}
}

extension NOSTR_tag {
	/// Unwrap the tag as the specified struct conforming to `NOSTR_tag`.
	/// The primary function to convert from the generalized `any NOSTR_tag` to
	/// a more concrete tag form.
	public func unwrap<T: NOSTR_tag>(as type: T.Type = T.self) -> T? {
		self.RAW_access { ptr in
			guard let unwrappedTag = T(RAW_accessed: ptr) else { return nil }
			return unwrappedTag
		}
	}
}

extension NOSTR_tag {
	public func isEqual(to other: any NOSTR_tag) -> Bool {
		return self.RAW_access { aPtr in
			other.RAW_access { bPtr in
				guard aPtr.count == bPtr.count else { return false }
				return memcmp(aPtr.baseAddress!, bPtr.baseAddress!, aPtr.count) == 0
			}
		}
	}
}
