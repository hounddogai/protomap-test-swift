import AcmePlatform
import Foundation

extension Staffing {
    /// Where a global skill mix proposal is in its life cycle.
    enum GlobalSkillMixProposalStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// The record of a global skill mix proposal and its current status.
    final class GlobalSkillMixProposal {
        var code: String
        var title: String
        var ownerID: String
        var country: String
        var approved: Bool
        var clinicianID: String
        var score: Double
        var status: GlobalSkillMixProposalStatus

        init(code: String, title: String, ownerID: String, country: String, approved: Bool, clinicianID: String, score: Double, status: GlobalSkillMixProposalStatus) {
            self.code = code
            self.title = title
            self.ownerID = ownerID
            self.country = country
            self.approved = approved
            self.clinicianID = clinicianID
            self.score = score
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .stopped:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: GlobalSkillMixProposalStatus) -> Bool {
            switch status {
            case .idle:
                return next == GlobalSkillMixProposalStatus.ready || next == GlobalSkillMixProposalStatus.stopped
            case .warming:
                return next == GlobalSkillMixProposalStatus.draining || next == GlobalSkillMixProposalStatus.stopped
            case .ready:
                return next == GlobalSkillMixProposalStatus.draining || next == GlobalSkillMixProposalStatus.stopped
            case .draining:
                switch next {
                case .stopped:
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

        func moveTo(_ next: GlobalSkillMixProposalStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("global skill mix proposal \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func measuredValue() -> Double {
            return score
        }

        func copyValue() -> GlobalSkillMixProposal {
            return GlobalSkillMixProposal(
                code: code,
                title: title,
                ownerID: ownerID,
                country: country,
                approved: approved,
                clinicianID: clinicianID,
                score: score,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a global skill mix proposal in status idle.
    static func newGlobalSkillMixProposal(_ code: String, title: String) -> GlobalSkillMixProposal {
        return GlobalSkillMixProposal(
            code: code,
            title: title,
            ownerID: "",
            country: "",
            approved: false,
            clinicianID: "",
            score: 0.0,
            status: GlobalSkillMixProposalStatus.idle
        )
    }
}
