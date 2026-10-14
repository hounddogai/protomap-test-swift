import AcmePlatform
import Foundation

extension CareManagement {
    /// Where a assessment proposal is in its life cycle.
    enum AssessmentProposalStatus: String, CaseIterable {
        case planned
        case scheduled
        case inProgress = "in_progress"
        case completed
        case cancelled
    }

    /// A assessment proposal as the assessment team keeps it.
    final class AssessmentProposal {
        var code: String
        var title: String
        var externalRef: String
        var patientRef: String
        var version: Int
        var status: AssessmentProposalStatus

        init(code: String, title: String, externalRef: String, patientRef: String, version: Int, status: AssessmentProposalStatus) {
            self.code = code
            self.title = title
            self.externalRef = externalRef
            self.patientRef = patientRef
            self.version = version
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

        func canMoveTo(_ next: AssessmentProposalStatus) -> Bool {
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
                return next == AssessmentProposalStatus.inProgress || next == AssessmentProposalStatus.completed
            case .inProgress:
                return next == AssessmentProposalStatus.completed || next == AssessmentProposalStatus.cancelled
            case .completed:
                return next == AssessmentProposalStatus.cancelled
            default:
                break
            }
            return false
        }

        func moveTo(_ next: AssessmentProposalStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("assessment proposal \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func measuredValue() -> Double {
            return Double(version)
        }

        func copyValue() -> AssessmentProposal {
            return AssessmentProposal(
                code: code,
                title: title,
                externalRef: externalRef,
                patientRef: patientRef,
                version: version,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a assessment proposal in status planned.
    static func newAssessmentProposal(_ code: String, title: String) -> AssessmentProposal {
        return AssessmentProposal(
            code: code,
            title: title,
            externalRef: "",
            patientRef: "",
            version: 0,
            status: AssessmentProposalStatus.planned
        )
    }
}
