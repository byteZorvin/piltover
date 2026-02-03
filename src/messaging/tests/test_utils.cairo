use piltover::messaging::utils::{STARKNET_EVENT_MAX_DATA_FELTS, truncate_payload_for_event};

#[test]
fn test_truncate_payload_no_skip_short() {
    let payload = array![1, 2, 3, 4, 5];
    let truncated = truncate_payload_for_event(payload.span(), 0);
    assert(truncated.len() == 5_usize, 'invalid truncated len');
    assert((*truncated[0]) == 1, 'invalid truncated[0]');
    assert((*truncated[1]) == 2, 'invalid truncated[1]');
    assert((*truncated[2]) == 3, 'invalid truncated[2]');
    assert((*truncated[3]) == 4, 'invalid truncated[3]');
    assert((*truncated[4]) == 5, 'invalid truncated[4]');
}

#[test]
fn test_truncate_payload_with_skip() {
    let payload = array![1, 2, 3, 4, 5];
    let truncated = truncate_payload_for_event(payload.span(), 2);
    assert(truncated.len() == 5_usize, 'invalid truncated len');
    assert((*truncated[0]) == 1, 'invalid truncated[0]');
    assert((*truncated[1]) == 2, 'invalid truncated[1]');
    assert((*truncated[2]) == 3, 'invalid truncated[2]');
    assert((*truncated[3]) == 4, 'invalid truncated[3]');
    assert((*truncated[4]) == 5, 'invalid truncated[4]');
}

#[test]
fn test_truncate_payload_with_skip_truncation() {
    let mut payload = array![];
    for i in 0_usize..297 {
        payload.append(i.into());
    }
    let truncated = truncate_payload_for_event(payload.span(), 2);
    println!("truncated len: {}", truncated.len());
    assert(truncated.len() == 297_usize, 'invalid truncated len');

    let mut payload2 = array![];
    for i in 0_usize..299 {
        payload2.append(i.into());
    }
    let truncated2 = truncate_payload_for_event(payload2.span(), 2);
    println!("truncated2 len: {}", truncated2.len());
    assert(truncated2.len() == 297, 'invalid truncated len');
    assert((*truncated2[0]) == 0, 'invalid truncated2[0]');
    assert((*truncated2[296]) == 296, 'invalid truncated2[296]');
}

#[test]
fn test_truncate_payload_at_limit_skip() {
    let mut payload = array![];
    for i in 0_usize..(STARKNET_EVENT_MAX_DATA_FELTS + 1) {
        payload.append(i.into());
    }

    let truncated = truncate_payload_for_event(payload.span(), STARKNET_EVENT_MAX_DATA_FELTS);
    assert(truncated.len() == 0_usize, 'empty when skip >= limit');
}

#[test]
fn test_truncate_payload_exact_limit() {
    let mut payload = array![];
    for i in 0_usize..STARKNET_EVENT_MAX_DATA_FELTS {
        payload.append(i.into());
    }

    let truncated = truncate_payload_for_event(payload.span(), 0);
    // -1 to include the serialized length of the payload Span.
    assert(truncated.len() == STARKNET_EVENT_MAX_DATA_FELTS - 1, 'invalid truncated len');

    // -1 to include the serialized length of the payload Span.
    for i in 0_usize..STARKNET_EVENT_MAX_DATA_FELTS - 1 {
        assert((*truncated[i]) == i.into(), 'invalid truncated element');
    }
}

#[test]
fn test_truncate_payload_no_skip_long_payload() {
    let mut payload = array![];
    for i in 0_usize..(STARKNET_EVENT_MAX_DATA_FELTS + 100) {
        payload.append(i.into());
    }

    let truncated = truncate_payload_for_event(payload.span(), 0);
    // -1 to include the serialized length of the payload Span.
    assert(truncated.len() == (STARKNET_EVENT_MAX_DATA_FELTS - 1), 'invalid truncated len');

    // -1 to include the serialized length of the payload Span.
    for i in 0_usize..(STARKNET_EVENT_MAX_DATA_FELTS - 1) {
        assert((*truncated[i]) == i.into(), 'invalid truncated element');
    }
}
