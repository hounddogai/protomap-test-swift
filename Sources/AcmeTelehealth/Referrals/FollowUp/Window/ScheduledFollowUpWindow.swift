import AcmePlatform
import Foundation

extension Referrals {
    /// Where a scheduled follow up window is in its life cycle.
    enum ScheduledFollowUpWindowStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A scheduled follow up window. Its code is unique within a tenant.
    final class ScheduledFollowUpWindow {
        var code: String
        var name: String
        var sequence: Int
        var durationMinutes: Int
        var notes: String
        var status: ScheduledFollowUpWindowStatus

        init(code: String, name: String, sequence: Int, durationMinutes: Int, notes: String, status: ScheduledFollowUpWindowStatus) {
            self.code = code
            self.name = name
            self.sequence = sequence
            self.durationMinutes = durationMinutes
            self.notes = notes
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

        func canMoveTo(_ next: ScheduledFollowUpWindowStatus) -> Bool {
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
                case .inProgress, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                return next == ScheduledFollowUpWindowStatus.completed
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

        func moveTo(_ next: ScheduledFollowUpWindowStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("scheduled follow up window \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func projectedValue() -> Double {
            return ((Double(sequence) - Double(durationMinutes)) * 100).rounded() / 100
        }

        func copyValue() -> ScheduledFollowUpWindow {
            return ScheduledFollowUpWindow(
                code: code,
                name: name,
                sequence: sequence,
                durationMinutes: durationMinutes,
                notes: notes,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a scheduled follow up window in status planned.
    static func newScheduledFollowUpWindow(_ code: String, name: String) -> ScheduledFollowUpWindow {
        return ScheduledFollowUpWindow(
            code: code,
            name: name,
            sequence: 0,
            durationMinutes: 0,
            notes: "",
            status: ScheduledFollowUpWindowStatus.planned
        )
    }
}
