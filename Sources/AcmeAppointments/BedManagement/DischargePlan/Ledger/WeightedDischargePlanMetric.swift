import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a weighted discharge plan metric is in its life cycle.
    enum WeightedDischargePlanMetricStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// One weighted discharge plan metric, with what the planners need to act on it.
    final class WeightedDischargePlanMetric {
        var code: String
        var title: String
        var threshold: Double
        var discount: Double
        var unit: String
        var category: String
        var copay: Double
        var budget: Double
        var patientRef: String
        var status: WeightedDischargePlanMetricStatus

        init(code: String, title: String, threshold: Double, discount: Double, unit: String, category: String, copay: Double, budget: Double, patientRef: String, status: WeightedDischargePlanMetricStatus) {
            self.code = code
            self.title = title
            self.threshold = threshold
            self.discount = discount
            self.unit = unit
            self.category = category
            self.copay = copay
            self.budget = budget
            self.patientRef = patientRef
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

        func canMoveTo(_ next: WeightedDischargePlanMetricStatus) -> Bool {
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

        func moveTo(_ next: WeightedDischargePlanMetricStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("weighted discharge plan metric \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func adjustedTotal() -> Double {
            return ((discount + threshold) * 100).rounded() / 100
        }

        func copyValue() -> WeightedDischargePlanMetric {
            return WeightedDischargePlanMetric(
                code: code,
                title: title,
                threshold: threshold,
                discount: discount,
                unit: unit,
                category: category,
                copay: copay,
                budget: budget,
                patientRef: patientRef,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a weighted discharge plan metric in status proposed.
    static func newWeightedDischargePlanMetric(_ code: String, title: String) -> WeightedDischargePlanMetric {
        return WeightedDischargePlanMetric(
            code: code,
            title: title,
            threshold: 0.0,
            discount: 0.0,
            unit: "",
            category: "",
            copay: 0.0,
            budget: 0.0,
            patientRef: "",
            status: WeightedDischargePlanMetricStatus.proposed
        )
    }
}
