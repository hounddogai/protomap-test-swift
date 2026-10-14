import AcmePlatform
import Foundation

extension Imaging {
    /// Where a scheduled priority schedule is in its life cycle.
    enum ScheduledPriorityScheduleStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A scheduled priority schedule. Its code is unique within a tenant.
    final class ScheduledPrioritySchedule {
        var code: String
        var label: String
        var approved: Bool
        var revision: Int
        var ownerID: String
        var status: ScheduledPriorityScheduleStatus

        init(code: String, label: String, approved: Bool, revision: Int, ownerID: String, status: ScheduledPriorityScheduleStatus) {
            self.code = code
            self.label = label
            self.approved = approved
            self.revision = revision
            self.ownerID = ownerID
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

        func canMoveTo(_ next: ScheduledPriorityScheduleStatus) -> Bool {
            switch status {
            case .idle:
                switch next {
                case .warming:
                    return true
                default:
                    break
                }
                return false
            case .warming:
                return next == ScheduledPriorityScheduleStatus.draining || next == ScheduledPriorityScheduleStatus.stopped
            case .ready:
                switch next {
                case .stopped:
                    return true
                default:
                    break
                }
                return false
            case .draining:
                return next == ScheduledPriorityScheduleStatus.stopped
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ScheduledPriorityScheduleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("scheduled priority schedule \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func measuredValue() -> Double {
            return Double(revision)
        }

        func copyValue() -> ScheduledPrioritySchedule {
            return ScheduledPrioritySchedule(
                code: code,
                label: label,
                approved: approved,
                revision: revision,
                ownerID: ownerID,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a scheduled priority schedule in status idle.
    static func newScheduledPrioritySchedule(_ code: String, label: String) -> ScheduledPrioritySchedule {
        return ScheduledPrioritySchedule(
            code: code,
            label: label,
            approved: false,
            revision: 0,
            ownerID: "",
            status: ScheduledPriorityScheduleStatus.idle
        )
    }
}
