import AcmePlatform
import Foundation

extension Consent {
    /// Where a proxy override is in its life cycle.
    enum ProxyOverrideStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A proxy override as the proxy team keeps it.
    final class ProxyOverride {
        var code: String
        var name: String
        var approved: Bool
        var expiresAt: Int
        var channel: String
        var status: ProxyOverrideStatus

        init(code: String, name: String, approved: Bool, expiresAt: Int, channel: String, status: ProxyOverrideStatus) {
            self.code = code
            self.name = name
            self.approved = approved
            self.expiresAt = expiresAt
            self.channel = channel
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

        func canMoveTo(_ next: ProxyOverrideStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .inReview, .reopened:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                return next == ProxyOverrideStatus.resolved
            case .resolved:
                switch next {
                case .reopened, .archived:
                    return true
                default:
                    break
                }
                return false
            case .reopened:
                return next == ProxyOverrideStatus.archived
            default:
                break
            }
            return false
        }

        func moveTo(_ next: ProxyOverrideStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("proxy override \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("proxy override") \(code)"
        }

        func measuredValue() -> Double {
            return Double(expiresAt)
        }

        func copyValue() -> ProxyOverride {
            return ProxyOverride(
                code: code,
                name: name,
                approved: approved,
                expiresAt: expiresAt,
                channel: channel,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(channel)
        }
    }

    /// Starts a proxy override in status open.
    static func newProxyOverride(_ code: String, name: String) -> ProxyOverride {
        return ProxyOverride(
            code: code,
            name: name,
            approved: false,
            expiresAt: 0,
            channel: "",
            status: ProxyOverrideStatus.`open`
        )
    }
}
