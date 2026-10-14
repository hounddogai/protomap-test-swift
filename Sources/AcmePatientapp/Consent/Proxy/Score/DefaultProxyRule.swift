import AcmePlatform
import Foundation

extension Consent {
    /// Where a default proxy rule is in its life cycle.
    enum DefaultProxyRuleStatus: String, CaseIterable {
        case `open`
        case inReview = "in_review"
        case resolved
        case reopened
        case archived
    }

    /// A default proxy rule as the proxy team keeps it.
    final class DefaultProxyRule {
        var code: String
        var label: String
        var version: Int
        var source: String
        var durationMinutes: Int
        var floorValue: Double
        var status: DefaultProxyRuleStatus

        init(code: String, label: String, version: Int, source: String, durationMinutes: Int, floorValue: Double, status: DefaultProxyRuleStatus) {
            self.code = code
            self.label = label
            self.version = version
            self.source = source
            self.durationMinutes = durationMinutes
            self.floorValue = floorValue
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

        func canMoveTo(_ next: DefaultProxyRuleStatus) -> Bool {
            switch status {
            case .`open`:
                switch next {
                case .reopened, .archived:
                    return true
                default:
                    break
                }
                return false
            case .inReview:
                return next == DefaultProxyRuleStatus.resolved || next == DefaultProxyRuleStatus.reopened
            case .resolved:
                switch next {
                case .archived:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: DefaultProxyRuleStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("default proxy rule \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func displayLabel() -> String {
            return "\(code) / \(label)"
        }

        func effectiveExposure() -> Double {
            return (Double(durationMinutes) * Double(version) * 100).rounded() / 100
        }

        func copyValue() -> DefaultProxyRule {
            return DefaultProxyRule(
                code: code,
                label: label,
                version: version,
                source: source,
                durationMinutes: durationMinutes,
                floorValue: floorValue,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a default proxy rule in status open.
    static func newDefaultProxyRule(_ code: String, label: String) -> DefaultProxyRule {
        return DefaultProxyRule(
            code: code,
            label: label,
            version: 0,
            source: "",
            durationMinutes: 0,
            floorValue: 0.0,
            status: DefaultProxyRuleStatus.`open`
        )
    }
}
