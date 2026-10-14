import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a remittance slot is in its life cycle.
    enum RemittanceSlotStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// The record of a remittance slot and its current status.
    final class RemittanceSlot {
        var code: String
        var title: String
        var weight: Double
        var clinicianID: String
        var allergy: String
        var status: RemittanceSlotStatus

        init(code: String, title: String, weight: Double, clinicianID: String, allergy: String, status: RemittanceSlotStatus) {
            self.code = code
            self.title = title
            self.weight = weight
            self.clinicianID = clinicianID
            self.allergy = allergy
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

        func canMoveTo(_ next: RemittanceSlotStatus) -> Bool {
            switch status {
            case .proposed:
                return next == RemittanceSlotStatus.rejected
            case .approved:
                switch next {
                case .rejected:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                switch next {
                case .withdrawn:
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

        func moveTo(_ next: RemittanceSlotStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("remittance slot \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func measuredValue() -> Double {
            return weight
        }

        func copyValue() -> RemittanceSlot {
            return RemittanceSlot(
                code: code,
                title: title,
                weight: weight,
                clinicianID: clinicianID,
                allergy: allergy,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a remittance slot in status proposed.
    static func newRemittanceSlot(_ code: String, title: String) -> RemittanceSlot {
        return RemittanceSlot(
            code: code,
            title: title,
            weight: 0.0,
            clinicianID: "",
            allergy: "",
            status: RemittanceSlotStatus.proposed
        )
    }
}
