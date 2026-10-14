import AcmePlatform
import Foundation

extension Staffing {
    /// Where a float pool proposal is in its life cycle.
    enum FloatPoolProposalStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// The record of a float pool proposal and its current status.
    final class FloatPoolProposal {
        var code: String
        var title: String
        var windowDays: Int
        var source: String
        var endsAt: Int
        var label: String
        var channel: String
        var timezone: String
        var graceDays: Int
        var attempts: Int
        var clinicianID: String
        var status: FloatPoolProposalStatus

        init(code: String, title: String, windowDays: Int, source: String, endsAt: Int, label: String, channel: String, timezone: String, graceDays: Int, attempts: Int, clinicianID: String, status: FloatPoolProposalStatus) {
            self.code = code
            self.title = title
            self.windowDays = windowDays
            self.source = source
            self.endsAt = endsAt
            self.label = label
            self.channel = channel
            self.timezone = timezone
            self.graceDays = graceDays
            self.attempts = attempts
            self.clinicianID = clinicianID
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

        func canMoveTo(_ next: FloatPoolProposalStatus) -> Bool {
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
                return next == FloatPoolProposalStatus.rejected || next == FloatPoolProposalStatus.withdrawn
            case .rejected:
                switch next {
                case .withdrawn:
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

        func moveTo(_ next: FloatPoolProposalStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("float pool proposal \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) [\(title)]"
        }

        func weightedExposure() -> Double {
            return (Double(endsAt) * Double(graceDays) * 100).rounded() / 100
        }

        func copyValue() -> FloatPoolProposal {
            return FloatPoolProposal(
                code: code,
                title: title,
                windowDays: windowDays,
                source: source,
                endsAt: endsAt,
                label: label,
                channel: channel,
                timezone: timezone,
                graceDays: graceDays,
                attempts: attempts,
                clinicianID: clinicianID,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a float pool proposal in status proposed.
    static func newFloatPoolProposal(_ code: String, title: String) -> FloatPoolProposal {
        return FloatPoolProposal(
            code: code,
            title: title,
            windowDays: 0,
            source: "",
            endsAt: 0,
            label: "",
            channel: "",
            timezone: "",
            graceDays: 0,
            attempts: 0,
            clinicianID: "",
            status: FloatPoolProposalStatus.proposed
        )
    }
}
