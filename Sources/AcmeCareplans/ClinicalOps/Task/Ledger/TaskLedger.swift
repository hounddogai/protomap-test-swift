import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a task ledger is in its life cycle.
    enum TaskLedgerStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// One task ledger, with what the planners need to act on it.
    final class TaskLedger {
        var code: String
        var label: String
        var timezone: String
        var limit: Int
        var procedureCode: String
        var archived: Bool
        var summary: String
        var status: TaskLedgerStatus

        init(code: String, label: String, timezone: String, limit: Int, procedureCode: String, archived: Bool, summary: String, status: TaskLedgerStatus) {
            self.code = code
            self.label = label
            self.timezone = timezone
            self.limit = limit
            self.procedureCode = procedureCode
            self.archived = archived
            self.summary = summary
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

        func canMoveTo(_ next: TaskLedgerStatus) -> Bool {
            switch status {
            case .planned:
                return next == TaskLedgerStatus.completed
            case .scheduled:
                switch next {
                case .inProgress, .completed:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                return next == TaskLedgerStatus.completed || next == TaskLedgerStatus.cancelled
            case .completed:
                return next == TaskLedgerStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: TaskLedgerStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("task ledger \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func measuredValue() -> Double {
            return Double(limit)
        }

        func copyValue() -> TaskLedger {
            return TaskLedger(
                code: code,
                label: label,
                timezone: timezone,
                limit: limit,
                procedureCode: procedureCode,
                archived: archived,
                summary: summary,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a task ledger in status planned.
    static func newTaskLedger(_ code: String, label: String) -> TaskLedger {
        return TaskLedger(
            code: code,
            label: label,
            timezone: "",
            limit: 0,
            procedureCode: "",
            archived: false,
            summary: "",
            status: TaskLedgerStatus.planned
        )
    }
}
