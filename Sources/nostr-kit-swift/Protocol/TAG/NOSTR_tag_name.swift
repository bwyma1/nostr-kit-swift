import RAW

@RAW_staticbuff(bytes:4)
/// The name and index field of a `NOSTR_tag`
public struct NOSTR_tag_name:Sendable, Comparable, RAW_convertible { }
