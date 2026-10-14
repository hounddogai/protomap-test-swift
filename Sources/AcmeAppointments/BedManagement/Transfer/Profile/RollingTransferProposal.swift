import AcmePlatform
import Foundation

extension BedManagement {
    /// Where a rolling transfer proposal is in its life cycle.
    enum RollingTransferProposalStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// One rolling transfer proposal, with what the planners need to act on it.
    final class RollingTransferProposal {
        var code: String
        var title: String
        var attempts: Int
        var channel: String
        var clinicianID: String
        var revision: Int
        var contactEmail: String
        var version: Int
        var name: String
        var status: RollingTransferProposalStatus

        init(code: String, title: String, attempts: Int, channel: String, clinicianID: String, revision: Int, contactEmail: String, version: Int, name: String, status: RollingTransferProposalStatus) {
            self.code = code
            self.title = title
            self.attempts = attempts
            self.channel = channel
            self.clinicianID = clinicianID
            self.revision = revision
            self.contactEmail = contactEmail
            self.version = version
            self.name = name
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

        func canMoveTo(_ next: RollingTransferProposalStatus) -> Bool {
            switch status {
            case .`open`:
                return next == RollingTransferProposalStatus.inReview || next == RollingTransferProposalStatus.archived
            case .inReview:
                return next == RollingTransferProposalStatus.reopened || next == RollingTransferProposalStatus.archived
            case .resolved:
                return next == RollingTransferProposalStatus.reopened || next == RollingTransferProposalStatus.archived
            case .reopened:
                return next == RollingTransferProposalStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RollingTransferProposalStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rolling transfer proposal \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func adjustedVolume() -> Double {
            return (Double(revision) * Double(attempts) * 100).rounded() / 100
        }

        func copyValue() -> RollingTransferProposal {
            return RollingTransferProposal(
                code: code,
                title: title,
                attempts: attempts,
                channel: channel,
                clinicianID: clinicianID,
                revision: revision,
                contactEmail: contactEmail,
                version: version,
                name: name,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a rolling transfer proposal in status open.
    static func newRollingTransferProposal(_ code: String, title: String) -> RollingTransferProposal {
        return RollingTransferProposal(
            code: code,
            title: title,
            attempts: 0,
            channel: "",
            clinicianID: "",
            revision: 0,
            contactEmail: "",
            version: 0,
            name: "",
            status: RollingTransferProposalStatus.`open`
        )
    }
}
