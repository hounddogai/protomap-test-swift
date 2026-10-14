import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a assessment variance is in its life cycle.
    enum AssessmentVarianceStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// One assessment variance, with what the planners need to act on it.
    final class AssessmentVariance {
        var code: String
        var title: String
        var margin: Double
        var region: String
        var archived: Bool
        var refills: Int
        var graceDays: Int
        var attempts: Int
        var status: AssessmentVarianceStatus

        init(code: String, title: String, margin: Double, region: String, archived: Bool, refills: Int, graceDays: Int, attempts: Int, status: AssessmentVarianceStatus) {
            self.code = code
            self.title = title
            self.margin = margin
            self.region = region
            self.archived = archived
            self.refills = refills
            self.graceDays = graceDays
            self.attempts = attempts
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

        func canMoveTo(_ next: AssessmentVarianceStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .inReview, .archived:
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
                return next == AssessmentVarianceStatus.archived
            case .reopened:
                return next == AssessmentVarianceStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: AssessmentVarianceStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("assessment variance \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func weightedExposure() -> Double {
            return ((Double(attempts) - margin) * 100).rounded() / 100
        }

        func copyValue() -> AssessmentVariance {
            return AssessmentVariance(
                code: code,
                title: title,
                margin: margin,
                region: region,
                archived: archived,
                refills: refills,
                graceDays: graceDays,
                attempts: attempts,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a assessment variance in status open.
    static func newAssessmentVariance(_ code: String, title: String) -> AssessmentVariance {
        return AssessmentVariance(
            code: code,
            title: title,
            margin: 0.0,
            region: "",
            archived: false,
            refills: 0,
            graceDays: 0,
            attempts: 0,
            status: AssessmentVarianceStatus.`open`
        )
    }
}
