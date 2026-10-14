import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a batched dispense profile is in its life cycle.
    enum BatchedDispenseProfileStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A batched dispense profile. Its code is unique within a tenant.
    final class BatchedDispenseProfile {
        var code: String
        var name: String
        var durationMinutes: Int
        var windowDays: Int
        var pinned: Bool
        var capacity: Int
        var channel: String
        var maximum: Double
        var ratio: Double
        var timezone: String
        var status: BatchedDispenseProfileStatus

        init(code: String, name: String, durationMinutes: Int, windowDays: Int, pinned: Bool, capacity: Int, channel: String, maximum: Double, ratio: Double, timezone: String, status: BatchedDispenseProfileStatus) {
            self.code = code
            self.name = name
            self.durationMinutes = durationMinutes
            self.windowDays = windowDays
            self.pinned = pinned
            self.capacity = capacity
            self.channel = channel
            self.maximum = maximum
            self.ratio = ratio
            self.timezone = timezone
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .expired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: BatchedDispenseProfileStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .revoked:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                return next == BatchedDispenseProfileStatus.expired
            case .revoked:
                switch next {
                case .expired:
                    return true
                default:
                    break
                }
                return false
            default:
                break
            }
            return false
        }

        func moveTo(_ next: BatchedDispenseProfileStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("batched dispense profile \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(name)]"
        }

        func netTotal() -> Double {
            return ((Double(durationMinutes) + maximum) * 100).rounded() / 100
        }

        func copyValue() -> BatchedDispenseProfile {
            return BatchedDispenseProfile(
                code: code,
                name: name,
                durationMinutes: durationMinutes,
                windowDays: windowDays,
                pinned: pinned,
                capacity: capacity,
                channel: channel,
                maximum: maximum,
                ratio: ratio,
                timezone: timezone,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a batched dispense profile in status requested.
    static func newBatchedDispenseProfile(_ code: String, name: String) -> BatchedDispenseProfile {
        return BatchedDispenseProfile(
            code: code,
            name: name,
            durationMinutes: 0,
            windowDays: 0,
            pinned: false,
            capacity: 0,
            channel: "",
            maximum: 0.0,
            ratio: 0.0,
            timezone: "",
            status: BatchedDispenseProfileStatus.requested
        )
    }
}
