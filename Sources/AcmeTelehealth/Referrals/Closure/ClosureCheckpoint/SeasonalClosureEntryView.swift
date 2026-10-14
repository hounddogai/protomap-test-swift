import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a seasonal closure entry.
    final class SeasonalClosureEntryView {
        var code: String
        var title: String
        var timezone: String
        var localeText: String
        var reviewer: String
        var cost: String
        var notes: String
        var quantity: String
        var summaryText: String
        var region: String
        var dosageMgText: String
        var statusLabel: String

        init(code: String, title: String, timezone: String, localeText: String, reviewer: String, cost: String, notes: String, quantity: String, summaryText: String, region: String, dosageMgText: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.timezone = timezone
            self.localeText = localeText
            self.reviewer = reviewer
            self.cost = cost
            self.notes = notes
            self.quantity = quantity
            self.summaryText = summaryText
            self.region = region
            self.dosageMgText = dosageMgText
            self.statusLabel = statusLabel
        }
    }

    static func toSeasonalClosureEntryView(_ item: SeasonalClosureEntry) -> SeasonalClosureEntryView {
        return SeasonalClosureEntryView(
            code: item.code,
            title: Kit.Text.truncate(item.title, limit: 64),
            timezone: Kit.Text.truncate(item.timezone, limit: 80),
            localeText: Kit.Text.truncate(item.locale, limit: 64),
            reviewer: item.reviewer,
            cost: String(format: "%.2f", item.cost),
            notes: item.notes,
            quantity: String(item.quantity),
            summaryText: item.summary,
            region: Kit.Text.truncate(item.region, limit: 64),
            dosageMgText: String(format: "%.2f", item.dosageMg),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toSeasonalClosureEntryViews(_ items: [SeasonalClosureEntry]) -> [SeasonalClosureEntryView] {
        var views: [SeasonalClosureEntryView] = []
        for item in items {
            views.append(toSeasonalClosureEntryView(item))
        }
        return views
    }

    static func sumSeasonalClosureEntryView(_ view: SeasonalClosureEntryView) throws -> Double {
        guard let parsedCost = Double(view.cost) else {
            throw Kit.Failure("parse cost: not a number")
        }
        guard let parsedQuantity = Int(view.quantity) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        guard let parsedDosageMg = Double(view.dosageMgText) else {
            throw Kit.Failure("parse dosage mg: not a number")
        }
        return parsedCost + Double(parsedQuantity) + parsedDosageMg
    }
}
