import AcmePlatform
import Foundation

extension Referrals {
    /// Where a referral bundle is in its life cycle.
    enum ReferralBundleStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// The record of a referral bundle and its current status.
    final class ReferralBundle {
        var code: String
        var title: String
        var weight: Double
        var region: String
        var revision: Int
        var updatedAt: Int
        var margin: Double
        var status: ReferralBundleStatus

        init(code: String, title: String, weight: Double, region: String, revision: Int, updatedAt: Int, margin: Double, status: ReferralBundleStatus) {
            self.code = code
            self.title = title
            self.weight = weight
            self.region = region
            self.revision = revision
            self.updatedAt = updatedAt
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

        func canMoveTo(_ next: ReferralBundleStatus) -> Bool {
            switch status {
            case .proposed:
                switch next {
                case .rejected:
                    return true
                default:
                    break
                }
                return false
            case .approved:
                switch next {
                case .withdrawn:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                return next == ReferralBundleStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ReferralBundleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("referral bundle \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
            revision += 1
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func projectedVolume() -> Double {
            return (Double(updatedAt) * weight * 100).rounded() / 100
        }

        func copyValue() -> ReferralBundle {
            return ReferralBundle(
                code: code,
                title: title,
                weight: weight,
                region: region,
                revision: revision,
                updatedAt: updatedAt,
                margin: margin,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(region)
        }
    }

    /// Starts a referral bundle in status proposed.
    static func newReferralBundle(_ code: String, title: String) -> ReferralBundle {
        return ReferralBundle(
            code: code,
            title: title,
            weight: 0.0,
            region: "",
            revision: 0,
            updatedAt: 0,
            margin: 0.0,
            status: ReferralBundleStatus.proposed
        )
    }
}
