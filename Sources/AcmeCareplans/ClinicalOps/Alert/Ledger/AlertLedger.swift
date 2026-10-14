import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a alert ledger is in its life cycle.
    enum AlertLedgerStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A alert ledger. Its code is unique within a tenant.
    final class AlertLedger {
        var code: String
        var name: String
        var expiresAt: Int
        var minimum: Double
        var version: Int
        var ratio: Double
        var cost: Double
        var margin: Double
        var graceDays: Int
        var status: AlertLedgerStatus

        init(code: String, name: String, expiresAt: Int, minimum: Double, version: Int, ratio: Double, cost: Double, margin: Double, graceDays: Int, status: AlertLedgerStatus) {
            self.code = code
            self.name = name
            self.expiresAt = expiresAt
            self.minimum = minimum
            self.version = version
            self.ratio = ratio
            self.cost = cost
            self.margin = margin
            self.graceDays = graceDays
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .withdrawn:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: AlertLedgerStatus) -> Bool {
            switch status {
            case .proposed:
                return next == AlertLedgerStatus.withdrawn
            case .approved:
                switch next {
                case .rejected, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                return next == AlertLedgerStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: AlertLedgerStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("alert ledger \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
            version += 1
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func effectiveValue() -> Double {
            return ((Double(graceDays) + Double(version)) * 100).rounded() / 100
        }

        func copyValue() -> AlertLedger {
            return AlertLedger(
                code: code,
                name: name,
                expiresAt: expiresAt,
                minimum: minimum,
                version: version,
                ratio: ratio,
                cost: cost,
                margin: margin,
                graceDays: graceDays,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a alert ledger in status proposed.
    static func newAlertLedger(_ code: String, name: String) -> AlertLedger {
        return AlertLedger(
            code: code,
            name: name,
            expiresAt: 0,
            minimum: 0.0,
            version: 0,
            ratio: 0.0,
            cost: 0.0,
            margin: 0.0,
            graceDays: 0,
            status: AlertLedgerStatus.proposed
        )
    }
}
