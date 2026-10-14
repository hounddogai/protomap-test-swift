import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a default statement ledger is in its life cycle.
    enum DefaultStatementLedgerStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// One default statement ledger, with what the planners need to act on it.
    final class DefaultStatementLedger {
        var code: String
        var title: String
        var name: String
        var externalRef: String
        var amount: Double
        var startsAt: Int
        var status: DefaultStatementLedgerStatus

        init(code: String, title: String, name: String, externalRef: String, amount: Double, startsAt: Int, status: DefaultStatementLedgerStatus) {
            self.code = code
            self.title = title
            self.name = name
            self.externalRef = externalRef
            self.amount = amount
            self.startsAt = startsAt
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

        func canMoveTo(_ next: DefaultStatementLedgerStatus) -> Bool {
            switch status {
            case .created:
                return next == DefaultStatementLedgerStatus.retired
            case .validated:
                switch next {
                case .retired:
                    return true
                default:
                    break
                }
                return false
            case .published:
                return next == DefaultStatementLedgerStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: DefaultStatementLedgerStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("default statement ledger \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("default statement ledger") \(code)"
        }

        func netValue() -> Double {
            return (Double(startsAt) * amount * 100).rounded() / 100
        }

        func copyValue() -> DefaultStatementLedger {
            return DefaultStatementLedger(
                code: code,
                title: title,
                name: name,
                externalRef: externalRef,
                amount: amount,
                startsAt: startsAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a default statement ledger in status created.
    static func newDefaultStatementLedger(_ code: String, title: String) -> DefaultStatementLedger {
        return DefaultStatementLedger(
            code: code,
            title: title,
            name: "",
            externalRef: "",
            amount: 0.0,
            startsAt: 0,
            status: DefaultStatementLedgerStatus.created
        )
    }
}
