import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a scheduled risk score ledger is in its life cycle.
    enum ScheduledRiskScoreLedgerStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A scheduled risk score ledger as the risk score team keeps it.
    final class ScheduledRiskScoreLedger {
        var code: String
        var title: String
        var graceDays: Int
        var contactEmail: String
        var cost: Double
        var status: ScheduledRiskScoreLedgerStatus

        init(code: String, title: String, graceDays: Int, contactEmail: String, cost: Double, status: ScheduledRiskScoreLedgerStatus) {
            self.code = code
            self.title = title
            self.graceDays = graceDays
            self.contactEmail = contactEmail
            self.cost = cost
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .retired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: ScheduledRiskScoreLedgerStatus) -> Bool {
            switch status {
            case .created:
                return next == ScheduledRiskScoreLedgerStatus.published
            case .validated:
                return next == ScheduledRiskScoreLedgerStatus.retired
            case .published:
                return next == ScheduledRiskScoreLedgerStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ScheduledRiskScoreLedgerStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("scheduled risk score ledger \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func effectiveExposure() -> Double {
            return ((Double(graceDays) + cost) * 100).rounded() / 100
        }

        func copyValue() -> ScheduledRiskScoreLedger {
            return ScheduledRiskScoreLedger(
                code: code,
                title: title,
                graceDays: graceDays,
                contactEmail: contactEmail,
                cost: cost,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a scheduled risk score ledger in status created.
    static func newScheduledRiskScoreLedger(_ code: String, title: String) -> ScheduledRiskScoreLedger {
        return ScheduledRiskScoreLedger(
            code: code,
            title: title,
            graceDays: 0,
            contactEmail: "",
            cost: 0.0,
            status: ScheduledRiskScoreLedgerStatus.created
        )
    }
}
