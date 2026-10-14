import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a slot item.
    final class SlotItemView {
        var code: String
        var label: String
        var titleText: String
        var ratio: String
        var procedureCodeText: String
        var localeText: String
        var summary: String
        var graceDaysText: String
        var statusLabel: String

        init(code: String, label: String, titleText: String, ratio: String, procedureCodeText: String, localeText: String, summary: String, graceDaysText: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.titleText = titleText
            self.ratio = ratio
            self.procedureCodeText = procedureCodeText
            self.localeText = localeText
            self.summary = summary
            self.graceDaysText = graceDaysText
            self.statusLabel = statusLabel
        }
    }

    static func toSlotItemView(_ item: SlotItem) -> SlotItemView {
        return SlotItemView(
            code: Kit.Text.truncate(item.code, limit: 40),
            label: Kit.Text.truncate(item.label, limit: 40),
            titleText: item.title,
            ratio: String(format: "%.2f", item.ratio),
            procedureCodeText: item.procedureCode,
            localeText: item.locale,
            summary: item.summary,
            graceDaysText: String(item.graceDays),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toSlotItemViews(_ items: [SlotItem]) -> [SlotItemView] {
        var views: [SlotItemView] = []
        for item in items {
            views.append(toSlotItemView(item))
        }
        return views
    }

    static func sumSlotItemView(_ view: SlotItemView) throws -> Double {
        guard let parsedRatio = Double(view.ratio) else {
            throw Kit.Failure("parse ratio: not a number")
        }
        guard let parsedGraceDays = Int(view.graceDaysText) else {
            throw Kit.Failure("parse grace days: not a number")
        }
        return parsedRatio + Double(parsedGraceDays)
    }
}
