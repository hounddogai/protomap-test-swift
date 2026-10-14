import AcmePlatform
import Foundation

extension Labs {
    /// Where a rolling specimen proposal is in its life cycle.
    enum RollingSpecimenProposalStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A rolling specimen proposal. Its code is unique within a tenant.
    final class RollingSpecimenProposal {
        var code: String
        var name: String
        var visitMinutes: Int
        var channel: String
        var externalRef: String
        var attempts: Int
        var status: RollingSpecimenProposalStatus

        init(code: String, name: String, visitMinutes: Int, channel: String, externalRef: String, attempts: Int, status: RollingSpecimenProposalStatus) {
            self.code = code
            self.name = name
            self.visitMinutes = visitMinutes
            self.channel = channel
            self.externalRef = externalRef
            self.attempts = attempts
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .withdrawn:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: RollingSpecimenProposalStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .rejected, .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                return next == RollingSpecimenProposalStatus.rejected || next == RollingSpecimenProposalStatus.withdrawn
            case .rejected:
                return next == RollingSpecimenProposalStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: RollingSpecimenProposalStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("rolling specimen proposal \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func netValue() -> Double {
            return ((Double(visitMinutes) + Double(attempts)) * 100).rounded() / 100
        }

        func copyValue() -> RollingSpecimenProposal {
            return RollingSpecimenProposal(
                code: code,
                name: name,
                visitMinutes: visitMinutes,
                channel: channel,
                externalRef: externalRef,
                attempts: attempts,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a rolling specimen proposal in status proposed.
    static func newRollingSpecimenProposal(_ code: String, name: String) -> RollingSpecimenProposal {
        return RollingSpecimenProposal(
            code: code,
            name: name,
            visitMinutes: 0,
            channel: "",
            externalRef: "",
            attempts: 0,
            status: RollingSpecimenProposalStatus.proposed
        )
    }
}
