import RAW

/// An error thrown when a NOSTR message cannot be decoded.
public enum NOSTR_message_error: Error {
	/// The message bytes did not match a known message format.
	case badDecode
	/// The message carried an invalid subscription identifier.
	case badSubscriptionID
}

/// A NOSTR protocol message.
///
/// Each case corresponds to one of the NOSTR wire message types.
public enum NOSTR_message<UnsignedEvent: NOSTR_event_unsigned> {
	/// A client-to-server request to subscribe to events.
	case REQ(NOSTR_message_REQ)
	/// An event, sent client-to-server (publish) or server-to-client (subscription result).
	case EVENT(NOSTR_message_EVENT<UnsignedEvent>)
	/// A server-to-client signal that the end of stored events has been reached.
	case EOSE(NOSTR_message_EOSE)
	/// A client-to-server signal that a subscription has been closed.
	case CLOSE(NOSTR_message_CLOSE)
	/// A server-to-client notice or warning.
	case NOTICE(NOSTR_message_NOTICE)
	/// A server-to-client acknowledgement of a published event.
	case OK(NOSTR_message_OK)
}

//public func decodeNOSTRMessage(_ ptr:UnsafeRawBufferPointer, contentTypes: [NOSTR_event_content.Type]) -> NOSTR_message {
//	
//}

@RAW_staticbuff(bytes:4)
@RAW_staticbuff_fixedwidthinteger_type<UInt32>(bigEndian: true)
/// A 4-byte value identifying the type of a NOSTR message.
///
/// Types:
/// - REQ: `0x100` — client to server
/// - EVENT: `0x101` — client to server, server to client
/// - EOSE: `0x102` — server to client
/// - CLOSE: `0x103` — client to server
/// - NOTICE: `0x104` — server to client
/// - OK: `0x105` — server to client
internal struct NOSTR_message_type:Sendable, Comparable, RAW_convertible { }

/// A subscription identifier used by REQ, EOSE, CLOSE, and server-sent EVENT messages.
@RAW_convertible_string_type<UTF8>(backing:RAW_byte.self)
public struct NOSTR_subscription_ID: NOSTR_event_content, Comparable, ExpressibleByStringLiteral { }
