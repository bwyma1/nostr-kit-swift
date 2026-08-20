import RAW
import RAW_dh25519

public func findTag<T: NOSTR_tag>(tags: [any NOSTR_tag], as type: T.Type = T.self) -> T? {
	for tag in tags {
		guard let typedTag = tag.unwrap(as: type) else { continue }
		return typedTag
	}
	return nil
}

@NostrTag
public struct GenericTag: Sendable, Hashable, Equatable, NOSTR_tag {
	public var indexField: NOSTR_tag_name
	public var value: EncodedString
	public init?(name:String, value: String) {
		guard let indexField = NOSTR_tag_name(string: name) else { return nil }
		self.indexField = indexField
		self.value = EncodedString(value)
	}
}

/// Initializing an event tag for referencing other `NOSTR_event_signed`
@NostrTag(name: "e", valueType: NOSTR_id.self)
public struct EventRefTag: Sendable, Hashable, Equatable, NOSTR_tag {}

extension PublicKey: NOSTR_tag_value {}
/// Initializing an event tag for referencing other user/author.
@NostrTag(name: "p", valueType: PublicKey.self)
public struct UserTag: Sendable, Hashable, Equatable, NOSTR_tag {}

/// Initializing an event tag for user permissions.
@NostrTag(name: "perm", valueType: RAW_byte.self)
public struct AccessLevelTag: Sendable, Hashable, Equatable, NOSTR_tag {}

/// Initializing an event tag for the name of the user permissions.
@NostrTag(name: "permName", valueType: EncodedString.self)
public struct AccessLevelNameTag: Sendable, Hashable, Equatable, NOSTR_tag {}

/// Initializing an event d-tag for kinds 30000-39999.
/// The d-tag adds a layer of uniqueness on top of the public key and kind for an event.
@NostrTag(name: "d", valueType: EncodedString.self)
public struct DTag: Sendable, Hashable, Equatable, NOSTR_tag {
	public init?(raw: any RAW_accessible) {
		var value: EncodedString?
		raw.RAW_access { ptr in
			value = EncodedString(RAW_accessed: ptr)
		}
		guard let value = value else { return nil }
		self.value = value
	}
}
