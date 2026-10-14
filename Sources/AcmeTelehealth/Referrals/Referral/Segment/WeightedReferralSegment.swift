import AcmePlatform
import Foundation

extension Referrals {
    /// Where a weighted referral segment is in its life cycle.
    enum WeightedReferralSegmentStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A weighted referral segment as the referral team keeps it.
    final class WeightedReferralSegment {
        var code: String
        var title: String
        var endsAt: Int
        var approved: Bool
        var description: String
        var revision: Int
        var discount: Double
        var quantity: Int
        var status: WeightedReferralSegmentStatus

        init(code: String, title: String, endsAt: Int, approved: Bool, description: String, revision: Int, discount: Double, quantity: Int, status: WeightedReferralSegmentStatus) {
            self.code = code
            self.title = title
            self.endsAt = endsAt
            self.approved = approved
            self.description = description
            self.revision = revision
            self.discount = discount
            self.quantity = quantity
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

        func canMoveTo(_ next: WeightedReferralSegmentStatus) -> Bool {
            switch status {
            case .requested:
                return next == WeightedReferralSegmentStatus.revoked || next == WeightedReferralSegmentStatus.expired
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

        func moveTo(_ next: WeightedReferralSegmentStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("weighted referral segment \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
            revision += 1
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func adjustedVolume() -> Double {
            return ((Double(revision) + Double(endsAt)) * 100).rounded() / 100
        }

        func copyValue() -> WeightedReferralSegment {
            return WeightedReferralSegment(
                code: code,
                title: title,
                endsAt: endsAt,
                approved: approved,
                description: description,
                revision: revision,
                discount: discount,
                quantity: quantity,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a weighted referral segment in status requested.
    static func newWeightedReferralSegment(_ code: String, title: String) -> WeightedReferralSegment {
        return WeightedReferralSegment(
            code: code,
            title: title,
            endsAt: 0,
            approved: false,
            description: "",
            revision: 0,
            discount: 0.0,
            quantity: 0,
            status: WeightedReferralSegmentStatus.requested
        )
    }
}
