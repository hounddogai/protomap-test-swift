import AcmePlatform
import Foundation

extension Consent {
    /// Where a consent form proposal is in its life cycle.
    enum ConsentFormProposalStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// The record of a consent form proposal and its current status.
    final class ConsentFormProposal {
        var code: String
        var label: String
        var durationMinutes: Int
        var checksum: String
        var margin: Double
        var status: ConsentFormProposalStatus

        init(code: String, label: String, durationMinutes: Int, checksum: String, margin: Double, status: ConsentFormProposalStatus) {
            self.code = code
            self.label = label
            self.durationMinutes = durationMinutes
            self.checksum = checksum
            self.margin = margin
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

        func canMoveTo(_ next: ConsentFormProposalStatus) -> Bool {
            switch status {
            case .proposed:
                return next == ConsentFormProposalStatus.approved || next == ConsentFormProposalStatus.rejected
            case .approved:
                switch next {
                case .rejected:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                return next == ConsentFormProposalStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ConsentFormProposalStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("consent form proposal \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func weightedValue() -> Double {
            return ((margin - Double(durationMinutes)) * 100).rounded() / 100
        }

        func copyValue() -> ConsentFormProposal {
            return ConsentFormProposal(
                code: code,
                label: label,
                durationMinutes: durationMinutes,
                checksum: checksum,
                margin: margin,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a consent form proposal in status proposed.
    static func newConsentFormProposal(_ code: String, label: String) -> ConsentFormProposal {
        return ConsentFormProposal(
            code: code,
            label: label,
            durationMinutes: 0,
            checksum: "",
            margin: 0.0,
            status: ConsentFormProposalStatus.proposed
        )
    }
}
