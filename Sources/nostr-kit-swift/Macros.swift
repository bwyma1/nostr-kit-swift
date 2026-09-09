import RAW

@attached(member, names: arbitrary)
@attached(extension, conformances: RAW_decodable, RAW_encodable, names: arbitrary)
/// Implements `RAW_decodable` and `RAW_encodable` in an extension for the attached struct.
public macro NostrContent() = #externalMacro(module: "ContentMacros", type: "NostrContent")
 
@attached(member, names: arbitrary)
@attached(extension, conformances: RAW_decodable, RAW_encodable, names: arbitrary)
/// Implements `RAW_decodable` and `RAW_encodable` in an extension for the tag.
///
/// - Parameters:
///   - name: When provided, the macro generates the tag's `indexField` stored
///     property, and the raw decode initializer verifies that the tag's index
///     field matches this name (returning `nil` otherwise).
///   - valueType: The tag's value type (the `tagValueType` associated type). When
///     provided, the macro generates the `value` stored property and an
///     `init(value:)` initializer, so the struct body need not declare them.
public macro NostrTag(name: String? = nil, valueType: Any.Type? = nil) = #externalMacro(module: "ContentMacros", type: "NostrTag")
