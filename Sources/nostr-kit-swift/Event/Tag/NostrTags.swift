import RAW
import RAW_dh25519

/// Returns the first tag in `tags` that can be unwrapped as `T`.
///
/// - Parameters:
///   - tags: The tags to search.
///   - type: The concrete tag type to match.
/// - Returns: The first matching tag, or `nil` if none match.
public func findTag<T: NOSTR_tag>(tags: [any NOSTR_tag], as type: T.Type = T.self) -> T? {
	for tag in tags {
		guard let typedTag = tag.unwrap(as: type) else { continue }
		return typedTag
	}
	return nil
}

/// A generic, untyped tag holding a string value and an arbitrary name.
@NostrTag
public struct StringTag: Sendable, Hashable, Equatable, NOSTR_tag {
	/// The tag's index field (its name).
	public var indexField: NOSTR_tag_name
	/// The tag's value.
	public var value: Encoded.String
	/// Creates a generic tag from a name and a string value.
	///
	/// Returns `nil` if `name` is longer than `NOSTR_tag_name.maxNameBytes`.
	public init?(name:String, value: String) {
		guard let indexField = NOSTR_tag_name(string: name) else { return nil }
		self.indexField = indexField
		self.value = Encoded.String(value)
	}
}

/// An event tag referencing another signed event by its id.
@NostrTag(name: "e", valueType: NOSTR_id.self)
public struct EventRefTag: Sendable, Hashable, Equatable, NOSTR_tag {}

extension PublicKey: NOSTR_tag_value {}
/// An event tag referencing another user/author by public key.
@NostrTag(name: "p", valueType: PublicKey.self)
public struct UserTag: Sendable, Hashable, Equatable, NOSTR_tag {}

/// An event tag describing a user's access level.
@NostrTag(name: "perm", valueType: RAW_byte.self)
public struct AccessLevelTag: Sendable, Hashable, Equatable, NOSTR_tag {}

/// An event tag holding the name of a user's permission.
@NostrTag(name: "permName", valueType: Encoded.String.self)
public struct AccessLevelNameTag: Sendable, Hashable, Equatable, NOSTR_tag {}

/// An event d-tag, which adds uniqueness on top of the public key and kind for an
/// event (used by parameterized replaceable events).
@NostrTag(name: "d", valueType: Encoded.String.self)
public struct DTag: Sendable, Hashable, Equatable, NOSTR_tag {
	/// Creates a d-tag from a raw, access-encodable value.
	public init?(raw: any RAW_accessible) {
		var value: Encoded.String?
		raw.RAW_access_immutable { ptr in
			value = Encoded.String(RAW_decode: UnsafeRawBufferPointer(ptr))
		}
		guard let value = value else { return nil }
		self.value = value
	}
}
