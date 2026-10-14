import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a authorization group is in its life cycle.
    enum AuthorizationGroupStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A authorization group. Its code is unique within a tenant.
    final class AuthorizationGroup {
        var code: String
        var label: String
        var visitMinutes: Int
        var budget: Double
        var version: Int
        var source: String
        var status: AuthorizationGroupStatus

        init(code: String, label: String, visitMinutes: Int, budget: Double, version: Int, source: String, status: AuthorizationGroupStatus) {
            self.code = code
            self.label = label
            self.visitMinutes = visitMinutes
            self.budget = budget
            self.version = version
            self.source = source
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

        func canMoveTo(_ next: AuthorizationGroupStatus) -> Bool {
            switch status {
            case .created:
                return next == AuthorizationGroupStatus.published || next == AuthorizationGroupStatus.retired
            case .validated:
                return next == AuthorizationGroupStatus.published
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

        func moveTo(_ next: AuthorizationGroupStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("authorization group \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            version += 1
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func projectedExposure() -> Double {
            return (Double(version) * Double(visitMinutes) * 100).rounded() / 100
        }

        func copyValue() -> AuthorizationGroup {
            return AuthorizationGroup(
                code: code,
                label: label,
                visitMinutes: visitMinutes,
                budget: budget,
                version: version,
                source: source,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(source)
        }
    }

    /// Starts a authorization group in status created.
    static func newAuthorizationGroup(_ code: String, label: String) -> AuthorizationGroup {
        return AuthorizationGroup(
            code: code,
            label: label,
            visitMinutes: 0,
            budget: 0.0,
            version: 0,
            source: "",
            status: AuthorizationGroupStatus.created
        )
    }
}
