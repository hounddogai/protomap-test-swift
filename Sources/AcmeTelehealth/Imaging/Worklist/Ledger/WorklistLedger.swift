import AcmePlatform
import Foundation

extension Imaging {
    /// Where a worklist ledger is in its life cycle.
    enum WorklistLedgerStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A worklist ledger as the worklist team keeps it.
    final class WorklistLedger {
        var code: String
        var name: String
        var margin: Double
        var cost: Double
        var visible: Bool
        var graceDays: Int
        var updatedAt: Int
        var status: WorklistLedgerStatus

        init(code: String, name: String, margin: Double, cost: Double, visible: Bool, graceDays: Int, updatedAt: Int, status: WorklistLedgerStatus) {
            self.code = code
            self.name = name
            self.margin = margin
            self.cost = cost
            self.visible = visible
            self.graceDays = graceDays
            self.updatedAt = updatedAt
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .archived:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: WorklistLedgerStatus) -> Bool {
            switch status {
            case .`open`:
                return next == WorklistLedgerStatus.inReview || next == WorklistLedgerStatus.resolved
            case .inReview:
                return next == WorklistLedgerStatus.reopened
            case .resolved:
                return next == WorklistLedgerStatus.reopened
            case .reopened:
                return next == WorklistLedgerStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: WorklistLedgerStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("worklist ledger \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func weightedLoad() -> Double {
            return ((cost + Double(updatedAt)) * 100).rounded() / 100
        }

        func copyValue() -> WorklistLedger {
            return WorklistLedger(
                code: code,
                name: name,
                margin: margin,
                cost: cost,
                visible: visible,
                graceDays: graceDays,
                updatedAt: updatedAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a worklist ledger in status open.
    static func newWorklistLedger(_ code: String, name: String) -> WorklistLedger {
        return WorklistLedger(
            code: code,
            name: name,
            margin: 0.0,
            cost: 0.0,
            visible: false,
            graceDays: 0,
            updatedAt: 0,
            status: WorklistLedgerStatus.`open`
        )
    }
}
