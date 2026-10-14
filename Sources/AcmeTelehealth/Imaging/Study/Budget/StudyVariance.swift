import AcmePlatform
import Foundation

extension Imaging {
    /// Where a study variance is in its life cycle.
    enum StudyVarianceStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A study variance. Its code is unique within a tenant.
    final class StudyVariance {
        var code: String
        var title: String
        var budget: Double
        var attempts: Int
        var label: String
        var revision: Int
        var ceiling: Double
        var status: StudyVarianceStatus

        init(code: String, title: String, budget: Double, attempts: Int, label: String, revision: Int, ceiling: Double, status: StudyVarianceStatus) {
            self.code = code
            self.title = title
            self.budget = budget
            self.attempts = attempts
            self.label = label
            self.revision = revision
            self.ceiling = ceiling
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

        func canMoveTo(_ next: StudyVarianceStatus) -> Bool {
            switch status {
            case .`open`:
                return next == StudyVarianceStatus.resolved
            case .inReview:
                return next == StudyVarianceStatus.archived
            case .resolved:
                return next == StudyVarianceStatus.reopened || next == StudyVarianceStatus.archived
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

        func moveTo(_ next: StudyVarianceStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("study variance \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func displayLabel() -> String {
            return "\(code) [\(title)]"
        }

        func effectiveTotal() -> Double {
            return ((budget + ceiling) * 100).rounded() / 100
        }

        func copyValue() -> StudyVariance {
            return StudyVariance(
                code: code,
                title: title,
                budget: budget,
                attempts: attempts,
                label: label,
                revision: revision,
                ceiling: ceiling,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a study variance in status open.
    static func newStudyVariance(_ code: String, title: String) -> StudyVariance {
        return StudyVariance(
            code: code,
            title: title,
            budget: 0.0,
            attempts: 0,
            label: "",
            revision: 0,
            ceiling: 0.0,
            status: StudyVarianceStatus.`open`
        )
    }
}
