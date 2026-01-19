import Foundation
import RAW

public protocol NOSTR_tag_value: Sendable, Comparable, RAW_convertible, RAW_accessible { }

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
public protocol NOSTR_tag: Sendable, Comparable, RAW_convertible {
	
	var NOSTR_tag_index_field:NOSTR_tag_name { get }
	
	var NOSTR_tag_values:[any NOSTR_tag_value] { get }
	
	init(NOSTR_tag_index_field:NOSTR_tag_name, NOSTR_tag_values:[any NOSTR_tag_value]) throws
}

/// Generic comparable implementation for any tag.
/// Compares the `NOSTR_tag_index_field` and the array of `NOSTR_tag_value`.
/// Override if needed.
extension NOSTR_tag {
	public static func compareValues(_ lhs: any NOSTR_tag_value,_ rhs: any NOSTR_tag_value) -> Bool {
		return lhs.RAW_access { lhsPtr in
			rhs.RAW_access { rhsPtr in
				let minLen = min(lhsPtr.count, rhsPtr.count)
				let cmp = memcmp(lhsPtr.baseAddress!, rhsPtr.baseAddress!, minLen)
				if cmp != 0 { return cmp < 0 }
				return lhsPtr.count < rhsPtr.count
			}
		}
	}
	
	public func isEqual(to other: any NOSTR_tag) -> Bool {
		guard let other = other as? Self else { return false }
		return self == other
	}

	public static func == (lhs: Self, rhs: Self) -> Bool {
		guard lhs.NOSTR_tag_index_field == rhs.NOSTR_tag_index_field else {
			return false
		}
		guard lhs.NOSTR_tag_values.count == rhs.NOSTR_tag_values.count else {
			return false
		}
		var rhsRemaining = rhs.NOSTR_tag_values

		for lVal in lhs.NOSTR_tag_values {
			var foundIndex: Int? = nil
			for (i, rVal) in rhsRemaining.enumerated() {
				if lVal.isEqual(to: rVal) {
					foundIndex = i
					break
				}
			}
			guard let idx = foundIndex else { return false }
			rhsRemaining.remove(at: idx)
		}

		return true
	}

	public static func < (lhs: Self, rhs: Self) -> Bool {
		if lhs.NOSTR_tag_index_field != rhs.NOSTR_tag_index_field {
			return lhs.NOSTR_tag_index_field < rhs.NOSTR_tag_index_field
		}
		if lhs.NOSTR_tag_values.count != rhs.NOSTR_tag_values.count {
			return lhs.NOSTR_tag_values.count < rhs.NOSTR_tag_values.count
		}
		let lhsSorted = lhs.NOSTR_tag_values.sorted(by: compareValues)
		let rhsSorted = rhs.NOSTR_tag_values.sorted(by: compareValues)
		
		for (lVal, rVal) in zip(lhsSorted, rhsSorted) {
			if compareValues(lVal, rVal) { return true }
			if compareValues(rVal, lVal) { return false }
		}
		return false
	}
}
