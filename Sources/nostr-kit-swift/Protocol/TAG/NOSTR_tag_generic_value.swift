import RAW
import RAW_base64

/// A generic string-based tag value.
///
/// Used as the value of an arbitrary, untyped `NOSTR_tag`.
@RAW_convertible_string_type<UTF8>(backing:RAW_byte.self)
public struct NOSTR_tag_generic_value: NOSTR_tag_value, ExpressibleByStringLiteral { }
