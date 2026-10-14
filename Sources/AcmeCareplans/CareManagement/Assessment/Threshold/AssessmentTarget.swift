import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a assessment target is in its life cycle.
    enum AssessmentTargetStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// The record of a assessment target and its current status.
    final class AssessmentTarget {
        var code: String
        var label: String
        var rate: Double
        var active: Bool
        var budget: Double
        var status: AssessmentTargetStatus

        init(code: String, label: String, rate: Double, active: Bool, budget: Double, status: AssessmentTargetStatus) {
            self.code = code
            self.label = label
            self.rate = rate
            self.active = active
            self.budget = budget
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

        func canMoveTo(_ next: AssessmentTargetStatus) -> Bool {
            switch status {
            case .`open`:
                return next == AssessmentTargetStatus.reopened
            case .inReview:
                return next == AssessmentTargetStatus.archived
            case .resolved:
                switch next {
                case .reopened:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: AssessmentTargetStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("assessment target \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func netTotal() -> Double {
            return ((rate + budget) * 100).rounded() / 100
        }

        func copyValue() -> AssessmentTarget {
            return AssessmentTarget(
                code: code,
                label: label,
                rate: rate,
                active: active,
                budget: budget,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a assessment target in status open.
    static func newAssessmentTarget(_ code: String, label: String) -> AssessmentTarget {
        return AssessmentTarget(
            code: code,
            label: label,
            rate: 0.0,
            active: false,
            budget: 0.0,
            status: AssessmentTargetStatus.`open`
        )
    }
}
