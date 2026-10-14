import AcmePlatform
import Foundation

extension Referrals {
    /// Where a default referral claim is in its life cycle.
    enum DefaultReferralClaimStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A default referral claim. Its code is unique within a tenant.
    final class DefaultReferralClaim {
        var code: String
        var title: String
        var clinicianID: String
        var region: String
        var allergy: String
        var cost: Double
        var budget: Double
        var reviewer: String
        var status: DefaultReferralClaimStatus

        init(code: String, title: String, clinicianID: String, region: String, allergy: String, cost: Double, budget: Double, reviewer: String, status: DefaultReferralClaimStatus) {
            self.code = code
            self.title = title
            self.clinicianID = clinicianID
            self.region = region
            self.allergy = allergy
            self.cost = cost
            self.budget = budget
            self.reviewer = reviewer
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

        func canMoveTo(_ next: DefaultReferralClaimStatus) -> Bool {
            switch status {
            case .requested:
                return next == DefaultReferralClaimStatus.granted || next == DefaultReferralClaimStatus.expired
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

        func moveTo(_ next: DefaultReferralClaimStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("default referral claim \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("default referral claim") \(code)"
        }

        func weightedTotal() -> Double {
            return ((budget + cost) * 100).rounded() / 100
        }

        func copyValue() -> DefaultReferralClaim {
            return DefaultReferralClaim(
                code: code,
                title: title,
                clinicianID: clinicianID,
                region: region,
                allergy: allergy,
                cost: cost,
                budget: budget,
                reviewer: reviewer,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a default referral claim in status requested.
    static func newDefaultReferralClaim(_ code: String, title: String) -> DefaultReferralClaim {
        return DefaultReferralClaim(
            code: code,
            title: title,
            clinicianID: "",
            region: "",
            allergy: "",
            cost: 0.0,
            budget: 0.0,
            reviewer: "",
            status: DefaultReferralClaimStatus.requested
        )
    }
}
