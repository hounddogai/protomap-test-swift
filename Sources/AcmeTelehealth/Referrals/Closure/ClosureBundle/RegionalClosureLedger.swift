import AcmePlatform
import Foundation

extension Referrals {
    /// Where a regional closure ledger is in its life cycle.
    enum RegionalClosureLedgerStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A regional closure ledger as the closure team keeps it.
    final class RegionalClosureLedger {
        var code: String
        var title: String
        var contactEmail: String
        var summary: String
        var visitMinutes: Int
        var dosageMg: Double
        var capacity: Int
        var region: String
        var cost: Double
        var amount: Double
        var encounterID: String
        var status: RegionalClosureLedgerStatus

        init(code: String, title: String, contactEmail: String, summary: String, visitMinutes: Int, dosageMg: Double, capacity: Int, region: String, cost: Double, amount: Double, encounterID: String, status: RegionalClosureLedgerStatus) {
            self.code = code
            self.title = title
            self.contactEmail = contactEmail
            self.summary = summary
            self.visitMinutes = visitMinutes
            self.dosageMg = dosageMg
            self.capacity = capacity
            self.region = region
            self.cost = cost
            self.amount = amount
            self.encounterID = encounterID
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

        func canMoveTo(_ next: RegionalClosureLedgerStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .pending, .suspended:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                switch next {
                case .closed:
                    return true
                default:
                    break
                }
                return false
            case .active:
                switch next {
                case .closed:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                return next == RegionalClosureLedgerStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RegionalClosureLedgerStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("regional closure ledger \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func netLoad() -> Double {
            return ((Double(capacity) - amount) * 100).rounded() / 100
        }

        func copyValue() -> RegionalClosureLedger {
            return RegionalClosureLedger(
                code: code,
                title: title,
                contactEmail: contactEmail,
                summary: summary,
                visitMinutes: visitMinutes,
                dosageMg: dosageMg,
                capacity: capacity,
                region: region,
                cost: cost,
                amount: amount,
                encounterID: encounterID,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a regional closure ledger in status draft.
    static func newRegionalClosureLedger(_ code: String, title: String) -> RegionalClosureLedger {
        return RegionalClosureLedger(
            code: code,
            title: title,
            contactEmail: "",
            summary: "",
            visitMinutes: 0,
            dosageMg: 0.0,
            capacity: 0,
            region: "",
            cost: 0.0,
            amount: 0.0,
            encounterID: "",
            status: RegionalClosureLedgerStatus.draft
        )
    }
}
