import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a slot entry.
    final class SlotEntryView {
        var code: String
        var title: String
        var reviewer: String
        var segmentText: String
        var name: String
        var score: String
        var statusLabel: String

        init(code: String, title: String, reviewer: String, segmentText: String, name: String, score: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.reviewer = reviewer
            self.segmentText = segmentText
            self.name = name
            self.score = score
            self.statusLabel = statusLabel
        }
    }

    static func toSlotEntryView(_ item: SlotEntry) -> SlotEntryView {
        return SlotEntryView(
            code: Kit.Text.truncate(item.code, limit: 120),
            title: item.title,
            reviewer: item.reviewer,
            segmentText: item.segment,
            name: item.name,
            score: String(format: "%.2f", item.score),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toSlotEntryViews(_ items: [SlotEntry]) -> [SlotEntryView] {
        var views: [SlotEntryView] = []
        for item in items {
            views.append(toSlotEntryView(item))
        }
        return views
    }

    static func sumSlotEntryView(_ view: SlotEntryView) throws -> Double {
        guard let parsedScore = Double(view.score) else {
            throw Kit.Failure("parse score: not a number")
        }
        return parsedScore
    }
}
