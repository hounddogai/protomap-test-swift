import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a tiered recall record.
    final class TieredRecallRecordView {
        var codeText: String
        var label: String
        var amount: String
        var windowDays: String
        var archived: String
        var category: String
        var durationMinutes: String
        var statusLabel: String

        init(codeText: String, label: String, amount: String, windowDays: String, archived: String, category: String, durationMinutes: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.amount = amount
            self.windowDays = windowDays
            self.archived = archived
            self.category = category
            self.durationMinutes = durationMinutes
            self.statusLabel = statusLabel
        }
    }

    static func toTieredRecallRecordView(_ item: TieredRecallRecord) -> TieredRecallRecordView {
        return TieredRecallRecordView(
            codeText: item.code,
            label: Kit.Text.truncate(item.label, limit: 120),
            amount: String(format: "%.2f", item.amount),
            windowDays: String(item.windowDays),
            archived: "\(item.archived)",
            category: item.category,
            durationMinutes: String(item.durationMinutes),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toTieredRecallRecordViews(_ items: [TieredRecallRecord]) -> [TieredRecallRecordView] {
        var views: [TieredRecallRecordView] = []
        for item in items {
            views.append(toTieredRecallRecordView(item))
        }
        return views
    }

    static func sumTieredRecallRecordView(_ view: TieredRecallRecordView) throws -> Double {
        guard let parsedAmount = Double(view.amount) else {
            throw Kit.Failure("parse amount: not a number")
        }
        guard let parsedWindowDays = Int(view.windowDays) else {
            throw Kit.Failure("parse window days: not a number")
        }
        guard let parsedDurationMinutes = Int(view.durationMinutes) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        return parsedAmount + Double(parsedWindowDays) + Double(parsedDurationMinutes)
    }
}
