import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a regional cleaning ledger is in its life cycle.
    enum RegionalCleaningLedgerStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// The record of a regional cleaning ledger and its current status.
    final class RegionalCleaningLedger {
        var code: String
        var name: String
        var createdAt: Int
        var endsAt: Int
        var currency: String
        var status: RegionalCleaningLedgerStatus

        init(code: String, name: String, createdAt: Int, endsAt: Int, currency: String, status: RegionalCleaningLedgerStatus) {
            self.code = code
            self.name = name
            self.createdAt = createdAt
            self.endsAt = endsAt
            self.currency = currency
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

        func canMoveTo(_ next: RegionalCleaningLedgerStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .validated, .retired:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                switch next {
                case .published, .retired:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: RegionalCleaningLedgerStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("regional cleaning ledger \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("regional cleaning ledger") \(code)"
        }

        func weightedVolume() -> Double {
            return ((Double(createdAt) + Double(endsAt)) * 100).rounded() / 100
        }

        func copyValue() -> RegionalCleaningLedger {
            return RegionalCleaningLedger(
                code: code,
                name: name,
                createdAt: createdAt,
                endsAt: endsAt,
                currency: currency,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a regional cleaning ledger in status created.
    static func newRegionalCleaningLedger(_ code: String, name: String) -> RegionalCleaningLedger {
        return RegionalCleaningLedger(
            code: code,
            name: name,
            createdAt: 0,
            endsAt: 0,
            currency: "",
            status: RegionalCleaningLedgerStatus.created
        )
    }
}
