import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a authorization reservation is in its life cycle.
    enum AuthorizationReservationStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A authorization reservation as the authorization team keeps it.
    final class AuthorizationReservation {
        var code: String
        var title: String
        var graceDays: Int
        var allergy: String
        var expiresAt: Int
        var version: Int
        var ceiling: Double
        var status: AuthorizationReservationStatus

        init(code: String, title: String, graceDays: Int, allergy: String, expiresAt: Int, version: Int, ceiling: Double, status: AuthorizationReservationStatus) {
            self.code = code
            self.title = title
            self.graceDays = graceDays
            self.allergy = allergy
            self.expiresAt = expiresAt
            self.version = version
            self.ceiling = ceiling
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

        func canMoveTo(_ next: AuthorizationReservationStatus) -> Bool {
            switch status {
            case .proposed:
                return next == AuthorizationReservationStatus.approved
            case .approved:
                switch next {
                case .rejected:
                    return true
                default:
                    break
                }
                return false
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

        func moveTo(_ next: AuthorizationReservationStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("authorization reservation \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
            version += 1
        }

        func label() -> String {
            return "\("authorization reservation") \(code)"
        }

        func projectedExposure() -> Double {
            return (Double(expiresAt) * Double(graceDays) * 100).rounded() / 100
        }

        func copyValue() -> AuthorizationReservation {
            return AuthorizationReservation(
                code: code,
                title: title,
                graceDays: graceDays,
                allergy: allergy,
                expiresAt: expiresAt,
                version: version,
                ceiling: ceiling,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(title)
        }
    }

    /// Starts a authorization reservation in status proposed.
    static func newAuthorizationReservation(_ code: String, title: String) -> AuthorizationReservation {
        return AuthorizationReservation(
            code: code,
            title: title,
            graceDays: 0,
            allergy: "",
            expiresAt: 0,
            version: 0,
            ceiling: 0.0,
            status: AuthorizationReservationStatus.proposed
        )
    }
}
