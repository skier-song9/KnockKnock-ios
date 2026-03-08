# iOS + Android Common BLE Advertisement and Proximity Spec

## Summary

This document defines a shared BLE advertisement spec and a local proximity-bin design for KnockKnock. BLE is used only for presence and coarse proximity. Ranking and directional arrow behavior remain on the existing WebSocket and GPS flow.

Key decisions:

- Identifier strategy: stable device ID
- Proximity levels: 3 bins
- BLE does not provide bearing or true meter distance
- Proximity is computed locally with no backend changes
- BLE `deviceId` must match the WebSocket `deviceId`

## BLE Advertisement Spec

### Primary advertisement

- Include only the existing KnockKnock 128-bit service UUID.
- Use the UUID for scan filtering and device discovery.

### Scan response

- Put the shared payload into the complete local name field.
- Format: `KK1:<base64url(payload)>`
- Target maximum length: 28 characters

### Payload V1

Binary layout:

- `version`: 1 byte, fixed `0x01`
- `stableDeviceId`: 16 bytes, UUID raw bytes
- `txPowerAt1m`: 1 byte signed int8, default `-59`

Encoding rules:

- Encode the 18-byte payload as base64url with no padding.
- Prefix the encoded payload with `KK1:`.
- Convert the UUID back to a canonical lowercase string inside the app.

Behavior rules:

- `stableDeviceId` must be the same value used as the app's WebSocket `deviceId`.
- Ignore malformed payloads, version mismatches, and self IDs.
- Active scan is required to receive scan response data.
- Scan should first filter by service UUID, then parse the `KK1:` local name payload.
- Duplicate scan results must be enabled.

Rationale:

- The existing 128-bit UUID should be preserved.
- A 128-bit UUID plus extra payload does not fit comfortably into the primary advertisement.
- Manufacturer data is intentionally avoided in v1 because the project does not define a company ID policy.

## Proximity Design

### Tracker state

Each discovered device keeps:

- `deviceId`
- `txPowerAt1m`
- `recentRssi[5]`
- `filteredRssi`
- `lastSeenAt`
- `currentBin`

### RSSI processing

- Collect RSSI on every duplicate scan callback.
- Keep the latest 5 RSSI samples.
- Compute `filteredRssi` as the median of those 5 samples.
- Bin calculation can begin after 2 samples.

### Path-loss normalization

- Compute `pathLoss = txPowerAt1m - filteredRssi`.
- Lower path-loss means a closer device.

### Proximity bins

- `near`: `pathLoss <= 15`
- `mid`: `15 < pathLoss <= 25`
- `far`: `pathLoss > 25`

### Hysteresis

Apply 3 dB hysteresis to prevent flapping:

- `mid -> near` only when `pathLoss <= 12`
- `near -> mid` only when `pathLoss > 18`
- `far -> mid` only when `pathLoss <= 22`
- `mid -> far` only when `pathLoss > 28`

### Staleness

- If no RSSI sample arrives for 8 seconds, mark the device as `unknown`.
- If no RSSI sample arrives for 15 seconds, remove the tracker entry.

## UI Mapping

Radar UI should use proximity only for ring placement and color.

- `near`: inner ring, red, radius `0.45 * radarRadius`
- `mid`: middle ring, orange, radius `0.75 * radarRadius`
- `far`: outer ring, blue, radius `1.05 * radarRadius`
- `unknown`: faded gray, radius `1.15 * radarRadius`

Existing UI rules stay unchanged:

- `remainingStops` and rank continue to come from the server
- The center arrow continues to use GPS and heading
- User angle placement can remain hash-based until a separate directional design exists

## App Integration

### BLE layer

The BLE layer should:

- advertise the shared service UUID
- publish a `deviceId -> ProximitySample` map
- keep `nearbyDeviceIds` for presence
- decode scan response local names using the `KK1:` format
- update proximity samples on each scan result
- apply stale timeout transitions

Recommended types:

- `AdvertisementPayloadV1`
- `ProximityBin`
- `ProximitySample`

### App state merge

The app should merge server users and BLE proximity locally:

- use `NearbyUser.id` as the join key
- attach local-only proximity data after WebSocket users arrive
- keep users with missing BLE data as `unknown`
- do not render BLE-only anonymous devices in the main radar list for v1

## Test Plan

### Parsing and compatibility

- iOS payloads decode correctly on Android
- Android payloads decode correctly on iOS
- UUID bytes round-trip back to the same canonical UUID string
- malformed payloads are ignored safely

### Proximity logic

- static devices do not flap bins under minor RSSI noise
- hysteresis works in both directions
- stale transitions move devices to `unknown` and later remove them

### End-to-end

- iOS to iOS discovery works with the shared UUID and `KK1:` payload
- iOS to Android discovery works with the same rules
- Proximity bins merge onto WebSocket users using the shared `deviceId`
- Radar color and radius update when RSSI changes

## Assumptions

- This spec targets foreground active-search behavior.
- Background BLE reliability is out of scope.
- BLE-based bearing is out of scope.
- Proximity bins are coarse UI hints, not true distance measurements.
- If the project later defines a manufacturer-data policy, the payload may move there in a future version.
