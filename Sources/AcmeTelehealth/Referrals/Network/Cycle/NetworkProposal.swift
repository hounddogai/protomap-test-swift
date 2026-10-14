import AcmePlatform
import Foundation

extension Referrals {
    /// Where a network proposal is in its life cycle.
    enum NetworkProposalStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A network proposal. Its code is unique within a tenant.
    final class NetworkProposal {
        var code: String
        var label: String
        var summary: String
        var sequence: Int
        var visitMinutes: Int
        var visible: Bool
        var refills: Int
        var reviewer: String
        var status: NetworkProposalStatus

        init(code: String, label: String, summary: String, sequence: Int, visitMinutes: Int, visible: Bool, refills: Int, reviewer: String, status: NetworkProposalStatus) {
            self.code = code
            self.label = label
            self.summary = summary
            self.sequence = sequence
            self.visitMinutes = visitMinutes
            self.visible = visible
            self.refills = refills
            self.reviewer = reviewer
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

        func canMoveTo(_ next: NetworkProposalStatus) -> Bool {
            switch status {
            case .created:
                return next == NetworkProposalStatus.validated || next == NetworkProposalStatus.published
            case .validated:
                switch next {
                case .retired:
                    return true
                default:
                    break
                }
                return false
            case .published:
                return next == NetworkProposalStatus.retired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: NetworkProposalStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("network proposal \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) (\(label))"
        }

        func netTotal() -> Double {
            return ((Double(refills) - Double(visitMinutes)) * 100).rounded() / 100
        }

        func copyValue() -> NetworkProposal {
            return NetworkProposal(
                code: code,
                label: label,
                summary: summary,
                sequence: sequence,
                visitMinutes: visitMinutes,
                visible: visible,
                refills: refills,
                reviewer: reviewer,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a network proposal in status created.
    static func newNetworkProposal(_ code: String, label: String) -> NetworkProposal {
        return NetworkProposal(
            code: code,
            label: label,
            summary: "",
            sequence: 0,
            visitMinutes: 0,
            visible: false,
            refills: 0,
            reviewer: "",
            status: NetworkProposalStatus.created
        )
    }
}
