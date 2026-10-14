import AcmePlatform
import Foundation

extension Pharmacy {
    /// Where a weighted inventory audit is in its life cycle.
    enum WeightedInventoryAuditStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A weighted inventory audit as the inventory team keeps it.
    final class WeightedInventoryAudit {
        var code: String
        var name: String
        var label: String
        var quantity: Int
        var specialty: String
        var facility: String
        var encounterID: String
        var retries: Int
        var contactEmail: String
        var discount: Double
        var channel: String
        var status: WeightedInventoryAuditStatus

        init(code: String, name: String, label: String, quantity: Int, specialty: String, facility: String, encounterID: String, retries: Int, contactEmail: String, discount: Double, channel: String, status: WeightedInventoryAuditStatus) {
            self.code = code
            self.name = name
            self.label = label
            self.quantity = quantity
            self.specialty = specialty
            self.facility = facility
            self.encounterID = encounterID
            self.retries = retries
            self.contactEmail = contactEmail
            self.discount = discount
            self.channel = channel
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .expired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: WeightedInventoryAuditStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .revoked, .expired:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                switch next {
                case .expired:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                return next == WeightedInventoryAuditStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: WeightedInventoryAuditStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("weighted inventory audit \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("weighted inventory audit") \(code)"
        }

        func effectiveValue() -> Double {
            return (Double(retries) * discount * 100).rounded() / 100
        }

        func copyValue() -> WeightedInventoryAudit {
            return WeightedInventoryAudit(
                code: code,
                name: name,
                label: label,
                quantity: quantity,
                specialty: specialty,
                facility: facility,
                encounterID: encounterID,
                retries: retries,
                contactEmail: contactEmail,
                discount: discount,
                channel: channel,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(facility)
        }
    }

    /// Starts a weighted inventory audit in status requested.
    static func newWeightedInventoryAudit(_ code: String, name: String) -> WeightedInventoryAudit {
        return WeightedInventoryAudit(
            code: code,
            name: name,
            label: "",
            quantity: 0,
            specialty: "",
            facility: "",
            encounterID: "",
            retries: 0,
            contactEmail: "",
            discount: 0.0,
            channel: "",
            status: WeightedInventoryAuditStatus.requested
        )
    }
}
