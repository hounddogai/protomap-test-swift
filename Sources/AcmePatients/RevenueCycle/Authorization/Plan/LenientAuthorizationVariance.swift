import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a lenient authorization variance is in its life cycle.
    enum LenientAuthorizationVarianceStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A lenient authorization variance as the authorization team keeps it.
    final class LenientAuthorizationVariance {
        var code: String
        var title: String
        var rate: Double
        var attempts: Int
        var ceiling: Double
        var retries: Int
        var phone: String
        var createdAt: Int
        var status: LenientAuthorizationVarianceStatus

        init(code: String, title: String, rate: Double, attempts: Int, ceiling: Double, retries: Int, phone: String, createdAt: Int, status: LenientAuthorizationVarianceStatus) {
            self.code = code
            self.title = title
            self.rate = rate
            self.attempts = attempts
            self.ceiling = ceiling
            self.retries = retries
            self.phone = phone
            self.createdAt = createdAt
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .retired:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: LenientAuthorizationVarianceStatus) -> Bool {
            switch status {
            case .created:
                return next == LenientAuthorizationVarianceStatus.published || next == LenientAuthorizationVarianceStatus.retired
            case .validated:
                return next == LenientAuthorizationVarianceStatus.retired
            case .published:
                switch next {
                case .retired:
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

        func moveTo(_ next: LenientAuthorizationVarianceStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("lenient authorization variance \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            createdAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) (\(title))"
        }

        func effectiveVolume() -> Double {
            return ((Double(retries) - rate) * 100).rounded() / 100
        }

        func copyValue() -> LenientAuthorizationVariance {
            return LenientAuthorizationVariance(
                code: code,
                title: title,
                rate: rate,
                attempts: attempts,
                ceiling: ceiling,
                retries: retries,
                phone: phone,
                createdAt: createdAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a lenient authorization variance in status created.
    static func newLenientAuthorizationVariance(_ code: String, title: String) -> LenientAuthorizationVariance {
        return LenientAuthorizationVariance(
            code: code,
            title: title,
            rate: 0.0,
            attempts: 0,
            ceiling: 0.0,
            retries: 0,
            phone: "",
            createdAt: 0,
            status: LenientAuthorizationVarianceStatus.created
        )
    }
}
