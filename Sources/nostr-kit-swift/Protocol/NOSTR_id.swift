import RAW
import RAW_dh25519

@RAW_staticbuff(bytes: 32)
/// The unique id sha256 hash attached to each created `NOSTR_event`.
/// It can be used for indexing of references for other events.
/// It is used to prevent accidental duplicate events.
public struct NOSTR_id:Sendable, Hashable, Comparable, RAW_convertible, RAW_accessible, NOSTR_tag_value { }
