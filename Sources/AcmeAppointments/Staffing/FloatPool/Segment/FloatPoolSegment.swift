import AcmePlatform
import Foundation

extension Staffing {
    /// Where a float pool segment is in its life cycle.
    enum FloatPoolSegmentStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A float pool segment as the float pool team keeps it.
    final class FloatPoolSegment {
        var code: String
        var title: String
        var encounterID: String
        var updatedAt: Int
        var expiresAt: Int
        var priority: Int
        var endsAt: Int
        var active: Bool
        var windowDays: Int
        var status: FloatPoolSegmentStatus

        init(code: String, title: String, encounterID: String, updatedAt: Int, expiresAt: Int, priority: Int, endsAt: Int, active: Bool, windowDays: Int, status: FloatPoolSegmentStatus) {
            self.code = code
            self.title = title
            self.encounterID = encounterID
            self.updatedAt = updatedAt
            self.expiresAt = expiresAt
            self.priority = priority
            self.endsAt = endsAt
            self.active = active
            self.windowDays = windowDays
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

        func canMoveTo(_ next: FloatPoolSegmentStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .inProgress, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                return next == FloatPoolSegmentStatus.inProgress || next == FloatPoolSegmentStatus.cancelled
            case .inProgress:
                switch next {
                case .completed, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                return next == FloatPoolSegmentStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: FloatPoolSegmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("float pool segment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func weightedValue() -> Double {
            return ((Double(updatedAt) - Double(windowDays)) * 100).rounded() / 100
        }

        func copyValue() -> FloatPoolSegment {
            return FloatPoolSegment(
                code: code,
                title: title,
                encounterID: encounterID,
                updatedAt: updatedAt,
                expiresAt: expiresAt,
                priority: priority,
                endsAt: endsAt,
                active: active,
                windowDays: windowDays,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a float pool segment in status planned.
    static func newFloatPoolSegment(_ code: String, title: String) -> FloatPoolSegment {
        return FloatPoolSegment(
            code: code,
            title: title,
            encounterID: "",
            updatedAt: 0,
            expiresAt: 0,
            priority: 0,
            endsAt: 0,
            active: false,
            windowDays: 0,
            status: FloatPoolSegmentStatus.planned
        )
    }
}
