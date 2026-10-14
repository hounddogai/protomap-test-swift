import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a reference range slot.
    final class ReferenceRangeSlotView {
        var code: String
        var labelText: String
        var externalRefText: String
        var description: String
        var categoryText: String
        var score: String
        var statusLabel: String

        init(code: String, labelText: String, externalRefText: String, description: String, categoryText: String, score: String, statusLabel: String) {
            self.code = code
            self.labelText = labelText
            self.externalRefText = externalRefText
            self.description = description
            self.categoryText = categoryText
            self.score = score
            self.statusLabel = statusLabel
        }
    }

    static func toReferenceRangeSlotView(_ item: ReferenceRangeSlot) -> ReferenceRangeSlotView {
        return ReferenceRangeSlotView(
            code: item.code,
            labelText: item.label,
            externalRefText: item.externalRef,
            description: item.description,
            categoryText: item.category,
            score: String(format: "%.2f", item.score),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toReferenceRangeSlotViews(_ items: [ReferenceRangeSlot]) -> [ReferenceRangeSlotView] {
        var views: [ReferenceRangeSlotView] = []
        for item in items {
            views.append(toReferenceRangeSlotView(item))
        }
        return views
    }

    static func sumReferenceRangeSlotView(_ view: ReferenceRangeSlotView) throws -> Double {
        guard let parsedScore = Double(view.score) else {
            throw Kit.Failure("parse score: not a number")
        }
        return parsedScore
    }
}
