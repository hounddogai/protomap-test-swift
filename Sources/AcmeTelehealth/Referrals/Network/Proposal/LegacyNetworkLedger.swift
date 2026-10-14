import AcmePlatform
import Foundation

extension Referrals {
    /// Where a legacy network ledger is in its life cycle.
    enum LegacyNetworkLedgerStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A legacy network ledger. Its code is unique within a tenant.
    final class LegacyNetworkLedger {
        var code: String
        var title: String
        var unit: String
        var minimum: Double
        var encounterID: String
        var status: LegacyNetworkLedgerStatus

        init(code: String, title: String, unit: String, minimum: Double, encounterID: String, status: LegacyNetworkLedgerStatus) {
            self.code = code
            self.title = title
            self.unit = unit
            self.minimum = minimum
            self.encounterID = encounterID
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

        func canMoveTo(_ next: LegacyNetworkLedgerStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .inReview, .archived:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                switch next {
                case .reopened, .archived:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                switch next {
                case .archived:
                    return true
                default:
                    break
                }
                return false
            case .reopened:
                return next == LegacyNetworkLedgerStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: LegacyNetworkLedgerStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("legacy network ledger \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("legacy network ledger") \(code)"
        }

        func measuredValue() -> Double {
            return minimum
        }

        func copyValue() -> LegacyNetworkLedger {
            return LegacyNetworkLedger(
                code: code,
                title: title,
                unit: unit,
                minimum: minimum,
                encounterID: encounterID,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a legacy network ledger in status open.
    static func newLegacyNetworkLedger(_ code: String, title: String) -> LegacyNetworkLedger {
        return LegacyNetworkLedger(
            code: code,
            title: title,
            unit: "",
            minimum: 0.0,
            encounterID: "",
            status: LegacyNetworkLedgerStatus.`open`
        )
    }
}
