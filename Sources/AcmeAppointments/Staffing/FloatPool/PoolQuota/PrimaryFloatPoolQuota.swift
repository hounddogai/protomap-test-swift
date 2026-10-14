import AcmePlatform
import Foundation

extension Staffing {
    /// Where a primary float pool quota is in its life cycle.
    enum PrimaryFloatPoolQuotaStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// One primary float pool quota, with what the planners need to act on it.
    final class PrimaryFloatPoolQuota {
        var code: String
        var title: String
        var endsAt: Int
        var minimum: Double
        var discount: Double
        var country: String
        var status: PrimaryFloatPoolQuotaStatus

        init(code: String, title: String, endsAt: Int, minimum: Double, discount: Double, country: String, status: PrimaryFloatPoolQuotaStatus) {
            self.code = code
            self.title = title
            self.endsAt = endsAt
            self.minimum = minimum
            self.discount = discount
            self.country = country
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

        func canMoveTo(_ next: PrimaryFloatPoolQuotaStatus) -> Bool {
            switch status {
            case .requested:
                return next == PrimaryFloatPoolQuotaStatus.granted || next == PrimaryFloatPoolQuotaStatus.expired
            case .granted:
                return next == PrimaryFloatPoolQuotaStatus.expired
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

        func moveTo(_ next: PrimaryFloatPoolQuotaStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("primary float pool quota \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            endsAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code): \(title)"
        }

        func projectedLoad() -> Double {
            return ((discount - minimum) * 100).rounded() / 100
        }

        func copyValue() -> PrimaryFloatPoolQuota {
            return PrimaryFloatPoolQuota(
                code: code,
                title: title,
                endsAt: endsAt,
                minimum: minimum,
                discount: discount,
                country: country,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a primary float pool quota in status requested.
    static func newPrimaryFloatPoolQuota(_ code: String, title: String) -> PrimaryFloatPoolQuota {
        return PrimaryFloatPoolQuota(
            code: code,
            title: title,
            endsAt: 0,
            minimum: 0.0,
            discount: 0.0,
            country: "",
            status: PrimaryFloatPoolQuotaStatus.requested
        )
    }
}
