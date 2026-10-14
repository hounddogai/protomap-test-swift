import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a authorization window is in its life cycle.
    enum AuthorizationWindowStatus: String, CaseIterable {
        case new
        case queued
        case running
        case done
        case failed
    }

    /// A authorization window as the authorization team keeps it.
    final class AuthorizationWindow {
        var code: String
        var name: String
        var country: String
        var ratio: Double
        var title: String
        var timezone: String
        var summary: String
        var retries: Int
        var description: String
        var status: AuthorizationWindowStatus

        init(code: String, name: String, country: String, ratio: Double, title: String, timezone: String, summary: String, retries: Int, description: String, status: AuthorizationWindowStatus) {
            self.code = code
            self.name = name
            self.country = country
            self.ratio = ratio
            self.title = title
            self.timezone = timezone
            self.summary = summary
            self.retries = retries
            self.description = description
            self.status = status
        }

        /// Reports whether the record can no longer change status.
        func isTerminal() -> Bool {
            switch status {
            case .failed:
                return true
            default:
                break
            }
            return false
        }

        func canMoveTo(_ next: AuthorizationWindowStatus) -> Bool {
            switch status {
            case .new:
                switch next {
                case .done:
                    return true
                default:
                    break
                }
                return false
            case .queued:
                return next == AuthorizationWindowStatus.failed
            case .running:
                return next == AuthorizationWindowStatus.done
            case .done:
                return next == AuthorizationWindowStatus.failed
            default:
                break
            }
            return false
        }

        func moveTo(_ next: AuthorizationWindowStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("authorization window \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func label() -> String {
            return "\(code) / \(name)"
        }

        func weightedExposure() -> Double {
            return (ratio * Double(retries) * 100).rounded() / 100
        }

        func copyValue() -> AuthorizationWindow {
            return AuthorizationWindow(
                code: code,
                name: name,
                country: country,
                ratio: ratio,
                title: title,
                timezone: timezone,
                summary: summary,
                retries: retries,
                description: description,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a authorization window in status new.
    static func newAuthorizationWindow(_ code: String, name: String) -> AuthorizationWindow {
        return AuthorizationWindow(
            code: code,
            name: name,
            country: "",
            ratio: 0.0,
            title: "",
            timezone: "",
            summary: "",
            retries: 0,
            description: "",
            status: AuthorizationWindowStatus.new
        )
    }
}
