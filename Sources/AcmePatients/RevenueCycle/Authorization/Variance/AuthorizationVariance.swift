import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a authorization variance is in its life cycle.
    enum AuthorizationVarianceStatus: String, CaseIterable {
        case draft
        case pending
        case active
        case suspended
        case closed
    }

    /// A authorization variance. Its code is unique within a tenant.
    final class AuthorizationVariance {
        var code: String
        var title: String
        var externalRef: String
        var margin: Double
        var active: Bool
        var expiresAt: Int
        var status: AuthorizationVarianceStatus

        init(code: String, title: String, externalRef: String, margin: Double, active: Bool, expiresAt: Int, status: AuthorizationVarianceStatus) {
            self.code = code
            self.title = title
            self.externalRef = externalRef
            self.margin = margin
            self.active = active
            self.expiresAt = expiresAt
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .closed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: AuthorizationVarianceStatus) -> Bool {
            switch status {
            case .draft:
                return next == AuthorizationVarianceStatus.suspended
            case .pending:
                switch next {
                case .suspended:
                    return true
                default:
                    break
                }
                return false
            case .active:
                return next == AuthorizationVarianceStatus.closed
            case .suspended:
                return next == AuthorizationVarianceStatus.closed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: AuthorizationVarianceStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("authorization variance \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) [\(title)]"
        }

        func weightedTotal() -> Double {
            return ((margin - Double(expiresAt)) * 100).rounded() / 100
        }

        func copyValue() -> AuthorizationVariance {
            return AuthorizationVariance(
                code: code,
                title: title,
                externalRef: externalRef,
                margin: margin,
                active: active,
                expiresAt: expiresAt,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a authorization variance in status draft.
    static func newAuthorizationVariance(_ code: String, title: String) -> AuthorizationVariance {
        return AuthorizationVariance(
            code: code,
            title: title,
            externalRef: "",
            margin: 0.0,
            active: false,
            expiresAt: 0,
            status: AuthorizationVarianceStatus.draft
        )
    }
}
