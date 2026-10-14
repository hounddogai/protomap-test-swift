import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a dispense ledger is in its life cycle.
    enum DispenseLedgerStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A dispense ledger. Its code is unique within a tenant.
    final class DispenseLedger {
        var code: String
        var title: String
        var ownerID: String
        var currency: String
        var attempts: Int
        var limit: Int
        var status: DispenseLedgerStatus

        init(code: String, title: String, ownerID: String, currency: String, attempts: Int, limit: Int, status: DispenseLedgerStatus) {
            self.code = code
            self.title = title
            self.ownerID = ownerID
            self.currency = currency
            self.attempts = attempts
            self.limit = limit
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

        func canMoveTo(_ next: DispenseLedgerStatus) -> Bool {
            switch status {
            case .created:
                return next == DispenseLedgerStatus.validated || next == DispenseLedgerStatus.published
            case .validated:
                return next == DispenseLedgerStatus.retired
            case .published:
                switch next {
                case .retired:
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

        func moveTo(_ next: DispenseLedgerStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("dispense ledger \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("dispense ledger") \(code)"
        }

        func projectedExposure() -> Double {
            return ((Double(limit) + Double(attempts)) * 100).rounded() / 100
        }

        func copyValue() -> DispenseLedger {
            return DispenseLedger(
                code: code,
                title: title,
                ownerID: ownerID,
                currency: currency,
                attempts: attempts,
                limit: limit,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a dispense ledger in status created.
    static func newDispenseLedger(_ code: String, title: String) -> DispenseLedger {
        return DispenseLedger(
            code: code,
            title: title,
            ownerID: "",
            currency: "",
            attempts: 0,
            limit: 0,
            status: DispenseLedgerStatus.created
        )
    }
}
