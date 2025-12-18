import RAW

@RAW_staticbuff(bytes: 64)
/// The signature that created in a `NOSTR_event_signed`
/// This signature is used to determine if the data has been altered.
public struct NOSTR_sig: Sendable, Hashable, RAW_convertible, RAW_accessible { }
