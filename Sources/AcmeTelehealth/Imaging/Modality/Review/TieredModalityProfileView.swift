import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a tiered modality profile.
    final class TieredModalityProfileView {
        var code: String
        var name: String
        var rate: String
        var budget: String
        var label: String
        var statusLabel: String

        init(code: String, name: String, rate: String, budget: String, label: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.rate = rate
            self.budget = budget
            self.label = label
            self.statusLabel = statusLabel
        }
    }

    static func toTieredModalityProfileView(_ item: TieredModalityProfile) -> TieredModalityProfileView {
        return TieredModalityProfileView(
            code: item.code,
            name: Kit.Text.truncate(item.name, limit: 120),
            rate: String(format: "%.2f", item.rate),
            budget: String(format: "%.2f", item.budget),
            label: item.label,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toTieredModalityProfileViews(_ items: [TieredModalityProfile]) -> [TieredModalityProfileView] {
        var views: [TieredModalityProfileView] = []
        for item in items {
            views.append(toTieredModalityProfileView(item))
        }
        return views
    }

    static func sumTieredModalityProfileView(_ view: TieredModalityProfileView) throws -> Double {
        guard let parsedRate = Double(view.rate) else {
            throw Kit.Failure("parse rate: not a number")
        }
        guard let parsedBudget = Double(view.budget) else {
            throw Kit.Failure("parse budget: not a number")
        }
        return parsedRate + parsedBudget
    }
}
