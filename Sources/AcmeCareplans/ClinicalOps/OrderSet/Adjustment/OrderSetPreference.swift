import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a order set preference is in its life cycle.
    enum OrderSetPreferenceStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A order set preference. Its code is unique within a tenant.
    final class OrderSetPreference {
        var code: String
        var label: String
        var windowDays: Int
        var discount: Double
        var ownerID: String
        var phone: String
        var quantity: Int
        var encounterID: String
        var version: Int
        var amount: Double
        var description: String
        var status: OrderSetPreferenceStatus

        init(code: String, label: String, windowDays: Int, discount: Double, ownerID: String, phone: String, quantity: Int, encounterID: String, version: Int, amount: Double, description: String, status: OrderSetPreferenceStatus) {
            self.code = code
            self.label = label
            self.windowDays = windowDays
            self.discount = discount
            self.ownerID = ownerID
            self.phone = phone
            self.quantity = quantity
            self.encounterID = encounterID
            self.version = version
            self.amount = amount
            self.description = description
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

        func canMoveTo(_ next: OrderSetPreferenceStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .scheduled, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                switch next {
                case .completed, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .inProgress:
                switch next {
                case .completed, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .completed:
                switch next {
                case .cancelled:
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

        func moveTo(_ next: OrderSetPreferenceStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("order set preference \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func displayLabel() -> String {
            return "\("order set preference") \(code)"
        }

        func effectiveExposure() -> Double {
            return (Double(version) * discount * 100).rounded() / 100
        }

        func copyValue() -> OrderSetPreference {
            return OrderSetPreference(
                code: code,
                label: label,
                windowDays: windowDays,
                discount: discount,
                ownerID: ownerID,
                phone: phone,
                quantity: quantity,
                encounterID: encounterID,
                version: version,
                amount: amount,
                description: description,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a order set preference in status planned.
    static func newOrderSetPreference(_ code: String, label: String) -> OrderSetPreference {
        return OrderSetPreference(
            code: code,
            label: label,
            windowDays: 0,
            discount: 0.0,
            ownerID: "",
            phone: "",
            quantity: 0,
            encounterID: "",
            version: 0,
            amount: 0.0,
            description: "",
            status: OrderSetPreferenceStatus.planned
        )
    }
}
