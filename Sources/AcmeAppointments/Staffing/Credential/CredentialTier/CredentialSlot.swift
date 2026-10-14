import AcmePlatform
import Foundation

extension Staffing {
    /// Where a credential slot is in its life cycle.
    enum CredentialSlotStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// One credential slot, with what the planners need to act on it.
    final class CredentialSlot {
        var code: String
        var label: String
        var endsAt: Int
        var cost: Double
        var quantity: Int
        var unit: String
        var capacity: Int
        var ratio: Double
        var clinicianID: String
        var status: CredentialSlotStatus

        init(code: String, label: String, endsAt: Int, cost: Double, quantity: Int, unit: String, capacity: Int, ratio: Double, clinicianID: String, status: CredentialSlotStatus) {
            self.code = code
            self.label = label
            self.endsAt = endsAt
            self.cost = cost
            self.quantity = quantity
            self.unit = unit
            self.capacity = capacity
            self.ratio = ratio
            self.clinicianID = clinicianID
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

        func canMoveTo(_ next: CredentialSlotStatus) -> Bool {
            switch status {
            case .created:
                return next == CredentialSlotStatus.published
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

        func moveTo(_ next: CredentialSlotStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("credential slot \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func weightedVolume() -> Double {
            return ((cost - Double(capacity)) * 100).rounded() / 100
        }

        func copyValue() -> CredentialSlot {
            return CredentialSlot(
                code: code,
                label: label,
                endsAt: endsAt,
                cost: cost,
                quantity: quantity,
                unit: unit,
                capacity: capacity,
                ratio: ratio,
                clinicianID: clinicianID,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a credential slot in status created.
    static func newCredentialSlot(_ code: String, label: String) -> CredentialSlot {
        return CredentialSlot(
            code: code,
            label: label,
            endsAt: 0,
            cost: 0.0,
            quantity: 0,
            unit: "",
            capacity: 0,
            ratio: 0.0,
            clinicianID: "",
            status: CredentialSlotStatus.created
        )
    }
}
