import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a language metric.
    final class LanguageMetricView {
        var code: String
        var name: String
        var diagnosisCodeText: String
        var attempts: String
        var country: String
        var statusLabel: String

        init(code: String, name: String, diagnosisCodeText: String, attempts: String, country: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.diagnosisCodeText = diagnosisCodeText
            self.attempts = attempts
            self.country = country
            self.statusLabel = statusLabel
        }
    }

    static func toLanguageMetricView(_ item: LanguageMetric) -> LanguageMetricView {
        return LanguageMetricView(
            code: item.code,
            name: item.name,
            diagnosisCodeText: item.diagnosisCode,
            attempts: String(item.attempts),
            country: item.country,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLanguageMetricViews(_ items: [LanguageMetric]) -> [LanguageMetricView] {
        var views: [LanguageMetricView] = []
        for item in items {
            views.append(toLanguageMetricView(item))
        }
        return views
    }

    static func sumLanguageMetricView(_ view: LanguageMetricView) throws -> Double {
        guard let parsedAttempts = Int(view.attempts) else {
            throw Kit.Failure("parse attempts: not a number")
        }
        return Double(parsedAttempts)
    }
}
