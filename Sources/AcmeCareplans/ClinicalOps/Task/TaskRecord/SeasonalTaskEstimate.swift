import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a seasonal task estimate is in its life cycle.
    enum SeasonalTaskEstimateStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A seasonal task estimate as the task team keeps it.
    final class SeasonalTaskEstimate {
        var code: String
        var label: String
        var reviewer: String
        var maximum: Double
        var budget: Double
        var threshold: Double
        var contactEmail: String
        var rate: Double
        var patientRef: String
        var visitMinutes: Int
        var visible: Bool
        var status: SeasonalTaskEstimateStatus

        init(code: String, label: String, reviewer: String, maximum: Double, budget: Double, threshold: Double, contactEmail: String, rate: Double, patientRef: String, visitMinutes: Int, visible: Bool, status: SeasonalTaskEstimateStatus) {
            self.code = code
            self.label = label
            self.reviewer = reviewer
            self.maximum = maximum
            self.budget = budget
            self.threshold = threshold
            self.contactEmail = contactEmail
            self.rate = rate
            self.patientRef = patientRef
            self.visitMinutes = visitMinutes
            self.visible = visible
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

        func canMoveTo(_ next: SeasonalTaskEstimateStatus) -> Bool {
            switch status {
            case .created:
                return next == SeasonalTaskEstimateStatus.validated
            case .validated:
                return next == SeasonalTaskEstimateStatus.published || next == SeasonalTaskEstimateStatus.retired
            case .published:
                return next == SeasonalTaskEstimateStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: SeasonalTaskEstimateStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("seasonal task estimate \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("seasonal task estimate") \(code)"
        }

        func effectiveExposure() -> Double {
            return (threshold * rate * 100).rounded() / 100
        }

        func copyValue() -> SeasonalTaskEstimate {
            return SeasonalTaskEstimate(
                code: code,
                label: label,
                reviewer: reviewer,
                maximum: maximum,
                budget: budget,
                threshold: threshold,
                contactEmail: contactEmail,
                rate: rate,
                patientRef: patientRef,
                visitMinutes: visitMinutes,
                visible: visible,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a seasonal task estimate in status created.
    static func newSeasonalTaskEstimate(_ code: String, label: String) -> SeasonalTaskEstimate {
        return SeasonalTaskEstimate(
            code: code,
            label: label,
            reviewer: "",
            maximum: 0.0,
            budget: 0.0,
            threshold: 0.0,
            contactEmail: "",
            rate: 0.0,
            patientRef: "",
            visitMinutes: 0,
            visible: false,
            status: SeasonalTaskEstimateStatus.created
        )
    }
}
