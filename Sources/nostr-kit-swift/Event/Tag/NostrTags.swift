import RAW
import RAW_dh25519

public func findTag<T: NOSTR_tag>(tags: [any NOSTR_tag], as type: T.Type = T.self) -> T? {
	for tag in tags {
		guard let typedTag = tag.unwrap(as: type) else { continue }
		return typedTag
	}
	return nil
}

@NostrTag(safeDecode: true)
public struct GenericTag: Sendable, Hashable, Equatable, NOSTR_tag {
	public var indexField: NOSTR_tag_name
	public var value: EncodedString
	public init(name:String, value: String) {
		self.indexField = NOSTR_tag_name(string: name)
		self.value = EncodedString(value)
	}
}

/// Initializing an event tag for referencing other `NOSTR_event_signed`
@NostrTag(name: "e")
public struct EventRefTag: Sendable, Hashable, Equatable, NOSTR_tag {
	public var indexField = NOSTR_tag_name(string: "e")
	public var value: NOSTR_id
	public init(value: NOSTR_id) {
		self.value = value
	}
}

extension PublicKey: NOSTR_tag_value {}
/// Initializing an event tag for referencing other user/author.
@NostrTag(name: "p")
public struct UserTag: Sendable, Hashable, Equatable, NOSTR_tag {
	public var indexField = NOSTR_tag_name(string: "p")
	public var value: PublicKey
	public init(value: PublicKey) {
		self.value = value
	}
}

/// Initializing an event tag for user permissions.
@NostrTag(name: "perm")
public struct AccessLevelTag: Sendable, Hashable, Equatable, NOSTR_tag {
	public var indexField = NOSTR_tag_name(string: "perm")
	public var value: RAW_byte
	public init(value: UInt8) {
		self.value = RAW_byte(RAW_native: value)
	}
}

/// Initializing an event tag for the name of the user permissions.
@NostrTag(name: "permName", safeDecode: true)
public struct AccessLevelNameTag: Sendable, Hashable, Equatable, NOSTR_tag {
	public var indexField = NOSTR_tag_name(string: "permName")
	public var value: EncodedString
	public init(value: String) {
		self.value = EncodedString(value)
	}
}

/// Initializing an event d-tag for kinds 30000-39999.
/// The d-tag adds a layer of uniqueness on top of the public key and kind for an event.
@NostrTag(name: "d", safeDecode: true)
public struct DTag: Sendable, Hashable, Equatable, NOSTR_tag {
	public var indexField = NOSTR_tag_name(string: "d")
	public var value: EncodedString
	public init(value: String) {
		self.value = EncodedString(value)
	}
	
	public init?(raw: any RAW_accessible) {
		var value: EncodedString?
		raw.RAW_access { ptr in
			value = EncodedString(RAW_accessed: ptr)
		}
		guard let value = value else { return nil }
		self.value = value
	}
}
