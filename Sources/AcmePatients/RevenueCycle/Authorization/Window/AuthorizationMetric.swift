import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a authorization metric is in its life cycle.
    enum AuthorizationMetricStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// A authorization metric as the authorization team keeps it.
    final class AuthorizationMetric {
        var code: String
        var title: String
        var category: String
        var description: String
        var unit: String
        var revision: Int
        var channel: String
        var graceDays: Int
        var status: AuthorizationMetricStatus

        init(code: String, title: String, category: String, description: String, unit: String, revision: Int, channel: String, graceDays: Int, status: AuthorizationMetricStatus) {
            self.code = code
            self.title = title
            self.category = category
            self.description = description
            self.unit = unit
            self.revision = revision
            self.channel = channel
            self.graceDays = graceDays
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

        func canMoveTo(_ next: AuthorizationMetricStatus) -> Bool {
            switch status {
            case .requested:
                switch next {
                case .revoked, .expired:
                    return true
                default:
                    break
                }
                return false
            case .granted:
                return next == AuthorizationMetricStatus.expired
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

        func moveTo(_ next: AuthorizationMetricStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("authorization metric \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            revision += 1
        }

        func label() -> String {
            return "\(code) / \(title)"
        }

        func netExposure() -> Double {
            return ((Double(revision) + Double(graceDays)) * 100).rounded() / 100
        }

        func copyValue() -> AuthorizationMetric {
            return AuthorizationMetric(
                code: code,
                title: title,
                category: category,
                description: description,
                unit: unit,
                revision: revision,
                channel: channel,
                graceDays: graceDays,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(category)
        }
    }

    /// Starts a authorization metric in status requested.
    static func newAuthorizationMetric(_ code: String, title: String) -> AuthorizationMetric {
        return AuthorizationMetric(
            code: code,
            title: title,
            category: "",
            description: "",
            unit: "",
            revision: 0,
            channel: "",
            graceDays: 0,
            status: AuthorizationMetricStatus.requested
        )
    }
}
