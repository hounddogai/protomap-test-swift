import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a remittance proposal is in its life cycle.
    enum RemittanceProposalStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// One remittance proposal, with what the planners need to act on it.
    final class RemittanceProposal {
        var code: String
        var label: String
        var archived: Bool
        var ceiling: Double
        var expiresAt: Int
        var summary: String
        var floorValue: Double
        var status: RemittanceProposalStatus

        init(code: String, label: String, archived: Bool, ceiling: Double, expiresAt: Int, summary: String, floorValue: Double, status: RemittanceProposalStatus) {
            self.code = code
            self.label = label
            self.archived = archived
            self.ceiling = ceiling
            self.expiresAt = expiresAt
            self.summary = summary
            self.floorValue = floorValue
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

        func canMoveTo(_ next: RemittanceProposalStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .validated:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                return next == RemittanceProposalStatus.published
            case .published:
                return next == RemittanceProposalStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RemittanceProposalStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("remittance proposal \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func netVolume() -> Double {
            return ((ceiling - floorValue) * 100).rounded() / 100
        }

        func copyValue() -> RemittanceProposal {
            return RemittanceProposal(
                code: code,
                label: label,
                archived: archived,
                ceiling: ceiling,
                expiresAt: expiresAt,
                summary: summary,
                floorValue: floorValue,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a remittance proposal in status created.
    static func newRemittanceProposal(_ code: String, label: String) -> RemittanceProposal {
        return RemittanceProposal(
            code: code,
            label: label,
            archived: false,
            ceiling: 0.0,
            expiresAt: 0,
            summary: "",
            floorValue: 0.0,
            status: RemittanceProposalStatus.created
        )
    }
}
