//! Utility functions for the messaging component.

pub const STARKNET_EVENT_MAX_DATA_FELTS: usize = 300;

/// Currently, starknet is limiting events to 300 data felts.
/// This function ensures that the payload is truncated to the first 300 felts,
/// and returns the truncated payload.
///
/// Since events may have other data felts, passing the number of felts to skip is useful
/// to avoid truncating too much if some data felts are already present.
///
/// It is NOT ideal to copy the felts, since it adds execution (hence gas) costs.
/// An alternative would be to not output the payload at all, or only in test mode.
/// For short messages, it is still very handy to have the payload in the event.
///
/// # Arguments
///
/// * `payload` - The payload to truncate.
/// * `skip` - The number of felts to skip.
///
/// # Returns
///
/// The truncated payload.
pub fn truncate_payload_for_event(payload: Span<felt252>, skip: usize) -> Span<felt252> {
    if skip >= STARKNET_EVENT_MAX_DATA_FELTS {
        return array![].span();
    }

    // -1 to include the length of the payload Span when serialized.
    let max_payload_len = STARKNET_EVENT_MAX_DATA_FELTS - skip - 1;

    if payload.len() <= max_payload_len {
        return payload;
    }

    let mut truncated = array![];
    let mut i = 0_usize;

    loop {
        if i >= max_payload_len {
            break;
        }
        truncated.append((*payload[i]));
        i += 1;
    }

    truncated.span()
}
