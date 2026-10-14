import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a authorization forecast.
    final class AuthorizationForecastView {
        var codeText: String
        var name: String
        var patientRef: String
        var attemptsText: String
        var timezoneText: String
        var descriptionText: String
        var locale: String
        var sourceText: String
        var updatedAt: String
        var procedureCode: String
        var contactEmail: String
        var statusLabel: String

        init(codeText: String, name: String, patientRef: String, attemptsText: String, timezoneText: String, descriptionText: String, locale: String, sourceText: String, updatedAt: String, procedureCode: String, contactEmail: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.patientRef = patientRef
            self.attemptsText = attemptsText
            self.timezoneText = timezoneText
            self.descriptionText = descriptionText
            self.locale = locale
            self.sourceText = sourceText
            self.updatedAt = updatedAt
            self.procedureCode = procedureCode
            self.contactEmail = contactEmail
            self.statusLabel = statusLabel
        }
    }

    static func toAuthorizationForecastView(_ item: AuthorizationForecast) -> AuthorizationForecastView {
        return AuthorizationForecastView(
            codeText: item.code,
            name: item.name,
            patientRef: Kit.Text.truncate(item.patientRef, limit: 40),
            attemptsText: String(item.attempts),
            timezoneText: Kit.Text.truncate(item.timezone, limit: 120),
            descriptionText: item.description,
            locale: item.locale,
            sourceText: item.source,
            updatedAt: String(item.updatedAt),
            procedureCode: item.procedureCode,
            contactEmail: item.contactEmail,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAuthorizationForecastViews(_ items: [AuthorizationForecast]) -> [AuthorizationForecastView] {
        var views: [AuthorizationForecastView] = []
        for item in items {
            views.append(toAuthorizationForecastView(item))
        }
        return views
    }

    static func sumAuthorizationForecastView(_ view: AuthorizationForecastView) throws -> Double {
        guard let parsedAttempts = Int(view.attemptsText) else {
            throw Kit.Failure("parse attempts: not a number")
        }
        guard let parsedUpdatedAt = Int(view.updatedAt) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        return Double(parsedAttempts) + Double(parsedUpdatedAt)
    }
}
