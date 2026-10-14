import AcmePlatform
import Foundation

extension Imaging {
    /// Where a study proposal is in its life cycle.
    enum StudyProposalStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A study proposal as the study team keeps it.
    final class StudyProposal {
        var code: String
        var title: String
        var ownerID: String
        var clinicianID: String
        var minimum: Double
        var description: String
        var status: StudyProposalStatus

        init(code: String, title: String, ownerID: String, clinicianID: String, minimum: Double, description: String, status: StudyProposalStatus) {
            self.code = code
            self.title = title
            self.ownerID = ownerID
            self.clinicianID = clinicianID
            self.minimum = minimum
            self.description = description
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

        func canMoveTo(_ next: StudyProposalStatus) -> Bool {
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
                return next == StudyProposalStatus.active || next == StudyProposalStatus.closed
            case .active:
                return next == StudyProposalStatus.suspended
            case .suspended:
                return next == StudyProposalStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: StudyProposalStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("study proposal \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func measuredValue() -> Double {
            return minimum
        }

        func copyValue() -> StudyProposal {
            return StudyProposal(
                code: code,
                title: title,
                ownerID: ownerID,
                clinicianID: clinicianID,
                minimum: minimum,
                description: description,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a study proposal in status draft.
    static func newStudyProposal(_ code: String, title: String) -> StudyProposal {
        return StudyProposal(
            code: code,
            title: title,
            ownerID: "",
            clinicianID: "",
            minimum: 0.0,
            description: "",
            status: StudyProposalStatus.draft
        )
    }
}
