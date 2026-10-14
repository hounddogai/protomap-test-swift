import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a outreach schedule is in its life cycle.
    enum OutreachScheduleStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// The record of a outreach schedule and its current status.
    final class OutreachSchedule {
        var code: String
        var name: String
        var timezone: String
        var maximum: Double
        var archived: Bool
        var margin: Double
        var status: OutreachScheduleStatus

        init(code: String, name: String, timezone: String, maximum: Double, archived: Bool, margin: Double, status: OutreachScheduleStatus) {
            self.code = code
            self.name = name
            self.timezone = timezone
            self.maximum = maximum
            self.archived = archived
            self.margin = margin
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

        func canMoveTo(_ next: OutreachScheduleStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .scheduled, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                switch next {
                case .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                return next == OutreachScheduleStatus.completed || next == OutreachScheduleStatus.cancelled
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

        func moveTo(_ next: OutreachScheduleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("outreach schedule \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func adjustedExposure() -> Double {
            return (margin * maximum * 100).rounded() / 100
        }

        func copyValue() -> OutreachSchedule {
            return OutreachSchedule(
                code: code,
                name: name,
                timezone: timezone,
                maximum: maximum,
                archived: archived,
                margin: margin,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a outreach schedule in status planned.
    static func newOutreachSchedule(_ code: String, name: String) -> OutreachSchedule {
        return OutreachSchedule(
            code: code,
            name: name,
            timezone: "",
            maximum: 0.0,
            archived: false,
            margin: 0.0,
            status: OutreachScheduleStatus.planned
        )
    }
}
