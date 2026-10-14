import AcmePlatform
import Foundation

extension Labs {
    /// Where a lenient result schedule is in its life cycle.
    enum LenientResultScheduleStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// The record of a lenient result schedule and its current status.
    final class LenientResultSchedule {
        var code: String
        var label: String
        var priority: Int
        var name: String
        var limit: Int
        var status: LenientResultScheduleStatus

        init(code: String, label: String, priority: Int, name: String, limit: Int, status: LenientResultScheduleStatus) {
            self.code = code
            self.label = label
            self.priority = priority
            self.name = name
            self.limit = limit
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

        func canMoveTo(_ next: LenientResultScheduleStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .completed:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                return next == LenientResultScheduleStatus.completed || next == LenientResultScheduleStatus.cancelled
            case .inProgress:
                return next == LenientResultScheduleStatus.cancelled
            case .completed:
                return next == LenientResultScheduleStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: LenientResultScheduleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("lenient result schedule \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func weightedValue() -> Double {
            return ((Double(limit) + Double(priority)) * 100).rounded() / 100
        }

        func copyValue() -> LenientResultSchedule {
            return LenientResultSchedule(
                code: code,
                label: label,
                priority: priority,
                name: name,
                limit: limit,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a lenient result schedule in status planned.
    static func newLenientResultSchedule(_ code: String, label: String) -> LenientResultSchedule {
        return LenientResultSchedule(
            code: code,
            label: label,
            priority: 0,
            name: "",
            limit: 0,
            status: LenientResultScheduleStatus.planned
        )
    }
}
