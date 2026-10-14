import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a alert cycle is in its life cycle.
    enum AlertCycleStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// The record of a alert cycle and its current status.
    final class AlertCycle {
        var code: String
        var label: String
        var category: String
        var ownerID: String
        var phone: String
        var currency: String
        var amount: Double
        var status: AlertCycleStatus

        init(code: String, label: String, category: String, ownerID: String, phone: String, currency: String, amount: Double, status: AlertCycleStatus) {
            self.code = code
            self.label = label
            self.category = category
            self.ownerID = ownerID
            self.phone = phone
            self.currency = currency
            self.amount = amount
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

        func canMoveTo(_ next: AlertCycleStatus) -> Bool {
            switch status {
            case .created:
                return next == AlertCycleStatus.retired
            case .validated:
                switch next {
                case .published, .retired:
                    return true
                default:
                    break
                }
                return false
            case .published:
                return next == AlertCycleStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: AlertCycleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("alert cycle \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func measuredValue() -> Double {
            return amount
        }

        func copyValue() -> AlertCycle {
            return AlertCycle(
                code: code,
                label: label,
                category: category,
                ownerID: ownerID,
                phone: phone,
                currency: currency,
                amount: amount,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a alert cycle in status created.
    static func newAlertCycle(_ code: String, label: String) -> AlertCycle {
        return AlertCycle(
            code: code,
            label: label,
            category: "",
            ownerID: "",
            phone: "",
            currency: "",
            amount: 0.0,
            status: AlertCycleStatus.created
        )
    }
}
