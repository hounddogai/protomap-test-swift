import AcmePlatform
import Foundation

extension Consent {
    /// Where a primary proxy policy is in its life cycle.
    enum PrimaryProxyPolicyStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A primary proxy policy. Its code is unique within a tenant.
    final class PrimaryProxyPolicy {
        var code: String
        var title: String
        var windowDays: Int
        var label: String
        var country: String
        var status: PrimaryProxyPolicyStatus

        init(code: String, title: String, windowDays: Int, label: String, country: String, status: PrimaryProxyPolicyStatus) {
            self.code = code
            self.title = title
            self.windowDays = windowDays
            self.label = label
            self.country = country
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

        func canMoveTo(_ next: PrimaryProxyPolicyStatus) -> Bool {
            switch status {
            case .proposed:
                return next == PrimaryProxyPolicyStatus.approved || next == PrimaryProxyPolicyStatus.rejected
            case .approved:
                switch next {
                case .rejected:
                    return true
                default:
                    break
                }
                return false
            case .rejected:
                return next == PrimaryProxyPolicyStatus.withdrawn
            default:
                break
            }
            return false
        }

        func moveTo(_ next: PrimaryProxyPolicyStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("primary proxy policy \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) / \(title)"
        }

        func measuredValue() -> Double {
            return Double(windowDays)
        }

        func copyValue() -> PrimaryProxyPolicy {
            return PrimaryProxyPolicy(
                code: code,
                title: title,
                windowDays: windowDays,
                label: label,
                country: country,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(country)
        }
    }

    /// Starts a primary proxy policy in status proposed.
    static func newPrimaryProxyPolicy(_ code: String, title: String) -> PrimaryProxyPolicy {
        return PrimaryProxyPolicy(
            code: code,
            title: title,
            windowDays: 0,
            label: "",
            country: "",
            status: PrimaryProxyPolicyStatus.proposed
        )
    }
}
