extension NOSTR_id {
	public init?(tagValue: NOSTR_tag_generic_value) {
		var valueLength = 0; tagValue.RAW_encode(count: &valueLength)
		guard valueLength == 32 else { return nil }
		self = tagValue.RAW_access { ptr in
			return NOSTR_id(RAW_accessed: ptr)!
		}
	}
}
