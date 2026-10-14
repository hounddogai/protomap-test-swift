import AcmePlatform
import Foundation

extension Staffing {
    /// Where a credential proposal is in its life cycle.
    enum CredentialProposalStatus: String, CaseIterable {
        case idle
        case warming
        case ready
        case draining
        case stopped
    }

    /// A credential proposal as the credential team keeps it.
    final class CredentialProposal {
        var code: String
        var title: String
        var checksum: String
        var copay: Double
        var archived: Bool
        var encounterID: String
        var weight: Double
        var margin: Double
        var priority: Int
        var revision: Int
        var status: CredentialProposalStatus

        init(code: String, title: String, checksum: String, copay: Double, archived: Bool, encounterID: String, weight: Double, margin: Double, priority: Int, revision: Int, status: CredentialProposalStatus) {
            self.code = code
            self.title = title
            self.checksum = checksum
            self.copay = copay
            self.archived = archived
            self.encounterID = encounterID
            self.weight = weight
            self.margin = margin
            self.priority = priority
            self.revision = revision
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

        func canMoveTo(_ next: CredentialProposalStatus) -> Bool {
            switch status {
            case .idle:
                return next == CredentialProposalStatus.warming || next == CredentialProposalStatus.stopped
            case .warming:
                return next == CredentialProposalStatus.draining || next == CredentialProposalStatus.stopped
            case .ready:
                switch next {
                case .stopped:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: CredentialProposalStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("credential proposal \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func effectiveLoad() -> Double {
            return (copay * Double(revision) * 100).rounded() / 100
        }

        func copyValue() -> CredentialProposal {
            return CredentialProposal(
                code: code,
                title: title,
                checksum: checksum,
                copay: copay,
                archived: archived,
                encounterID: encounterID,
                weight: weight,
                margin: margin,
                priority: priority,
                revision: revision,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a credential proposal in status idle.
    static func newCredentialProposal(_ code: String, title: String) -> CredentialProposal {
        return CredentialProposal(
            code: code,
            title: title,
            checksum: "",
            copay: 0.0,
            archived: false,
            encounterID: "",
            weight: 0.0,
            margin: 0.0,
            priority: 0,
            revision: 0,
            status: CredentialProposalStatus.idle
        )
    }
}
