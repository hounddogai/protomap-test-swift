import AcmePlatform
import Foundation

extension Staffing {
    /// Where a weighted acuity plan budget is in its life cycle.
    enum WeightedAcuityPlanBudgetStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A weighted acuity plan budget. Its code is unique within a tenant.
    final class WeightedAcuityPlanBudget {
        var code: String
        var label: String
        var ratio: Double
        var refills: Int
        var priority: Int
        var weight: Double
        var contactEmail: String
        var capacity: Int
        var segment: String
        var locale: String
        var status: WeightedAcuityPlanBudgetStatus

        init(code: String, label: String, ratio: Double, refills: Int, priority: Int, weight: Double, contactEmail: String, capacity: Int, segment: String, locale: String, status: WeightedAcuityPlanBudgetStatus) {
            self.code = code
            self.label = label
            self.ratio = ratio
            self.refills = refills
            self.priority = priority
            self.weight = weight
            self.contactEmail = contactEmail
            self.capacity = capacity
            self.segment = segment
            self.locale = locale
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

        func canMoveTo(_ next: WeightedAcuityPlanBudgetStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .approved:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                return next == WeightedAcuityPlanBudgetStatus.rejected || next == WeightedAcuityPlanBudgetStatus.withdrawn
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

        func moveTo(_ next: WeightedAcuityPlanBudgetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("weighted acuity plan budget \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("weighted acuity plan budget") \(code)"
        }

        func adjustedTotal() -> Double {
            return (Double(refills) * Double(priority) * 100).rounded() / 100
        }

        func copyValue() -> WeightedAcuityPlanBudget {
            return WeightedAcuityPlanBudget(
                code: code,
                label: label,
                ratio: ratio,
                refills: refills,
                priority: priority,
                weight: weight,
                contactEmail: contactEmail,
                capacity: capacity,
                segment: segment,
                locale: locale,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(segment)
        }
    }

    /// Starts a weighted acuity plan budget in status proposed.
    static func newWeightedAcuityPlanBudget(_ code: String, label: String) -> WeightedAcuityPlanBudget {
        return WeightedAcuityPlanBudget(
            code: code,
            label: label,
            ratio: 0.0,
            refills: 0,
            priority: 0,
            weight: 0.0,
            contactEmail: "",
            capacity: 0,
            segment: "",
            locale: "",
            status: WeightedAcuityPlanBudgetStatus.proposed
        )
    }
}
