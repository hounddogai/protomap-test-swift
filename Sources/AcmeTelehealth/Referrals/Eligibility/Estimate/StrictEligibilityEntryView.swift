import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a strict eligibility entry.
    final class StrictEligibilityEntryView {
        var code: String
        var title: String
        var ratio: String
        var unit: String
        var summaryText: String
        var statusLabel: String

        init(code: String, title: String, ratio: String, unit: String, summaryText: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.ratio = ratio
            self.unit = unit
            self.summaryText = summaryText
            self.statusLabel = statusLabel
        }
    }

    static func toStrictEligibilityEntryView(_ item: StrictEligibilityEntry) -> StrictEligibilityEntryView {
        return StrictEligibilityEntryView(
            code: item.code,
            title: item.title,
            ratio: String(format: "%.2f", item.ratio),
            unit: item.unit,
            summaryText: Kit.Text.truncate(item.summary, limit: 64),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toStrictEligibilityEntryViews(_ items: [StrictEligibilityEntry]) -> [StrictEligibilityEntryView] {
        var views: [StrictEligibilityEntryView] = []
        for item in items {
            views.append(toStrictEligibilityEntryView(item))
        }
        return views
    }

    static func sumStrictEligibilityEntryView(_ view: StrictEligibilityEntryView) throws -> Double {
        guard let parsedRatio = Double(view.ratio) else {
            throw Kit.Failure("parse ratio: not a number")
        }
        return parsedRatio
    }
}
