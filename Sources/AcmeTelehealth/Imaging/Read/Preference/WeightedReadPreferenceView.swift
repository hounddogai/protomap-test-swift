import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a weighted read preference.
    final class WeightedReadPreferenceView {
        var code: String
        var titleText: String
        var country: String
        var graceDays: String
        var specialty: String
        var statusLabel: String

        init(code: String, titleText: String, country: String, graceDays: String, specialty: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.country = country
            self.graceDays = graceDays
            self.specialty = specialty
            self.statusLabel = statusLabel
        }
    }

    static func toWeightedReadPreferenceView(_ item: WeightedReadPreference) -> WeightedReadPreferenceView {
        return WeightedReadPreferenceView(
            code: item.code,
            titleText: Kit.Text.truncate(item.title, limit: 64),
            country: item.country,
            graceDays: String(item.graceDays),
            specialty: item.specialty,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toWeightedReadPreferenceViews(_ items: [WeightedReadPreference]) -> [WeightedReadPreferenceView] {
        var views: [WeightedReadPreferenceView] = []
        for item in items {
            views.append(toWeightedReadPreferenceView(item))
        }
        return views
    }

    static func sumWeightedReadPreferenceView(_ view: WeightedReadPreferenceView) throws -> Double {
        guard let parsedGraceDays = Int(view.graceDays) else {
            throw Kit.Failure("parse grace days: not a number")
        }
        return Double(parsedGraceDays)
    }
}
