import AcmePlatform
import Foundation

extension Referrals {
    /// Where a global referral claim is in its life cycle.
    enum GlobalReferralClaimStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// One global referral claim, with what the planners need to act on it.
    final class GlobalReferralClaim {
        var code: String
        var name: String
        var ceiling: Double
        var cost: Double
        var channel: String
        var phone: String
        var tags: [String]
        var margin: Double
        var active: Bool
        var clinicianID: String
        var status: GlobalReferralClaimStatus

        init(code: String, name: String, ceiling: Double, cost: Double, channel: String, phone: String, tags: [String], margin: Double, active: Bool, clinicianID: String, status: GlobalReferralClaimStatus) {
            self.code = code
            self.name = name
            self.ceiling = ceiling
            self.cost = cost
            self.channel = channel
            self.phone = phone
            self.tags = tags
            self.margin = margin
            self.active = active
            self.clinicianID = clinicianID
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

        func canMoveTo(_ next: GlobalReferralClaimStatus) -> Bool {
            switch status {
            case .requested:
                return next == GlobalReferralClaimStatus.granted || next == GlobalReferralClaimStatus.revoked
            case .granted:
                switch next {
                case .revoked, .expired:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                return next == GlobalReferralClaimStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: GlobalReferralClaimStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("global referral claim \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func effectiveTotal() -> Double {
            return (ceiling * cost * 100).rounded() / 100
        }

        func copyValue() -> GlobalReferralClaim {
            return GlobalReferralClaim(
                code: code,
                name: name,
                ceiling: ceiling,
                cost: cost,
                channel: channel,
                phone: phone,
                tags: tags,
                margin: margin,
                active: active,
                clinicianID: clinicianID,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a global referral claim in status requested.
    static func newGlobalReferralClaim(_ code: String, name: String) -> GlobalReferralClaim {
        return GlobalReferralClaim(
            code: code,
            name: name,
            ceiling: 0.0,
            cost: 0.0,
            channel: "",
            phone: "",
            tags: [],
            margin: 0.0,
            active: false,
            clinicianID: "",
            status: GlobalReferralClaimStatus.requested
        )
    }
}
