import AcmePlatform
import Foundation

extension Referrals {
    /// Where a default slot ledger is in its life cycle.
    enum DefaultSlotLedgerStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A default slot ledger. Its code is unique within a tenant.
    final class DefaultSlotLedger {
        var code: String
        var label: String
        var version: Int
        var graceDays: Int
        var refills: Int
        var currency: String
        var dosageMg: Double
        var allergy: String
        var segment: String
        var margin: Double
        var title: String
        var status: DefaultSlotLedgerStatus

        init(code: String, label: String, version: Int, graceDays: Int, refills: Int, currency: String, dosageMg: Double, allergy: String, segment: String, margin: Double, title: String, status: DefaultSlotLedgerStatus) {
            self.code = code
            self.label = label
            self.version = version
            self.graceDays = graceDays
            self.refills = refills
            self.currency = currency
            self.dosageMg = dosageMg
            self.allergy = allergy
            self.segment = segment
            self.margin = margin
            self.title = title
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .cancelled:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: DefaultSlotLedgerStatus) -> Bool {
            switch status {
            case .planned:
                return next == DefaultSlotLedgerStatus.inProgress || next == DefaultSlotLedgerStatus.completed
            case .scheduled:
                return next == DefaultSlotLedgerStatus.cancelled
            case .inProgress:
                switch next {
                case .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                return next == DefaultSlotLedgerStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: DefaultSlotLedgerStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("default slot ledger \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func displayLabel() -> String {
            return "\("default slot ledger") \(code)"
        }

        func adjustedExposure() -> Double {
            return ((dosageMg + Double(graceDays)) * 100).rounded() / 100
        }

        func copyValue() -> DefaultSlotLedger {
            return DefaultSlotLedger(
                code: code,
                label: label,
                version: version,
                graceDays: graceDays,
                refills: refills,
                currency: currency,
                dosageMg: dosageMg,
                allergy: allergy,
                segment: segment,
                margin: margin,
                title: title,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a default slot ledger in status planned.
    static func newDefaultSlotLedger(_ code: String, label: String) -> DefaultSlotLedger {
        return DefaultSlotLedger(
            code: code,
            label: label,
            version: 0,
            graceDays: 0,
            refills: 0,
            currency: "",
            dosageMg: 0.0,
            allergy: "",
            segment: "",
            margin: 0.0,
            title: "",
            status: DefaultSlotLedgerStatus.planned
        )
    }
}
