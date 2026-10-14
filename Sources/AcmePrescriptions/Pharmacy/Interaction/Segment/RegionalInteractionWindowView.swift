import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a regional interaction window.
    final class RegionalInteractionWindowView {
        var code: String
        var titleText: String
        var acuityText: String
        var externalRefText: String
        var archived: String
        var summaryText: String
        var statusLabel: String

        init(code: String, titleText: String, acuityText: String, externalRefText: String, archived: String, summaryText: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.acuityText = acuityText
            self.externalRefText = externalRefText
            self.archived = archived
            self.summaryText = summaryText
            self.statusLabel = statusLabel
        }
    }

    static func toRegionalInteractionWindowView(_ item: RegionalInteractionWindow) -> RegionalInteractionWindowView {
        return RegionalInteractionWindowView(
            code: item.code,
            titleText: Kit.Text.truncate(item.title, limit: 120),
            acuityText: String(item.acuity),
            externalRefText: item.externalRef,
            archived: "\(item.archived)",
            summaryText: item.summary,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRegionalInteractionWindowViews(_ items: [RegionalInteractionWindow]) -> [RegionalInteractionWindowView] {
        var views: [RegionalInteractionWindowView] = []
        for item in items {
            views.append(toRegionalInteractionWindowView(item))
        }
        return views
    }

    static func sumRegionalInteractionWindowView(_ view: RegionalInteractionWindowView) throws -> Double {
        guard let parsedAcuity = Int(view.acuityText) else {
            throw Kit.Failure("parse acuity: not a number")
        }
        return Double(parsedAcuity)
    }
}
