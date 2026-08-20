import RAW

@attached(member, names: arbitrary)
@attached(extension, conformances: RAW_convertible, names: arbitrary)
/// Implements `RAW_convertible` in an extension for the attached struct.
public macro NostrContent() = #externalMacro(module: "ContentMacros", type: "NostrContent")
 
@attached(member, names: arbitrary)
@attached(extension, conformances: RAW_convertible, names: arbitrary)
/// Implements `RAW_convertible` in an extension for the tag.
/// - `name` : When provided, the raw decode initializer checks that the tag's index field matches the name, else the initializer returns nil. It also generates the tag's `indexField` stored property, so the struct body need not declare it.
/// - `valueType` : The tag's value type (the `tagValueType` associated type). When provided, the macro generates the `value` stored property and an `init(value:)` initializer, so the struct body need not declare them.
public macro NostrTag(name: String? = nil, valueType: Any.Type? = nil) = #externalMacro(module: "ContentMacros", type: "NostrTag")
