import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a care gap plan is in its life cycle.
    enum CareGapPlanStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A care gap plan. Its code is unique within a tenant.
    final class CareGapPlan {
        var code: String
        var label: String
        var diagnosisCode: String
        var visible: Bool
        var priority: Int
        var durationMinutes: Int
        var weight: Double
        var maximum: Double
        var bed: String
        var quantity: Int
        var status: CareGapPlanStatus

        init(code: String, label: String, diagnosisCode: String, visible: Bool, priority: Int, durationMinutes: Int, weight: Double, maximum: Double, bed: String, quantity: Int, status: CareGapPlanStatus) {
            self.code = code
            self.label = label
            self.diagnosisCode = diagnosisCode
            self.visible = visible
            self.priority = priority
            self.durationMinutes = durationMinutes
            self.weight = weight
            self.maximum = maximum
            self.bed = bed
            self.quantity = quantity
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .archived:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: CareGapPlanStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .resolved, .reopened:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                switch next {
                case .resolved, .reopened:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                switch next {
                case .reopened, .archived:
                    return true
                default:
                    break
                }
                return false
            case .reopened:
                return next == CareGapPlanStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: CareGapPlanStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("care gap plan \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("care gap plan") \(code)"
        }

        func netLoad() -> Double {
            return ((Double(priority) + maximum) * 100).rounded() / 100
        }

        func copyValue() -> CareGapPlan {
            return CareGapPlan(
                code: code,
                label: label,
                diagnosisCode: diagnosisCode,
                visible: visible,
                priority: priority,
                durationMinutes: durationMinutes,
                weight: weight,
                maximum: maximum,
                bed: bed,
                quantity: quantity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a care gap plan in status open.
    static func newCareGapPlan(_ code: String, label: String) -> CareGapPlan {
        return CareGapPlan(
            code: code,
            label: label,
            diagnosisCode: "",
            visible: false,
            priority: 0,
            durationMinutes: 0,
            weight: 0.0,
            maximum: 0.0,
            bed: "",
            quantity: 0,
            status: CareGapPlanStatus.`open`
        )
    }
}
