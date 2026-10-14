import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a discharge plan template is in its life cycle.
    enum DischargePlanTemplateStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A discharge plan template. Its code is unique within a tenant.
    final class DischargePlanTemplate {
        var code: String
        var name: String
        var weight: Double
        var capacity: Int
        var notes: String
        var discount: Double
        var allergy: String
        var status: DischargePlanTemplateStatus

        init(code: String, name: String, weight: Double, capacity: Int, notes: String, discount: Double, allergy: String, status: DischargePlanTemplateStatus) {
            self.code = code
            self.name = name
            self.weight = weight
            self.capacity = capacity
            self.notes = notes
            self.discount = discount
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

        func canMoveTo(_ next: DischargePlanTemplateStatus) -> Bool {
            switch status {
            case .proposed:
                return next == DischargePlanTemplateStatus.approved
            case .approved:
                switch next {
                case .rejected, .withdrawn:
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

        func moveTo(_ next: DischargePlanTemplateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("discharge plan template \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("discharge plan template") \(code)"
        }

        func netTotal() -> Double {
            return ((weight - discount) * 100).rounded() / 100
        }

        func copyValue() -> DischargePlanTemplate {
            return DischargePlanTemplate(
                code: code,
                name: name,
                weight: weight,
                capacity: capacity,
                notes: notes,
                discount: discount,
                allergy: allergy,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a discharge plan template in status proposed.
    static func newDischargePlanTemplate(_ code: String, name: String) -> DischargePlanTemplate {
        return DischargePlanTemplate(
            code: code,
            name: name,
            weight: 0.0,
            capacity: 0,
            notes: "",
            discount: 0.0,
            allergy: "",
            status: DischargePlanTemplateStatus.proposed
        )
    }
}
