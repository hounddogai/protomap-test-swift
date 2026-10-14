import AcmePlatform
import Foundation

extension Labs {
    /// Where a fallback courier slot is in its life cycle.
    enum FallbackCourierSlotStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// The record of a fallback courier slot and its current status.
    final class FallbackCourierSlot {
        var code: String
        var name: String
        var summary: String
        var timezone: String
        var endsAt: Int
        var reviewer: String
        var active: Bool
        var threshold: Double
        var status: FallbackCourierSlotStatus

        init(code: String, name: String, summary: String, timezone: String, endsAt: Int, reviewer: String, active: Bool, threshold: Double, status: FallbackCourierSlotStatus) {
            self.code = code
            self.name = name
            self.summary = summary
            self.timezone = timezone
            self.endsAt = endsAt
            self.reviewer = reviewer
            self.active = active
            self.threshold = threshold
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .stopped:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: FallbackCourierSlotStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .draining, .stopped:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                switch next {
                case .ready:
                    return true
                default:
                    break
                }
                return false
            case .ready:
                return next == FallbackCourierSlotStatus.draining || next == FallbackCourierSlotStatus.stopped
            case .draining:
                switch next {
                case .stopped:
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

        func moveTo(_ next: FallbackCourierSlotStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("fallback courier slot \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func effectiveLoad() -> Double {
            return ((Double(endsAt) + threshold) * 100).rounded() / 100
        }

        func copyValue() -> FallbackCourierSlot {
            return FallbackCourierSlot(
                code: code,
                name: name,
                summary: summary,
                timezone: timezone,
                endsAt: endsAt,
                reviewer: reviewer,
                active: active,
                threshold: threshold,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a fallback courier slot in status idle.
    static func newFallbackCourierSlot(_ code: String, name: String) -> FallbackCourierSlot {
        return FallbackCourierSlot(
            code: code,
            name: name,
            summary: "",
            timezone: "",
            endsAt: 0,
            reviewer: "",
            active: false,
            threshold: 0.0,
            status: FallbackCourierSlotStatus.idle
        )
    }
}
