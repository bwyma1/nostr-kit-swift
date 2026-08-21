import RAW

/// The 64-byte Ed25519 signature attached to a signed event.
///
/// The signature is computed over the event's `id` and is used to verify that the
/// event's data has not been altered.
@RAW_staticbuff(bytes: 64)
public struct NOSTR_sig: Sendable, Hashable, RAW_convertible, RAW_accessible {}
