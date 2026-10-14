import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a bed board plan is in its life cycle.
    enum BedBoardPlanStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// One bed board plan, with what the planners need to act on it.
    final class BedBoardPlan {
        var code: String
        var label: String
        var copay: Double
        var procedureCode: String
        var unit: String
        var discount: Double
        var category: String
        var country: String
        var ceiling: Double
        var status: BedBoardPlanStatus

        init(code: String, label: String, copay: Double, procedureCode: String, unit: String, discount: Double, category: String, country: String, ceiling: Double, status: BedBoardPlanStatus) {
            self.code = code
            self.label = label
            self.copay = copay
            self.procedureCode = procedureCode
            self.unit = unit
            self.discount = discount
            self.category = category
            self.country = country
            self.ceiling = ceiling
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

        func canMoveTo(_ next: BedBoardPlanStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .granted, .revoked:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                switch next {
                case .revoked, .expired:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                switch next {
                case .expired:
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

        func moveTo(_ next: BedBoardPlanStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("bed board plan \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func projectedVolume() -> Double {
            return (copay * discount * 100).rounded() / 100
        }

        func copyValue() -> BedBoardPlan {
            return BedBoardPlan(
                code: code,
                label: label,
                copay: copay,
                procedureCode: procedureCode,
                unit: unit,
                discount: discount,
                category: category,
                country: country,
                ceiling: ceiling,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a bed board plan in status requested.
    static func newBedBoardPlan(_ code: String, label: String) -> BedBoardPlan {
        return BedBoardPlan(
            code: code,
            label: label,
            copay: 0.0,
            procedureCode: "",
            unit: "",
            discount: 0.0,
            category: "",
            country: "",
            ceiling: 0.0,
            status: BedBoardPlanStatus.requested
        )
    }
}
