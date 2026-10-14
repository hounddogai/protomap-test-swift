import AcmePlatform
import Foundation

extension Referrals {
    /// Where a legacy referral claim is in its life cycle.
    enum LegacyReferralClaimStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// One legacy referral claim, with what the planners need to act on it.
    final class LegacyReferralClaim {
        var code: String
        var name: String
        var quantity: Int
        var tags: [String]
        var updatedAt: Int
        var unit: String
        var refills: Int
        var bed: String
        var status: LegacyReferralClaimStatus

        init(code: String, name: String, quantity: Int, tags: [String], updatedAt: Int, unit: String, refills: Int, bed: String, status: LegacyReferralClaimStatus) {
            self.code = code
            self.name = name
            self.quantity = quantity
            self.tags = tags
            self.updatedAt = updatedAt
            self.unit = unit
            self.refills = refills
            self.bed = bed
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .archived:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: LegacyReferralClaimStatus) -> Bool {
            switch status {
            case .`open`:
                return next == LegacyReferralClaimStatus.reopened
            case .inReview:
                switch next {
                case .reopened, .archived:
                    return true
                default:
                    break
                }
                return false
            case .resolved:
                return next == LegacyReferralClaimStatus.reopened || next == LegacyReferralClaimStatus.archived
            case .reopened:
                switch next {
                case .archived:
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

        func moveTo(_ next: LegacyReferralClaimStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("legacy referral claim \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("legacy referral claim") \(code)"
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
            return (Double(refills) * Double(quantity) * 100).rounded() / 100
        }

        func copyValue() -> LegacyReferralClaim {
            return LegacyReferralClaim(
                code: code,
                name: name,
                quantity: quantity,
                tags: tags,
                updatedAt: updatedAt,
                unit: unit,
                refills: refills,
                bed: bed,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a legacy referral claim in status open.
    static func newLegacyReferralClaim(_ code: String, name: String) -> LegacyReferralClaim {
        return LegacyReferralClaim(
            code: code,
            name: name,
            quantity: 0,
            tags: [],
            updatedAt: 0,
            unit: "",
            refills: 0,
            bed: "",
            status: LegacyReferralClaimStatus.`open`
        )
    }
}
