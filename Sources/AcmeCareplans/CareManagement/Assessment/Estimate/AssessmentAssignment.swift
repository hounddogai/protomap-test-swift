import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a assessment assignment is in its life cycle.
    enum AssessmentAssignmentStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// One assessment assignment, with what the planners need to act on it.
    final class AssessmentAssignment {
        var code: String
        var title: String
        var procedureCode: String
        var weight: Double
        var maximum: Double
        var status: AssessmentAssignmentStatus

        init(code: String, title: String, procedureCode: String, weight: Double, maximum: Double, status: AssessmentAssignmentStatus) {
            self.code = code
            self.title = title
            self.procedureCode = procedureCode
            self.weight = weight
            self.maximum = maximum
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

        func canMoveTo(_ next: AssessmentAssignmentStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .published, .retired:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                switch next {
                case .published, .retired:
                    return true
                default:
                    break
                }
                return false
            case .published:
                return next == AssessmentAssignmentStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: AssessmentAssignmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("assessment assignment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func effectiveTotal() -> Double {
            return (maximum * weight * 100).rounded() / 100
        }

        func copyValue() -> AssessmentAssignment {
            return AssessmentAssignment(
                code: code,
                title: title,
                procedureCode: procedureCode,
                weight: weight,
                maximum: maximum,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a assessment assignment in status created.
    static func newAssessmentAssignment(_ code: String, title: String) -> AssessmentAssignment {
        return AssessmentAssignment(
            code: code,
            title: title,
            procedureCode: "",
            weight: 0.0,
            maximum: 0.0,
            status: AssessmentAssignmentStatus.created
        )
    }
}
