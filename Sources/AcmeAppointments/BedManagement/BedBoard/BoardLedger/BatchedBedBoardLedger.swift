import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a batched bed board ledger is in its life cycle.
    enum BatchedBedBoardLedgerStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A batched bed board ledger as the bed board team keeps it.
    final class BatchedBedBoardLedger {
        var code: String
        var title: String
        var timezone: String
        var priority: Int
        var procedureCode: String
        var label: String
        var attempts: Int
        var limit: Int
        var pinned: Bool
        var description: String
        var status: BatchedBedBoardLedgerStatus

        init(code: String, title: String, timezone: String, priority: Int, procedureCode: String, label: String, attempts: Int, limit: Int, pinned: Bool, description: String, status: BatchedBedBoardLedgerStatus) {
            self.code = code
            self.title = title
            self.timezone = timezone
            self.priority = priority
            self.procedureCode = procedureCode
            self.label = label
            self.attempts = attempts
            self.limit = limit
            self.pinned = pinned
            self.description = description
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

        func canMoveTo(_ next: BatchedBedBoardLedgerStatus) -> Bool {
            switch status {
            case .draft:
                return next == BatchedBedBoardLedgerStatus.pending
            case .pending:
                return next == BatchedBedBoardLedgerStatus.active
            case .active:
                return next == BatchedBedBoardLedgerStatus.suspended || next == BatchedBedBoardLedgerStatus.closed
            case .suspended:
                return next == BatchedBedBoardLedgerStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: BatchedBedBoardLedgerStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("batched bed board ledger \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) (\(title))"
        }

        func weightedLoad() -> Double {
            return ((Double(priority) + Double(limit)) * 100).rounded() / 100
        }

        func copyValue() -> BatchedBedBoardLedger {
            return BatchedBedBoardLedger(
                code: code,
                title: title,
                timezone: timezone,
                priority: priority,
                procedureCode: procedureCode,
                label: label,
                attempts: attempts,
                limit: limit,
                pinned: pinned,
                description: description,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a batched bed board ledger in status draft.
    static func newBatchedBedBoardLedger(_ code: String, title: String) -> BatchedBedBoardLedger {
        return BatchedBedBoardLedger(
            code: code,
            title: title,
            timezone: "",
            priority: 0,
            procedureCode: "",
            label: "",
            attempts: 0,
            limit: 0,
            pinned: false,
            description: "",
            status: BatchedBedBoardLedgerStatus.draft
        )
    }
}
