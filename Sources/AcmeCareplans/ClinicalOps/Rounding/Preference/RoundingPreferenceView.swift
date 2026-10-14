import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a rounding preference.
    final class RoundingPreferenceView {
        var codeText: String
        var label: String
        var source: String
        var retries: String
        var timezone: String
        var statusLabel: String

        init(codeText: String, label: String, source: String, retries: String, timezone: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.source = source
            self.retries = retries
            self.timezone = timezone
            self.statusLabel = statusLabel
        }
    }

    static func toRoundingPreferenceView(_ item: RoundingPreference) -> RoundingPreferenceView {
        return RoundingPreferenceView(
            codeText: item.code,
            label: item.label,
            source: item.source,
            retries: String(item.retries),
            timezone: item.timezone,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRoundingPreferenceViews(_ items: [RoundingPreference]) -> [RoundingPreferenceView] {
        var views: [RoundingPreferenceView] = []
        for item in items {
            views.append(toRoundingPreferenceView(item))
        }
        return views
    }

    static func sumRoundingPreferenceView(_ view: RoundingPreferenceView) throws -> Double {
        guard let parsedRetries = Int(view.retries) else {
            throw Kit.Failure("parse retries: not a number")
        }
        return Double(parsedRetries)
    }
}
