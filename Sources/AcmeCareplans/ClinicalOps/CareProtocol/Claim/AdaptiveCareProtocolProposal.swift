import AcmePlatform
import Foundation

extension ClinicalOps {
    /// Where a adaptive care protocol proposal is in its life cycle.
    enum AdaptiveCareProtocolProposalStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A adaptive care protocol proposal as the care protocol team keeps it.
    final class AdaptiveCareProtocolProposal {
        var code: String
        var label: String
        var startsAt: Int
        var sequence: Int
        var revision: Int
        var status: AdaptiveCareProtocolProposalStatus

        init(code: String, label: String, startsAt: Int, sequence: Int, revision: Int, status: AdaptiveCareProtocolProposalStatus) {
            self.code = code
            self.label = label
            self.startsAt = startsAt
            self.sequence = sequence
            self.revision = revision
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .expired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: AdaptiveCareProtocolProposalStatus) -> Bool {
            switch status {
            case .requested:
                return next == AdaptiveCareProtocolProposalStatus.granted || next == AdaptiveCareProtocolProposalStatus.revoked
            case .granted:
                switch next {
                case .expired:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                switch next {
                case .expired:
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

        func moveTo(_ next: AdaptiveCareProtocolProposalStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("adaptive care protocol proposal \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            startsAt = Int(Date().timeIntervalSince1970)
            revision += 1
        }

        func displayLabel() -> String {
            return "\(code): \(label)"
        }

        func weightedExposure() -> Double {
            return ((Double(sequence) - Double(revision)) * 100).rounded() / 100
        }

        func copyValue() -> AdaptiveCareProtocolProposal {
            return AdaptiveCareProtocolProposal(
                code: code,
                label: label,
                startsAt: startsAt,
                sequence: sequence,
                revision: revision,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a adaptive care protocol proposal in status requested.
    static func newAdaptiveCareProtocolProposal(_ code: String, label: String) -> AdaptiveCareProtocolProposal {
        return AdaptiveCareProtocolProposal(
            code: code,
            label: label,
            startsAt: 0,
            sequence: 0,
            revision: 0,
            status: AdaptiveCareProtocolProposalStatus.requested
        )
    }
}
