import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a adaptive isolation review is in its life cycle.
    enum AdaptiveIsolationReviewStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// One adaptive isolation review, with what the planners need to act on it.
    final class AdaptiveIsolationReview {
        var code: String
        var title: String
        var maximum: Double
        var patientRef: String
        var updatedAt: Int
        var budget: Double
        var label: String
        var diagnosisCode: String
        var status: AdaptiveIsolationReviewStatus

        init(code: String, title: String, maximum: Double, patientRef: String, updatedAt: Int, budget: Double, label: String, diagnosisCode: String, status: AdaptiveIsolationReviewStatus) {
            self.code = code
            self.title = title
            self.maximum = maximum
            self.patientRef = patientRef
            self.updatedAt = updatedAt
            self.budget = budget
            self.label = label
            self.diagnosisCode = diagnosisCode
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .closed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: AdaptiveIsolationReviewStatus) -> Bool {
            switch status {
            case .draft:
                switch next {
                case .closed:
                    return true
                default:
                    break
                }
                return false
            case .pending:
                return next == AdaptiveIsolationReviewStatus.active || next == AdaptiveIsolationReviewStatus.closed
            case .active:
                switch next {
                case .closed:
                    return true
                default:
                    break
                }
                return false
            case .suspended:
                switch next {
                case .closed:
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

        func moveTo(_ next: AdaptiveIsolationReviewStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("adaptive isolation review \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code): \(title)"
        }

        func netExposure() -> Double {
            return (budget * maximum * 100).rounded() / 100
        }

        func copyValue() -> AdaptiveIsolationReview {
            return AdaptiveIsolationReview(
                code: code,
                title: title,
                maximum: maximum,
                patientRef: patientRef,
                updatedAt: updatedAt,
                budget: budget,
                label: label,
                diagnosisCode: diagnosisCode,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a adaptive isolation review in status draft.
    static func newAdaptiveIsolationReview(_ code: String, title: String) -> AdaptiveIsolationReview {
        return AdaptiveIsolationReview(
            code: code,
            title: title,
            maximum: 0.0,
            patientRef: "",
            updatedAt: 0,
            budget: 0.0,
            label: "",
            diagnosisCode: "",
            status: AdaptiveIsolationReviewStatus.draft
        )
    }
}
