import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a global assessment milestone is in its life cycle.
    enum GlobalAssessmentMilestoneStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A global assessment milestone as the assessment team keeps it.
    final class GlobalAssessmentMilestone {
        var code: String
        var title: String
        var ceiling: Double
        var version: Int
        var threshold: Double
        var description: String
        var externalRef: String
        var status: GlobalAssessmentMilestoneStatus

        init(code: String, title: String, ceiling: Double, version: Int, threshold: Double, description: String, externalRef: String, status: GlobalAssessmentMilestoneStatus) {
            self.code = code
            self.title = title
            self.ceiling = ceiling
            self.version = version
            self.threshold = threshold
            self.description = description
            self.externalRef = externalRef
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

        func canMoveTo(_ next: GlobalAssessmentMilestoneStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .inReview, .resolved:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                switch next {
                case .resolved:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                return next == GlobalAssessmentMilestoneStatus.reopened || next == GlobalAssessmentMilestoneStatus.archived
            case .reopened:
                return next == GlobalAssessmentMilestoneStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: GlobalAssessmentMilestoneStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("global assessment milestone \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func label() -> String {
            return "\("global assessment milestone") \(code)"
        }

        func projectedExposure() -> Double {
            return (ceiling * threshold * 100).rounded() / 100
        }

        func copyValue() -> GlobalAssessmentMilestone {
            return GlobalAssessmentMilestone(
                code: code,
                title: title,
                ceiling: ceiling,
                version: version,
                threshold: threshold,
                description: description,
                externalRef: externalRef,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a global assessment milestone in status open.
    static func newGlobalAssessmentMilestone(_ code: String, title: String) -> GlobalAssessmentMilestone {
        return GlobalAssessmentMilestone(
            code: code,
            title: title,
            ceiling: 0.0,
            version: 0,
            threshold: 0.0,
            description: "",
            externalRef: "",
            status: GlobalAssessmentMilestoneStatus.`open`
        )
    }
}
