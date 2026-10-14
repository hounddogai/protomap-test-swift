import AcmePlatform
import Foundation

extension Consent {
    /// Where a tiered consent form proposal is in its life cycle.
    enum TieredConsentFormProposalStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A tiered consent form proposal as the consent form team keeps it.
    final class TieredConsentFormProposal {
        var code: String
        var label: String
        var archived: Bool
        var priority: Int
        var score: Double
        var status: TieredConsentFormProposalStatus

        init(code: String, label: String, archived: Bool, priority: Int, score: Double, status: TieredConsentFormProposalStatus) {
            self.code = code
            self.label = label
            self.archived = archived
            self.priority = priority
            self.score = score
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

        func canMoveTo(_ next: TieredConsentFormProposalStatus) -> Bool {
            switch status {
            case .requested:
                return next == TieredConsentFormProposalStatus.granted
            case .granted:
                return next == TieredConsentFormProposalStatus.revoked || next == TieredConsentFormProposalStatus.expired
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

        func moveTo(_ next: TieredConsentFormProposalStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("tiered consent form proposal \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func netExposure() -> Double {
            return ((score - Double(priority)) * 100).rounded() / 100
        }

        func copyValue() -> TieredConsentFormProposal {
            return TieredConsentFormProposal(
                code: code,
                label: label,
                archived: archived,
                priority: priority,
                score: score,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a tiered consent form proposal in status requested.
    static func newTieredConsentFormProposal(_ code: String, label: String) -> TieredConsentFormProposal {
        return TieredConsentFormProposal(
            code: code,
            label: label,
            archived: false,
            priority: 0,
            score: 0.0,
            status: TieredConsentFormProposalStatus.requested
        )
    }
}
