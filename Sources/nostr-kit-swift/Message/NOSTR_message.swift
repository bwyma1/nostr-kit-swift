import RAW

public enum NOSTR_message_error: Error {
	case badDecode
}

public enum NOSTR_message<UnsignedEvent: NOSTR_event_unsigned> {
	case REQ(NOSTR_message_REQ)
	case EVENT(NOSTR_message_EVENT<UnsignedEvent>)
	case EOSE(NOSTR_message_EOSE)
	case CLOSE(NOSTR_message_CLOSE)
	case NOTICE(NOSTR_message_NOTICE)
	case OK(NOSTR_message_OK)
}

//public func decodeNOSTRMessage(_ ptr:UnsafeRawBufferPointer, contentTypes: [NOSTR_event_content.Type]) -> NOSTR_message {
//	
//}

@RAW_staticbuff(bytes:4)
@RAW_staticbuff_fixedwidthinteger_type<UInt32>(bigEndian: true)
/// Used to identify what kind of NOSTR message is being received.
/// Types:
/// - REQ: 		0x100	Client --> Server
/// - EVENT: 	0x101	Client --> Server, Server --> Client
/// - EOSE: 		0x102	Server --> Client
/// - CLOSE: 	0x103	Client --> Server
/// - NOTICE: 	0x104	Server --> Client
/// - OK: 		0x105	Server --> Client
internal struct NOSTR_message_type:Sendable, Comparable, RAW_convertible { }

@RAW_convertible_string_type<UTF8>(backing:RAW_byte.self)
/// Subscription ID for NOSTR messages.
/// Used for REQ, EOSE, CLOSE, and server sent EVENT.
public struct NOSTR_subscription_ID: NOSTR_event_content, Comparable, ExpressibleByStringLiteral { }
