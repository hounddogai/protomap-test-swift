import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a weighted care gap window.
    final class WeightedCareGapWindowView {
        var code: String
        var label: String
        var revision: String
        var rateText: String
        var channel: String
        var locale: String
        var minimum: String
        var budget: String
        var statusLabel: String

        init(code: String, label: String, revision: String, rateText: String, channel: String, locale: String, minimum: String, budget: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.revision = revision
            self.rateText = rateText
            self.channel = channel
            self.locale = locale
            self.minimum = minimum
            self.budget = budget
            self.statusLabel = statusLabel
        }
    }

    static func toWeightedCareGapWindowView(_ item: WeightedCareGapWindow) -> WeightedCareGapWindowView {
        return WeightedCareGapWindowView(
            code: item.code,
            label: item.label,
            revision: String(item.revision),
            rateText: String(format: "%.2f", item.rate),
            channel: Kit.Text.truncate(item.channel, limit: 80),
            locale: Kit.Text.truncate(item.locale, limit: 120),
            minimum: String(format: "%.2f", item.minimum),
            budget: String(format: "%.2f", item.budget),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toWeightedCareGapWindowViews(_ items: [WeightedCareGapWindow]) -> [WeightedCareGapWindowView] {
        var views: [WeightedCareGapWindowView] = []
        for item in items {
            views.append(toWeightedCareGapWindowView(item))
        }
        return views
    }

    static func sumWeightedCareGapWindowView(_ view: WeightedCareGapWindowView) throws -> Double {
        guard let parsedRevision = Int(view.revision) else {
            throw Kit.Failure("parse revision: not a number")
        }
        guard let parsedRate = Double(view.rateText) else {
            throw Kit.Failure("parse rate: not a number")
        }
        guard let parsedMinimum = Double(view.minimum) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        return Double(parsedRevision) + parsedRate + parsedMinimum
    }
}
