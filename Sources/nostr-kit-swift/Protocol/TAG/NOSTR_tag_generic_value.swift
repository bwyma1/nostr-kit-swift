import RAW
import RAW_base64

@RAW_convertible_string_type<UTF8>(backing:RAW_byte.self)
/// An example generic tag value.
/// Used in the array of tag values in a `NOSTR_tag`
public struct NOSTR_tag_generic_value: NOSTR_tag_value, ExpressibleByStringLiteral { }
