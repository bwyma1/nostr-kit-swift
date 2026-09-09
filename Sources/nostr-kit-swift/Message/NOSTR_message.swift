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

	/// Attempts to decode a single NOSTR message from the given raw bytes.
	///
	/// Each concrete message type embeds its own type tag, so the decoder tries
	/// every known message format and returns the first one that matches. If the
	/// bytes do not match any known format, this returns `nil`.
	///
	/// - Parameter ptr: The raw bytes of a single NOSTR wire message.
	/// - Returns: The decoded message, or `nil` if the bytes are not a known message.
	public static func decode(_ ptr: UnsafeRawBufferPointer) -> NOSTR_message<UnsignedEvent>? {
		guard ptr.count > 0 else { return nil }
		// Try EVENT.
		if let event = NOSTR_message_EVENT<UnsignedEvent>(RAW_decode: ptr) {
			return .EVENT(event)
		}
		// Try REQ.
		if let request = NOSTR_message_REQ(RAW_decode: ptr) {
			return .REQ(request)
		}
		// Try EOSE.
		if let eose = NOSTR_message_EOSE(RAW_decode: ptr) {
			return .EOSE(eose)
		}
		// Try CLOSE.
		if let close = NOSTR_message_CLOSE(RAW_decode: ptr) {
			return .CLOSE(close)
		}
		// Try NOTICE.
		if let notice = NOSTR_message_NOTICE(RAW_decode: ptr) {
			return .NOTICE(notice)
		}
		// Try OK.
		if let ok = NOSTR_message_OK(RAW_decode: ptr) {
			return .OK(ok)
		}
		return nil
	}
}

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
internal struct NOSTR_message_type:Sendable, Comparable { }

/// A subscription identifier used by REQ, EOSE, CLOSE, and server-sent EVENT messages.
@RAW_convertible_string_type<UTF8>(backing:RAW_byte.self)
public struct NOSTR_subscription_ID: NOSTR_event_content, Comparable, ExpressibleByStringLiteral { }
