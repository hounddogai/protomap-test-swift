import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a weighted outreach slot is in its life cycle.
    enum WeightedOutreachSlotStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A weighted outreach slot. Its code is unique within a tenant.
    final class WeightedOutreachSlot {
        var code: String
        var label: String
        var updatedAt: Int
        var contactEmail: String
        var channel: String
        var quantity: Int
        var diagnosisCode: String
        var currency: String
        var visible: Bool
        var category: String
        var title: String
        var status: WeightedOutreachSlotStatus

        init(code: String, label: String, updatedAt: Int, contactEmail: String, channel: String, quantity: Int, diagnosisCode: String, currency: String, visible: Bool, category: String, title: String, status: WeightedOutreachSlotStatus) {
            self.code = code
            self.label = label
            self.updatedAt = updatedAt
            self.contactEmail = contactEmail
            self.channel = channel
            self.quantity = quantity
            self.diagnosisCode = diagnosisCode
            self.currency = currency
            self.visible = visible
            self.category = category
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

        func canMoveTo(_ next: WeightedOutreachSlotStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .completed:
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

        func moveTo(_ next: WeightedOutreachSlotStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("weighted outreach slot \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func projectedLoad() -> Double {
            return (Double(updatedAt) * Double(quantity) * 100).rounded() / 100
        }

        func copyValue() -> WeightedOutreachSlot {
            return WeightedOutreachSlot(
                code: code,
                label: label,
                updatedAt: updatedAt,
                contactEmail: contactEmail,
                channel: channel,
                quantity: quantity,
                diagnosisCode: diagnosisCode,
                currency: currency,
                visible: visible,
                category: category,
                title: title,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a weighted outreach slot in status planned.
    static func newWeightedOutreachSlot(_ code: String, label: String) -> WeightedOutreachSlot {
        return WeightedOutreachSlot(
            code: code,
            label: label,
            updatedAt: 0,
            contactEmail: "",
            channel: "",
            quantity: 0,
            diagnosisCode: "",
            currency: "",
            visible: false,
            category: "",
            title: "",
            status: WeightedOutreachSlotStatus.planned
        )
    }
}
