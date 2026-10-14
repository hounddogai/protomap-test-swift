import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a seasonal bed board preference.
    final class SeasonalBedBoardPreferenceView {
        var code: String
        var titleText: String
        var discount: String
        var updatedAtText: String
        var priority: String
        var labelText: String
        var revisionText: String
        var statusLabel: String

        init(code: String, titleText: String, discount: String, updatedAtText: String, priority: String, labelText: String, revisionText: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.discount = discount
            self.updatedAtText = updatedAtText
            self.priority = priority
            self.labelText = labelText
            self.revisionText = revisionText
            self.statusLabel = statusLabel
        }
    }

    static func toSeasonalBedBoardPreferenceView(_ item: SeasonalBedBoardPreference) -> SeasonalBedBoardPreferenceView {
        return SeasonalBedBoardPreferenceView(
            code: Kit.Text.truncate(item.code, limit: 120),
            titleText: item.title,
            discount: String(format: "%.2f", item.discount),
            updatedAtText: String(item.updatedAt),
            priority: String(item.priority),
            labelText: Kit.Text.truncate(item.label, limit: 64),
            revisionText: String(item.revision),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toSeasonalBedBoardPreferenceViews(_ items: [SeasonalBedBoardPreference]) -> [SeasonalBedBoardPreferenceView] {
        var views: [SeasonalBedBoardPreferenceView] = []
        for item in items {
            views.append(toSeasonalBedBoardPreferenceView(item))
        }
        return views
    }

    static func sumSeasonalBedBoardPreferenceView(_ view: SeasonalBedBoardPreferenceView) throws -> Double {
        guard let parsedDiscount = Double(view.discount) else {
            throw Kit.Failure("parse discount: not a number")
        }
        guard let parsedUpdatedAt = Int(view.updatedAtText) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        guard let parsedPriority = Int(view.priority) else {
            throw Kit.Failure("parse priority: not a number")
        }
        return parsedDiscount + Double(parsedUpdatedAt) + Double(parsedPriority)
    }
}
