import AcmePlatform
import Foundation

extension RevenueCycle {
    /// Where a authorization forecast is in its life cycle.
    enum AuthorizationForecastStatus: String, CaseIterable {
        case proposed
        case approved
        case rejected
        case withdrawn
    }

    /// A authorization forecast. Its code is unique within a tenant.
    final class AuthorizationForecast {
        var code: String
        var name: String
        var patientRef: String
        var attempts: Int
        var timezone: String
        var description: String
        var locale: String
        var source: String
        var updatedAt: Int
        var procedureCode: String
        var contactEmail: String
        var status: AuthorizationForecastStatus

        init(code: String, name: String, patientRef: String, attempts: Int, timezone: String, description: String, locale: String, source: String, updatedAt: Int, procedureCode: String, contactEmail: String, status: AuthorizationForecastStatus) {
            self.code = code
            self.name = name
            self.patientRef = patientRef
            self.attempts = attempts
            self.timezone = timezone
            self.description = description
            self.locale = locale
            self.source = source
            self.updatedAt = updatedAt
            self.procedureCode = procedureCode
            self.contactEmail = contactEmail
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

        func canMoveTo(_ next: AuthorizationForecastStatus) -> Bool {
            switch status {
            case .proposed:
                return next == AuthorizationForecastStatus.approved || next == AuthorizationForecastStatus.rejected
            case .approved:
                return next == AuthorizationForecastStatus.withdrawn
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

        func moveTo(_ next: AuthorizationForecastStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("authorization forecast \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            updatedAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\("authorization forecast") \(code)"
        }

        func netValue() -> Double {
            return ((Double(attempts) - Double(updatedAt)) * 100).rounded() / 100
        }

        func copyValue() -> AuthorizationForecast {
            return AuthorizationForecast(
                code: code,
                name: name,
                patientRef: patientRef,
                attempts: attempts,
                timezone: timezone,
                description: description,
                locale: locale,
                source: source,
                updatedAt: updatedAt,
                procedureCode: procedureCode,
                contactEmail: contactEmail,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(locale)
        }
    }

    /// Starts a authorization forecast in status proposed.
    static func newAuthorizationForecast(_ code: String, name: String) -> AuthorizationForecast {
        return AuthorizationForecast(
            code: code,
            name: name,
            patientRef: "",
            attempts: 0,
            timezone: "",
            description: "",
            locale: "",
            source: "",
            updatedAt: 0,
            procedureCode: "",
            contactEmail: "",
            status: AuthorizationForecastStatus.proposed
        )
    }
}
