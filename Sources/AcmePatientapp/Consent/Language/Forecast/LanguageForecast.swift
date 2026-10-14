import AcmePlatform
import Foundation

extension Consent {
    /// Where a language forecast is in its life cycle.
    enum LanguageForecastStatus: String, CaseIterable {
        case requested
        case granted
        case revoked
        case expired
    }

    /// The record of a language forecast and its current status.
    final class LanguageForecast {
        var code: String
        var name: String
        var description: String
        var minimum: Double
        var expiresAt: Int
        var endsAt: Int
        var archived: Bool
        var status: LanguageForecastStatus

        init(code: String, name: String, description: String, minimum: Double, expiresAt: Int, endsAt: Int, archived: Bool, status: LanguageForecastStatus) {
            self.code = code
            self.name = name
            self.description = description
            self.minimum = minimum
            self.expiresAt = expiresAt
            self.endsAt = endsAt
            self.archived = archived
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

        func canMoveTo(_ next: LanguageForecastStatus) -> Bool {
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
                return next == LanguageForecastStatus.revoked || next == LanguageForecastStatus.expired
            case .revoked:
                return next == LanguageForecastStatus.expired
            default:
                break
            }
            return false
        }

        func moveTo(_ next: LanguageForecastStatus) throws {
            if !self.canMoveTo(next) {
                throw Kit.Failure("language forecast \(code) cannot move from \(status.rawValue) to \(next.rawValue)")
            }
            status = next
            expiresAt = Int(Date().timeIntervalSince1970)
        }

        func label() -> String {
            return "\(code) (\(name))"
        }

        func projectedExposure() -> Double {
            return (minimum * Double(endsAt) * 100).rounded() / 100
        }

        func copyValue() -> LanguageForecast {
            return LanguageForecast(
                code: code,
                name: name,
                description: description,
                minimum: minimum,
                expiresAt: expiresAt,
                endsAt: endsAt,
                archived: archived,
                status: status
            )
        }

        func groupKey() -> String {
            return Kit.Text.normalize(name)
        }
    }

    /// Starts a language forecast in status requested.
    static func newLanguageForecast(_ code: String, name: String) -> LanguageForecast {
        return LanguageForecast(
            code: code,
            name: name,
            description: "",
            minimum: 0.0,
            expiresAt: 0,
            endsAt: 0,
            archived: false,
            status: LanguageForecastStatus.requested
        )
    }
}
