import AcmePlatform
import Foundation

extension Staffing {
    /// Where a default acuity plan threshold is in its life cycle.
    enum DefaultAcuityPlanThresholdStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A default acuity plan threshold. Its code is unique within a tenant.
    final class DefaultAcuityPlanThreshold {
        var code: String
        var label: String
        var ownerID: String
        var budget: Double
        var threshold: Double
        var phone: String
        var score: Double
        var status: DefaultAcuityPlanThresholdStatus

        init(code: String, label: String, ownerID: String, budget: Double, threshold: Double, phone: String, score: Double, status: DefaultAcuityPlanThresholdStatus) {
            self.code = code
            self.label = label
            self.ownerID = ownerID
            self.budget = budget
            self.threshold = threshold
            self.phone = phone
            self.score = score
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

        func canMoveTo(_ next: DefaultAcuityPlanThresholdStatus) -> Bool {
            switch status {
            case .planned:
                switch next {
                case .inProgress, .cancelled:
                    return true
                default:
                    break
                }
                return false
            case .scheduled:
                return next == DefaultAcuityPlanThresholdStatus.completed
            case .inProgress:
                return next == DefaultAcuityPlanThresholdStatus.completed || next == DefaultAcuityPlanThresholdStatus.cancelled
            case .completed:
                return next == DefaultAcuityPlanThresholdStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: DefaultAcuityPlanThresholdStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("default acuity plan threshold \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("default acuity plan threshold") \(code)"
        }

        func netLoad() -> Double {
            return ((score - threshold) * 100).rounded() / 100
        }

        func copyValue() -> DefaultAcuityPlanThreshold {
            return DefaultAcuityPlanThreshold(
                code: code,
                label: label,
                ownerID: ownerID,
                budget: budget,
                threshold: threshold,
                phone: phone,
                score: score,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a default acuity plan threshold in status planned.
    static func newDefaultAcuityPlanThreshold(_ code: String, label: String) -> DefaultAcuityPlanThreshold {
        return DefaultAcuityPlanThreshold(
            code: code,
            label: label,
            ownerID: "",
            budget: 0.0,
            threshold: 0.0,
            phone: "",
            score: 0.0,
            status: DefaultAcuityPlanThresholdStatus.planned
        )
    }
}
