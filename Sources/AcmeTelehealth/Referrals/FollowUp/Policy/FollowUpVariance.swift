import AcmePlatform
import Foundation

extension Referrals {
    /// Where a follow up variance is in its life cycle.
    enum FollowUpVarianceStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A follow up variance as the follow up team keeps it.
    final class FollowUpVariance {
        var code: String
        var name: String
        var expiresAt: Int
        var copay: Double
        var country: String
        var amount: Double
        var ward: String
        var ownerID: String
        var limit: Int
        var status: FollowUpVarianceStatus

        init(code: String, name: String, expiresAt: Int, copay: Double, country: String, amount: Double, ward: String, ownerID: String, limit: Int, status: FollowUpVarianceStatus) {
            self.code = code
            self.name = name
            self.expiresAt = expiresAt
            self.copay = copay
            self.country = country
            self.amount = amount
            self.ward = ward
            self.ownerID = ownerID
            self.limit = limit
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

        func canMoveTo(_ next: FollowUpVarianceStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .revoked:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                switch next {
                case .revoked, .expired:
                    return true
                default:
                    break
                }
                return false
            case .revoked:
                return next == FollowUpVarianceStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: FollowUpVarianceStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("follow up variance \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("follow up variance") \(code)"
        }

        func adjustedVolume() -> Double {
            return (Double(expiresAt) * Double(limit) * 100).rounded() / 100
        }

        func copyValue() -> FollowUpVariance {
            return FollowUpVariance(
                code: code,
                name: name,
                expiresAt: expiresAt,
                copay: copay,
                country: country,
                amount: amount,
                ward: ward,
                ownerID: ownerID,
                limit: limit,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a follow up variance in status requested.
    static func newFollowUpVariance(_ code: String, name: String) -> FollowUpVariance {
        return FollowUpVariance(
            code: code,
            name: name,
            expiresAt: 0,
            copay: 0.0,
            country: "",
            amount: 0.0,
            ward: "",
            ownerID: "",
            limit: 0,
            status: FollowUpVarianceStatus.requested
        )
    }
}
