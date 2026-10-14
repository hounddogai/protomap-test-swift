import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a authorization preference is in its life cycle.
    enum AuthorizationPreferenceStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A authorization preference. Its code is unique within a tenant.
    final class AuthorizationPreference {
        var code: String
        var label: String
        var floorValue: Double
        var graceDays: Int
        var dosageMg: Double
        var status: AuthorizationPreferenceStatus

        init(code: String, label: String, floorValue: Double, graceDays: Int, dosageMg: Double, status: AuthorizationPreferenceStatus) {
            self.code = code
            self.label = label
            self.floorValue = floorValue
            self.graceDays = graceDays
            self.dosageMg = dosageMg
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

        func canMoveTo(_ next: AuthorizationPreferenceStatus) -> Bool {
            switch status {
            case .proposed:
                return next == AuthorizationPreferenceStatus.approved || next == AuthorizationPreferenceStatus.rejected
            case .approved:
                return next == AuthorizationPreferenceStatus.rejected || next == AuthorizationPreferenceStatus.withdrawn
            case .rejected:
                switch next {
                case .withdrawn:
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

        func moveTo(_ next: AuthorizationPreferenceStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("authorization preference \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
        }

        func displayLabel() -> String {
            return "\(code) [\(label)]"
        }

        func weightedTotal() -> Double {
            return (Double(graceDays) * floorValue * 100).rounded() / 100
        }

        func copyValue() -> AuthorizationPreference {
            return AuthorizationPreference(
                code: code,
                label: label,
                floorValue: floorValue,
                graceDays: graceDays,
                dosageMg: dosageMg,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(label)
        }
    }

    /// Starts a authorization preference in status proposed.
    static func newAuthorizationPreference(_ code: String, label: String) -> AuthorizationPreference {
        return AuthorizationPreference(
            code: code,
            label: label,
            floorValue: 0.0,
            graceDays: 0,
            dosageMg: 0.0,
            status: AuthorizationPreferenceStatus.proposed
        )
    }
}
