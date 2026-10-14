import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a adaptive assessment metric is in its life cycle.
    enum AdaptiveAssessmentMetricStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// The record of a adaptive assessment metric and its current status.
    final class AdaptiveAssessmentMetric {
        var code: String
        var title: String
        var margin: Double
        var attempts: Int
        var diagnosisCode: String
        var notes: String
        var retries: Int
        var category: String
        var status: AdaptiveAssessmentMetricStatus

        init(code: String, title: String, margin: Double, attempts: Int, diagnosisCode: String, notes: String, retries: Int, category: String, status: AdaptiveAssessmentMetricStatus) {
            self.code = code
            self.title = title
            self.margin = margin
            self.attempts = attempts
            self.diagnosisCode = diagnosisCode
            self.notes = notes
            self.retries = retries
            self.category = category
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

        func canMoveTo(_ next: AdaptiveAssessmentMetricStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .archived:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                return next == AdaptiveAssessmentMetricStatus.reopened || next == AdaptiveAssessmentMetricStatus.archived
            case .resolved:
                return next == AdaptiveAssessmentMetricStatus.reopened || next == AdaptiveAssessmentMetricStatus.archived
            case .reopened:
                switch next {
                case .archived:
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

        func moveTo(_ next: AdaptiveAssessmentMetricStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("adaptive assessment metric \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("adaptive assessment metric") \(code)"
        }

        func adjustedTotal() -> Double {
            return ((Double(retries) - Double(attempts)) * 100).rounded() / 100
        }

        func copyValue() -> AdaptiveAssessmentMetric {
            return AdaptiveAssessmentMetric(
                code: code,
                title: title,
                margin: margin,
                attempts: attempts,
                diagnosisCode: diagnosisCode,
                notes: notes,
                retries: retries,
                category: category,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a adaptive assessment metric in status open.
    static func newAdaptiveAssessmentMetric(_ code: String, title: String) -> AdaptiveAssessmentMetric {
        return AdaptiveAssessmentMetric(
            code: code,
            title: title,
            margin: 0.0,
            attempts: 0,
            diagnosisCode: "",
            notes: "",
            retries: 0,
            category: "",
            status: AdaptiveAssessmentMetricStatus.`open`
        )
    }
}
