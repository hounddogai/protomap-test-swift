import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a assessment milestone is in its life cycle.
    enum AssessmentMilestoneStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// The record of a assessment milestone and its current status.
    final class AssessmentMilestone {
        var code: String
        var label: String
        var description: String
        var specialty: String
        var margin: Double
        var bed: String
        var status: AssessmentMilestoneStatus

        init(code: String, label: String, description: String, specialty: String, margin: Double, bed: String, status: AssessmentMilestoneStatus) {
            self.code = code
            self.label = label
            self.description = description
            self.specialty = specialty
            self.margin = margin
            self.bed = bed
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

        func canMoveTo(_ next: AssessmentMilestoneStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .reopened, .archived:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                switch next {
                case .archived:
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
                return next == AssessmentMilestoneStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: AssessmentMilestoneStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("assessment milestone \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func measuredValue() -> Double {
            return margin
        }

        func copyValue() -> AssessmentMilestone {
            return AssessmentMilestone(
                code: code,
                label: label,
                description: description,
                specialty: specialty,
                margin: margin,
                bed: bed,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a assessment milestone in status open.
    static func newAssessmentMilestone(_ code: String, label: String) -> AssessmentMilestone {
        return AssessmentMilestone(
            code: code,
            label: label,
            description: "",
            specialty: "",
            margin: 0.0,
            bed: "",
            status: AssessmentMilestoneStatus.`open`
        )
    }
}
