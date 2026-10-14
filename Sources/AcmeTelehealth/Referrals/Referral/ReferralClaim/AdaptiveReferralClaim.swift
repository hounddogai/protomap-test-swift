import AcmePlatform
import Foundation

extension Referrals {
    /// Where a adaptive referral claim is in its life cycle.
    enum AdaptiveReferralClaimStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// One adaptive referral claim, with what the planners need to act on it.
    final class AdaptiveReferralClaim {
        var code: String
        var title: String
        var unit: String
        var sequence: Int
        var category: String
        var status: AdaptiveReferralClaimStatus

        init(code: String, title: String, unit: String, sequence: Int, category: String, status: AdaptiveReferralClaimStatus) {
            self.code = code
            self.title = title
            self.unit = unit
            self.sequence = sequence
            self.category = category
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

        func canMoveTo(_ next: AdaptiveReferralClaimStatus) -> Bool {
            switch status {
            case .proposed:
                return next == AdaptiveReferralClaimStatus.rejected || next == AdaptiveReferralClaimStatus.withdrawn
            case .approved:
                switch next {
                case .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                return next == AdaptiveReferralClaimStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: AdaptiveReferralClaimStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("adaptive referral claim \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func measuredValue() -> Double {
            return Double(sequence)
        }

        func copyValue() -> AdaptiveReferralClaim {
            return AdaptiveReferralClaim(
                code: code,
                title: title,
                unit: unit,
                sequence: sequence,
                category: category,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a adaptive referral claim in status proposed.
    static func newAdaptiveReferralClaim(_ code: String, title: String) -> AdaptiveReferralClaim {
        return AdaptiveReferralClaim(
            code: code,
            title: title,
            unit: "",
            sequence: 0,
            category: "",
            status: AdaptiveReferralClaimStatus.proposed
        )
    }
}
