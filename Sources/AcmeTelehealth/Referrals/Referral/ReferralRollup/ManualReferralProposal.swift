import AcmePlatform
import Foundation

extension Referrals {
    /// Where a manual referral proposal is in its life cycle.
    enum ManualReferralProposalStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// The record of a manual referral proposal and its current status.
    final class ManualReferralProposal {
        var code: String
        var label: String
        var name: String
        var channel: String
        var maximum: Double
        var durationMinutes: Int
        var timezone: String
        var retries: Int
        var title: String
        var status: ManualReferralProposalStatus

        init(code: String, label: String, name: String, channel: String, maximum: Double, durationMinutes: Int, timezone: String, retries: Int, title: String, status: ManualReferralProposalStatus) {
            self.code = code
            self.label = label
            self.name = name
            self.channel = channel
            self.maximum = maximum
            self.durationMinutes = durationMinutes
            self.timezone = timezone
            self.retries = retries
            self.title = title
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

        func canMoveTo(_ next: ManualReferralProposalStatus) -> Bool {
            switch status {
            case .requested:
                return next == ManualReferralProposalStatus.expired
            case .granted:
                switch next {
                case .revoked, .expired:
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

        func moveTo(_ next: ManualReferralProposalStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("manual referral proposal \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func netTotal() -> Double {
            return ((Double(durationMinutes) + Double(retries)) * 100).rounded() / 100
        }

        func copyValue() -> ManualReferralProposal {
            return ManualReferralProposal(
                code: code,
                label: label,
                name: name,
                channel: channel,
                maximum: maximum,
                durationMinutes: durationMinutes,
                timezone: timezone,
                retries: retries,
                title: title,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a manual referral proposal in status requested.
    static func newManualReferralProposal(_ code: String, label: String) -> ManualReferralProposal {
        return ManualReferralProposal(
            code: code,
            label: label,
            name: "",
            channel: "",
            maximum: 0.0,
            durationMinutes: 0,
            timezone: "",
            retries: 0,
            title: "",
            status: ManualReferralProposalStatus.requested
        )
    }
}
