import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a claim tier.
    final class ClaimTierView {
        var code: String
        var nameText: String
        var titleText: String
        var costText: String
        var procedureCodeText: String
        var locale: String
        var archived: String
        var encounterID: String
        var statusLabel: String

        init(code: String, nameText: String, titleText: String, costText: String, procedureCodeText: String, locale: String, archived: String, encounterID: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.titleText = titleText
            self.costText = costText
            self.procedureCodeText = procedureCodeText
            self.locale = locale
            self.archived = archived
            self.encounterID = encounterID
            self.statusLabel = statusLabel
        }
    }

    static func toClaimTierView(_ item: ClaimTier) -> ClaimTierView {
        return ClaimTierView(
            code: item.code,
            nameText: Kit.Text.truncate(item.name, limit: 64),
            titleText: item.title,
            costText: String(format: "%.2f", item.cost),
            procedureCodeText: Kit.Text.truncate(item.procedureCode, limit: 64),
            locale: item.locale,
            archived: "\(item.archived)",
            encounterID: Kit.Text.truncate(item.encounterID, limit: 120),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toClaimTierViews(_ items: [ClaimTier]) -> [ClaimTierView] {
        var views: [ClaimTierView] = []
        for item in items {
            views.append(toClaimTierView(item))
        }
        return views
    }

    static func sumClaimTierView(_ view: ClaimTierView) throws -> Double {
        guard let parsedCost = Double(view.costText) else {
            throw Kit.Failure("parse cost: not a number")
        }
        return parsedCost
    }
}
