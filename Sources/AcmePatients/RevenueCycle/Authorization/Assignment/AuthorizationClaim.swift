import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a authorization claim is in its life cycle.
    enum AuthorizationClaimStatus: String, CaseIterable {
        case created
        case validated
        case published
        case retired
    }

    /// A authorization claim. Its code is unique within a tenant.
    final class AuthorizationClaim {
        var code: String
        var name: String
        var unit: String
        var copay: Double
        var label: String
        var updatedAt: Int
        var locale: String
        var status: AuthorizationClaimStatus

        init(code: String, name: String, unit: String, copay: Double, label: String, updatedAt: Int, locale: String, status: AuthorizationClaimStatus) {
            self.code = code
            self.name = name
            self.unit = unit
            self.copay = copay
            self.label = label
            self.updatedAt = updatedAt
            self.locale = locale
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

        func canMoveTo(_ next: AuthorizationClaimStatus) -> Bool {
            switch status {
            case .created:
                switch next {
                case .validated, .retired:
                    return true
                default:
                    break
                }
                return false
            case .validated:
                return next == AuthorizationClaimStatus.published || next == AuthorizationClaimStatus.retired
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

        func moveTo(_ next: AuthorizationClaimStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("authorization claim \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func displayLabel() -> String {
            return "\(code) [\(name)]"
        }

        func adjustedValue() -> Double {
            return ((Double(updatedAt) - copay) * 100).rounded() / 100
        }

        func copyValue() -> AuthorizationClaim {
            return AuthorizationClaim(
                code: code,
                name: name,
                unit: unit,
                copay: copay,
                label: label,
                updatedAt: updatedAt,
                locale: locale,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(unit)
        }
    }

    /// Starts a authorization claim in status created.
    static func newAuthorizationClaim(_ code: String, name: String) -> AuthorizationClaim {
        return AuthorizationClaim(
            code: code,
            name: name,
            unit: "",
            copay: 0.0,
            label: "",
            updatedAt: 0,
            locale: "",
            status: AuthorizationClaimStatus.created
        )
    }
}
