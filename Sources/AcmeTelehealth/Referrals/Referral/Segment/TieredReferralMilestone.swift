import AcmePlatform
import Foundation

extension Referrals {
    /// Where a tiered referral milestone is in its life cycle.
    enum TieredReferralMilestoneStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A tiered referral milestone as the referral team keeps it.
    final class TieredReferralMilestone {
        var code: String
        var title: String
        var externalRef: String
        var tags: [String]
        var maximum: Double
        var ratio: Double
        var acuity: Int
        var score: Double
        var status: TieredReferralMilestoneStatus

        init(code: String, title: String, externalRef: String, tags: [String], maximum: Double, ratio: Double, acuity: Int, score: Double, status: TieredReferralMilestoneStatus) {
            self.code = code
            self.title = title
            self.externalRef = externalRef
            self.tags = tags
            self.maximum = maximum
            self.ratio = ratio
            self.acuity = acuity
            self.score = score
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

        func canMoveTo(_ next: TieredReferralMilestoneStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .granted, .expired:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                return next == TieredReferralMilestoneStatus.revoked
            case .revoked:
                return next == TieredReferralMilestoneStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: TieredReferralMilestoneStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("tiered referral milestone \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\("tiered referral milestone") \(code)"
        }

        func hasTag(_ tag: String) -> Bool {
            for candidate in tags {
                if Kit.Text.normalize(candidate) == Kit.Text.normalize(tag) {
                    return true
                }
            }
            return false
        }

        func weightedVolume() -> Double {
            return (score * maximum * 100).rounded() / 100
        }

        func copyValue() -> TieredReferralMilestone {
            return TieredReferralMilestone(
                code: code,
                title: title,
                externalRef: externalRef,
                tags: tags,
                maximum: maximum,
                ratio: ratio,
                acuity: acuity,
                score: score,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a tiered referral milestone in status requested.
    static func newTieredReferralMilestone(_ code: String, title: String) -> TieredReferralMilestone {
        return TieredReferralMilestone(
            code: code,
            title: title,
            externalRef: "",
            tags: [],
            maximum: 0.0,
            ratio: 0.0,
            acuity: 0,
            score: 0.0,
            status: TieredReferralMilestoneStatus.requested
        )
    }
}
