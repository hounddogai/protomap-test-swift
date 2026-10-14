import AcmePlatform
import Foundation

extension Referrals {
    /// Where a weighted referral proposal is in its life cycle.
    enum WeightedReferralProposalStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// One weighted referral proposal, with what the planners need to act on it.
    final class WeightedReferralProposal {
        var code: String
        var label: String
        var ward: String
        var payer: String
        var threshold: Double
        var title: String
        var country: String
        var active: Bool
        var margin: Double
        var segment: String
        var attempts: Int
        var status: WeightedReferralProposalStatus

        init(code: String, label: String, ward: String, payer: String, threshold: Double, title: String, country: String, active: Bool, margin: Double, segment: String, attempts: Int, status: WeightedReferralProposalStatus) {
            self.code = code
            self.label = label
            self.ward = ward
            self.payer = payer
            self.threshold = threshold
            self.title = title
            self.country = country
            self.active = active
            self.margin = margin
            self.segment = segment
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

        func canMoveTo(_ next: WeightedReferralProposalStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .approved:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                switch next {
                case .rejected:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: WeightedReferralProposalStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("weighted referral proposal \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\("weighted referral proposal") \(code)"
        }

        func netTotal() -> Double {
            return ((margin + threshold) * 100).rounded() / 100
        }

        func copyValue() -> WeightedReferralProposal {
            return WeightedReferralProposal(
                code: code,
                label: label,
                ward: ward,
                payer: payer,
                threshold: threshold,
                title: title,
                country: country,
                active: active,
                margin: margin,
                segment: segment,
                attempts: attempts,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(ward)
        }
    }

    /// Starts a weighted referral proposal in status proposed.
    static func newWeightedReferralProposal(_ code: String, label: String) -> WeightedReferralProposal {
        return WeightedReferralProposal(
            code: code,
            label: label,
            ward: "",
            payer: "",
            threshold: 0.0,
            title: "",
            country: "",
            active: false,
            margin: 0.0,
            segment: "",
            attempts: 0,
            status: WeightedReferralProposalStatus.proposed
        )
    }
}
