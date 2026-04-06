import RAW
import RAW_dh25519

extension EventTag {
	public init(tagName:String, tagValues:[any NOSTR_tag_value]) {
		NOSTR_tag_index_field = tagName.data(using: .utf8)!.withUnsafeBytes { ptr in
			NOSTR_tag_name(RAW_staticbuff: ptr.baseAddress!)
		}
		NOSTR_tag_values = NOSTR_tag_values_wrapper(array: tagValues)
	}
}

/// Basic string value initializer.
extension EventTag {
	public init(tagName:String, tagValues:[String]) {
		NOSTR_tag_index_field = tagName.data(using: .utf8)!.withUnsafeBytes { ptr in
			NOSTR_tag_name(RAW_staticbuff: ptr.baseAddress!)
		}
		NOSTR_tag_values = NOSTR_tag_values_wrapper(array: tagValues.map { NOSTR_tag_generic_value(stringLiteral: $0) })
	}
}

/// Initializing an event tag for referencing other `NOSTR_event_signed`
/// - `Event ID` - 	ID of the referenced event.
/// - `Relay URL` - 	Hint where to find this event.
/// - `Marker` - 		Relationship type (root, reply, mention, ...)
extension EventTag {
	public init(eventID:NOSTR_id, relayUrl:String? = nil, marker:String? = nil) {
		let tagName = "e"
		NOSTR_tag_index_field = tagName.data(using: .utf8)!.withUnsafeBytes { ptr in
			NOSTR_tag_name(RAW_staticbuff: ptr.baseAddress!)
		}
		guard relayUrl != nil || marker != nil else {
			NOSTR_tag_values = NOSTR_tag_values_wrapper(array:[eventID])
			return
		}
		guard let relayUrl = relayUrl else {
			NOSTR_tag_values = NOSTR_tag_values_wrapper(array:[eventID, NOSTR_tag_generic_value(stringLiteral: marker!)])
			return
		}
		guard let marker = marker else {
			NOSTR_tag_values = NOSTR_tag_values_wrapper(array:[eventID, NOSTR_tag_generic_value(stringLiteral: relayUrl)])
			return
		}
		NOSTR_tag_values = NOSTR_tag_values_wrapper(array:[eventID, NOSTR_tag_generic_value(stringLiteral: relayUrl), NOSTR_tag_generic_value(stringLiteral: marker)])
	}
}

extension PublicKey: NOSTR_tag_value {}

/// Initializing an event tag for referencing other user/author.
/// - `User` - 		Public Key of the user being referenced
/// - `Relay URL` - 	Hint where to find this user.
extension EventTag {
	public init(user:PublicKey, relayUrl:String? = nil) {
		let tagName = "p"
		NOSTR_tag_index_field = tagName.data(using: .utf8)!.withUnsafeBytes { ptr in
			NOSTR_tag_name(RAW_staticbuff: ptr.baseAddress!)
		}
		guard let relayUrl = relayUrl else {
			NOSTR_tag_values = NOSTR_tag_values_wrapper(array:[user])
			return
		}
		NOSTR_tag_values = NOSTR_tag_values_wrapper(array:[user, NOSTR_tag_generic_value(stringLiteral: relayUrl)])
	}
}

/// Initializing an event tag for user permissions
/// - `Access Level` - The index of the access level
extension EventTag {
	public init(accessLevel: UInt8) {
		let tagName = "perm"
		NOSTR_tag_index_field = tagName.data(using: .utf8)!.withUnsafeBytes { ptr in
			NOSTR_tag_name(RAW_staticbuff: ptr.baseAddress!)
		}
		NOSTR_tag_values = NOSTR_tag_values_wrapper(array:[RAW_byte(RAW_native: accessLevel)])
	}
}

/// Initializing an event tag for user permissions
/// - `Access Level Name` - The index of the access level
extension EventTag {
	public init(accessLevel: String) {
		let tagName = "permName"
		NOSTR_tag_index_field = tagName.data(using: .utf8)!.withUnsafeBytes { ptr in
			NOSTR_tag_name(RAW_staticbuff: ptr.baseAddress!)
		}
		NOSTR_tag_values = NOSTR_tag_values_wrapper(array:[EncodedString(accessLevel)])
	}
}

/// Initializing an event d-tag for kinds 30000-39999.
/// The d-tag adds a layer of uniqueness on top of the public key and kind for an event.
/// - `dTag`		 - The value of the d-Tag.
extension EventTag {
	public init(dTag: String) {
		let tagName = "d"
		NOSTR_tag_index_field = tagName.data(using: .utf8)!.withUnsafeBytes { ptr in
			NOSTR_tag_name(RAW_staticbuff: ptr.baseAddress!)
		}
		NOSTR_tag_values = NOSTR_tag_values_wrapper(array:[NOSTR_tag_generic_value(stringLiteral: dTag)])
	}
	
	public init(dTag: any NOSTR_tag_value) {
		let tagName = "d"
		NOSTR_tag_index_field = tagName.data(using: .utf8)!.withUnsafeBytes { ptr in
			NOSTR_tag_name(RAW_staticbuff: ptr.baseAddress!)
		}
		NOSTR_tag_values = NOSTR_tag_values_wrapper(array:[dTag])
	}
}
