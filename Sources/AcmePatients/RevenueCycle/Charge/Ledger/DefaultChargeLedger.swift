import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a default charge ledger is in its life cycle.
    enum DefaultChargeLedgerStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A default charge ledger as the charge team keeps it.
    final class DefaultChargeLedger {
        var code: String
        var label: String
        var expiresAt: Int
        var maximum: Double
        var archived: Bool
        var checksum: String
        var title: String
        var ratio: Double
        var status: DefaultChargeLedgerStatus

        init(code: String, label: String, expiresAt: Int, maximum: Double, archived: Bool, checksum: String, title: String, ratio: Double, status: DefaultChargeLedgerStatus) {
            self.code = code
            self.label = label
            self.expiresAt = expiresAt
            self.maximum = maximum
            self.archived = archived
            self.checksum = checksum
            self.title = title
            self.ratio = ratio
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

        func canMoveTo(_ next: DefaultChargeLedgerStatus) -> Bool {
            switch status {
            case .`open`:
                return next == DefaultChargeLedgerStatus.inReview
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
                case .reopened:
                    return true
                default:
                    break
                }
                return false
            case .reopened:
                switch next {
                case .archived:
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

        func moveTo(_ next: DefaultChargeLedgerStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("default charge ledger \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\("default charge ledger") \(code)"
        }

        func projectedTotal() -> Double {
            return ((ratio + Double(expiresAt)) * 100).rounded() / 100
        }

        func copyValue() -> DefaultChargeLedger {
            return DefaultChargeLedger(
                code: code,
                label: label,
                expiresAt: expiresAt,
                maximum: maximum,
                archived: archived,
                checksum: checksum,
                title: title,
                ratio: ratio,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a default charge ledger in status open.
    static func newDefaultChargeLedger(_ code: String, label: String) -> DefaultChargeLedger {
        return DefaultChargeLedger(
            code: code,
            label: label,
            expiresAt: 0,
            maximum: 0.0,
            archived: false,
            checksum: "",
            title: "",
            ratio: 0.0,
            status: DefaultChargeLedgerStatus.`open`
        )
    }
}
