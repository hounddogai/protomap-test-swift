import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a isolation schedule is in its life cycle.
    enum IsolationScheduleStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A isolation schedule as the isolation team keeps it.
    final class IsolationSchedule {
        var code: String
        var title: String
        var pinned: Bool
        var clinicianID: String
        var procedureCode: String
        var version: Int
        var summary: String
        var durationMinutes: Int
        var capacity: Int
        var priority: Int
        var approved: Bool
        var status: IsolationScheduleStatus

        init(code: String, title: String, pinned: Bool, clinicianID: String, procedureCode: String, version: Int, summary: String, durationMinutes: Int, capacity: Int, priority: Int, approved: Bool, status: IsolationScheduleStatus) {
            self.code = code
            self.title = title
            self.pinned = pinned
            self.clinicianID = clinicianID
            self.procedureCode = procedureCode
            self.version = version
            self.summary = summary
            self.durationMinutes = durationMinutes
            self.capacity = capacity
            self.priority = priority
            self.approved = approved
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .closed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: IsolationScheduleStatus) -> Bool {
            switch status {
            case .draft:
                return next == IsolationScheduleStatus.closed
            case .pending:
                switch next {
                case .active, .closed:
                    return true
                default:
                    break
                }
                return false
            case .active:
                return next == IsolationScheduleStatus.suspended
            case .suspended:
                return next == IsolationScheduleStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: IsolationScheduleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("isolation schedule \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func projectedLoad() -> Double {
            return (Double(priority) * Double(version) * 100).rounded() / 100
        }

        func copyValue() -> IsolationSchedule {
            return IsolationSchedule(
                code: code,
                title: title,
                pinned: pinned,
                clinicianID: clinicianID,
                procedureCode: procedureCode,
                version: version,
                summary: summary,
                durationMinutes: durationMinutes,
                capacity: capacity,
                priority: priority,
                approved: approved,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a isolation schedule in status draft.
    static func newIsolationSchedule(_ code: String, title: String) -> IsolationSchedule {
        return IsolationSchedule(
            code: code,
            title: title,
            pinned: false,
            clinicianID: "",
            procedureCode: "",
            version: 0,
            summary: "",
            durationMinutes: 0,
            capacity: 0,
            priority: 0,
            approved: false,
            status: IsolationScheduleStatus.draft
        )
    }
}
