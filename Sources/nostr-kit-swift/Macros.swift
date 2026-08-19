import RAW

@attached(member, names: arbitrary)
@attached(extension, conformances: RAW_convertible, names: arbitrary)
/// Implements `RAW_convertible` in an extension for the attached struct.
public macro NostrContent() = #externalMacro(module: "ContentMacros", type: "NostrContent")
 
@attached(extension, conformances: RAW_convertible, names: arbitrary)
/// Implements `RAW_convertible` in an extension for the tag.
/// - `name` : When provided, the raw decode initializer checks that the tag's index field matches the name, else the initializer returns nil.
/// - `safeDecode` : When true, the raw decode initializer does NOT apply a guard statement when decoding the tag's value.
public macro NostrTag(name: String? = nil, safeDecode: Bool = false) = #externalMacro(module: "ContentMacros", type: "NostrTag")
