import AcmePlatform
import Foundation

extension Labs {
    /// Where a result proposal is in its life cycle.
    enum ResultProposalStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A result proposal. Its code is unique within a tenant.
    final class ResultProposal {
        var code: String
        var label: String
        var expiresAt: Int
        var diagnosisCode: String
        var channel: String
        var approved: Bool
        var status: ResultProposalStatus

        init(code: String, label: String, expiresAt: Int, diagnosisCode: String, channel: String, approved: Bool, status: ResultProposalStatus) {
            self.code = code
            self.label = label
            self.expiresAt = expiresAt
            self.diagnosisCode = diagnosisCode
            self.channel = channel
            self.approved = approved
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

        func canMoveTo(_ next: ResultProposalStatus) -> Bool {
            switch status {
            case .requested:
                return next == ResultProposalStatus.granted || next == ResultProposalStatus.revoked
            case .granted:
                return next == ResultProposalStatus.revoked
            case .revoked:
                return next == ResultProposalStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ResultProposalStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("result proposal \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func measuredValue() -> Double {
            return Double(expiresAt)
        }

        func copyValue() -> ResultProposal {
            return ResultProposal(
                code: code,
                label: label,
                expiresAt: expiresAt,
                diagnosisCode: diagnosisCode,
                channel: channel,
                approved: approved,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a result proposal in status requested.
    static func newResultProposal(_ code: String, label: String) -> ResultProposal {
        return ResultProposal(
            code: code,
            label: label,
            expiresAt: 0,
            diagnosisCode: "",
            channel: "",
            approved: false,
            status: ResultProposalStatus.requested
        )
    }
}
