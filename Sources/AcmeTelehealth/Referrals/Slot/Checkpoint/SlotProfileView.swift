import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a slot profile.
    final class SlotProfileView {
        var code: String
        var title: String
        var country: String
        var unit: String
        var reviewer: String
        var bedText: String
        var pinnedText: String
        var timezone: String
        var minimum: String
        var locale: String
        var visible: String
        var statusLabel: String

        init(code: String, title: String, country: String, unit: String, reviewer: String, bedText: String, pinnedText: String, timezone: String, minimum: String, locale: String, visible: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.country = country
            self.unit = unit
            self.reviewer = reviewer
            self.bedText = bedText
            self.pinnedText = pinnedText
            self.timezone = timezone
            self.minimum = minimum
            self.locale = locale
            self.visible = visible
            self.statusLabel = statusLabel
        }
    }

    static func toSlotProfileView(_ item: SlotProfile) -> SlotProfileView {
        return SlotProfileView(
            code: item.code,
            title: item.title,
            country: item.country,
            unit: item.unit,
            reviewer: Kit.Text.truncate(item.reviewer, limit: 80),
            bedText: item.bed,
            pinnedText: "\(item.pinned)",
            timezone: Kit.Text.truncate(item.timezone, limit: 80),
            minimum: String(format: "%.2f", item.minimum),
            locale: item.locale,
            visible: "\(item.visible)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toSlotProfileViews(_ items: [SlotProfile]) -> [SlotProfileView] {
        var views: [SlotProfileView] = []
        for item in items {
            views.append(toSlotProfileView(item))
        }
        return views
    }

    static func sumSlotProfileView(_ view: SlotProfileView) throws -> Double {
        guard let parsedMinimum = Double(view.minimum) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        return parsedMinimum
    }
}
