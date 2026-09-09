extension NOSTR_id {
	/// Creates an event id from a generic tag value, if it is exactly 32 bytes long.
	public init?(tagValue: NOSTR_tag_generic_value) {
		var valueLength = 0; tagValue.RAW_encode(count: &valueLength)
		guard valueLength == 32 else { return nil }
		self = tagValue.RAW_access_immutable { ptr in
			return NOSTR_id(RAW_decode: UnsafeRawBufferPointer(ptr))!
		}
	}
}
