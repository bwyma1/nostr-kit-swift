import RAW

@RAW_staticbuff(bytes:8)
/// The name and index field of a `NOSTR_tag`
public struct NOSTR_tag_name:Sendable, Hashable, Comparable, RAW_convertible, RAW_accessible {
	public var string: String? {
		self.RAW_access { ptr in
			String(bytes: ptr, encoding: .utf8)
		}
	}
}

extension NOSTR_tag_name {
	public init(string: String) {
		self = string.data(using: .utf8)!.withUnsafeBytes { ptr in
			NOSTR_tag_name(RAW_staticbuff: ptr.baseAddress!)
		}
	}
}
