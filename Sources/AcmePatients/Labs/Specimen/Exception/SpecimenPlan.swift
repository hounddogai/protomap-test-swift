import AcmePlatform
import Foundation

extension Labs {
    /// Where a specimen plan is in its life cycle.
    enum SpecimenPlanStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A specimen plan as the specimen team keeps it.
    final class SpecimenPlan {
        var code: String
        var label: String
        var clinicianID: String
        var description: String
        var payer: String
        var unit: String
        var quantity: Int
        var status: SpecimenPlanStatus

        init(code: String, label: String, clinicianID: String, description: String, payer: String, unit: String, quantity: Int, status: SpecimenPlanStatus) {
            self.code = code
            self.label = label
            self.clinicianID = clinicianID
            self.description = description
            self.payer = payer
            self.unit = unit
            self.quantity = quantity
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

        func canMoveTo(_ next: SpecimenPlanStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .validated:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                switch next {
                case .published:
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

        func moveTo(_ next: SpecimenPlanStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("specimen plan \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func measuredValue() -> Double {
            return Double(quantity)
        }

        func copyValue() -> SpecimenPlan {
            return SpecimenPlan(
                code: code,
                label: label,
                clinicianID: clinicianID,
                description: description,
                payer: payer,
                unit: unit,
                quantity: quantity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a specimen plan in status created.
    static func newSpecimenPlan(_ code: String, label: String) -> SpecimenPlan {
        return SpecimenPlan(
            code: code,
            label: label,
            clinicianID: "",
            description: "",
            payer: "",
            unit: "",
            quantity: 0,
            status: SpecimenPlanStatus.created
        )
    }
}
