import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a fallback cleaning entry.
    final class FallbackCleaningEntryView {
        var codeText: String
        var name: String
        var titleText: String
        var source: String
        var category: String
        var currency: String
        var windowDays: String
        var timezone: String
        var statusLabel: String

        init(codeText: String, name: String, titleText: String, source: String, category: String, currency: String, windowDays: String, timezone: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.titleText = titleText
            self.source = source
            self.category = category
            self.currency = currency
            self.windowDays = windowDays
            self.timezone = timezone
            self.statusLabel = statusLabel
        }
    }

    static func toFallbackCleaningEntryView(_ item: FallbackCleaningEntry) -> FallbackCleaningEntryView {
        return FallbackCleaningEntryView(
            codeText: item.code,
            name: item.name,
            titleText: item.title,
            source: item.source,
            category: Kit.Text.truncate(item.category, limit: 80),
            currency: Kit.Text.truncate(item.currency, limit: 80),
            windowDays: String(item.windowDays),
            timezone: item.timezone,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toFallbackCleaningEntryViews(_ items: [FallbackCleaningEntry]) -> [FallbackCleaningEntryView] {
        var views: [FallbackCleaningEntryView] = []
        for item in items {
            views.append(toFallbackCleaningEntryView(item))
        }
        return views
    }

    static func sumFallbackCleaningEntryView(_ view: FallbackCleaningEntryView) throws -> Double {
        guard let parsedWindowDays = Int(view.windowDays) else {
            throw Kit.Failure("parse window days: not a number")
        }
        return Double(parsedWindowDays)
    }
}
