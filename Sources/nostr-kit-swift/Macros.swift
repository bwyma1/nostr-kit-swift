import RAW

@attached(member, names: arbitrary)
@attached(extension, conformances: RAW_convertible, names: arbitrary)
public macro NostrContent() = #externalMacro(module: "ContentMacros", type: "NostrContent")
 
