import AcmePlatform
import Foundation

extension Staffing {
    /// Where a shift group is in its life cycle.
    enum ShiftGroupStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// One shift group, with what the planners need to act on it.
    final class ShiftGroup {
        var code: String
        var title: String
        var active: Bool
        var capacity: Int
        var windowDays: Int
        var reviewer: String
        var externalRef: String
        var expiresAt: Int
        var copay: Double
        var timezone: String
        var status: ShiftGroupStatus

        init(code: String, title: String, active: Bool, capacity: Int, windowDays: Int, reviewer: String, externalRef: String, expiresAt: Int, copay: Double, timezone: String, status: ShiftGroupStatus) {
            self.code = code
            self.title = title
            self.active = active
            self.capacity = capacity
            self.windowDays = windowDays
            self.reviewer = reviewer
            self.externalRef = externalRef
            self.expiresAt = expiresAt
            self.copay = copay
            self.timezone = timezone
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .cancelled:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ShiftGroupStatus) -> Bool {
            switch status {
            case .planned:
                return next == ShiftGroupStatus.scheduled
            case .scheduled:
                return next == ShiftGroupStatus.completed || next == ShiftGroupStatus.cancelled
            case .inProgress:
                switch next {
                case .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                switch next {
                case .cancelled:
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

        func moveTo(_ next: ShiftGroupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("shift group \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func adjustedExposure() -> Double {
            return ((Double(windowDays) - Double(capacity)) * 100).rounded() / 100
        }

        func copyValue() -> ShiftGroup {
            return ShiftGroup(
                code: code,
                title: title,
                active: active,
                capacity: capacity,
                windowDays: windowDays,
                reviewer: reviewer,
                externalRef: externalRef,
                expiresAt: expiresAt,
                copay: copay,
                timezone: timezone,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a shift group in status planned.
    static func newShiftGroup(_ code: String, title: String) -> ShiftGroup {
        return ShiftGroup(
            code: code,
            title: title,
            active: false,
            capacity: 0,
            windowDays: 0,
            reviewer: "",
            externalRef: "",
            expiresAt: 0,
            copay: 0.0,
            timezone: "",
            status: ShiftGroupStatus.planned
        )
    }
}
