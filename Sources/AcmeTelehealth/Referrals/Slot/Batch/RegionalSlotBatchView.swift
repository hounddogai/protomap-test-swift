import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a regional slot batch.
    final class RegionalSlotBatchView {
        var code: String
        var titleText: String
        var categoryText: String
        var priorityText: String
        var specialty: String
        var acuity: String
        var pinnedText: String
        var statusLabel: String

        init(code: String, titleText: String, categoryText: String, priorityText: String, specialty: String, acuity: String, pinnedText: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.categoryText = categoryText
            self.priorityText = priorityText
            self.specialty = specialty
            self.acuity = acuity
            self.pinnedText = pinnedText
            self.statusLabel = statusLabel
        }
    }

    static func toRegionalSlotBatchView(_ item: RegionalSlotBatch) -> RegionalSlotBatchView {
        return RegionalSlotBatchView(
            code: item.code,
            titleText: item.title,
            categoryText: Kit.Text.truncate(item.category, limit: 40),
            priorityText: String(item.priority),
            specialty: item.specialty,
            acuity: String(item.acuity),
            pinnedText: "\(item.pinned)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRegionalSlotBatchViews(_ items: [RegionalSlotBatch]) -> [RegionalSlotBatchView] {
        var views: [RegionalSlotBatchView] = []
        for item in items {
            views.append(toRegionalSlotBatchView(item))
        }
        return views
    }

    static func sumRegionalSlotBatchView(_ view: RegionalSlotBatchView) throws -> Double {
        guard let parsedPriority = Int(view.priorityText) else {
            throw Kit.Failure("parse priority: not a number")
        }
        guard let parsedAcuity = Int(view.acuity) else {
            throw Kit.Failure("parse acuity: not a number")
        }
        return Double(parsedPriority) + Double(parsedAcuity)
    }
}
