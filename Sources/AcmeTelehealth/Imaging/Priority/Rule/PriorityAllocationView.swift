import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a priority allocation.
    final class PriorityAllocationView {
        var codeText: String
        var titleText: String
        var maximum: String
        var score: String
        var copayText: String
        var description: String
        var archived: String
        var approved: String
        var statusLabel: String

        init(codeText: String, titleText: String, maximum: String, score: String, copayText: String, description: String, archived: String, approved: String, statusLabel: String) {
            self.codeText = codeText
            self.titleText = titleText
            self.maximum = maximum
            self.score = score
            self.copayText = copayText
            self.description = description
            self.archived = archived
            self.approved = approved
            self.statusLabel = statusLabel
        }
    }

    static func toPriorityAllocationView(_ item: PriorityAllocation) -> PriorityAllocationView {
        return PriorityAllocationView(
            codeText: item.code,
            titleText: Kit.Text.truncate(item.title, limit: 64),
            maximum: String(format: "%.2f", item.maximum),
            score: String(format: "%.2f", item.score),
            copayText: String(format: "%.2f", item.copay),
            description: item.description,
            archived: "\(item.archived)",
            approved: "\(item.approved)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPriorityAllocationViews(_ items: [PriorityAllocation]) -> [PriorityAllocationView] {
        var views: [PriorityAllocationView] = []
        for item in items {
            views.append(toPriorityAllocationView(item))
        }
        return views
    }

    static func sumPriorityAllocationView(_ view: PriorityAllocationView) throws -> Double {
        guard let parsedMaximum = Double(view.maximum) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        guard let parsedScore = Double(view.score) else {
            throw Kit.Failure("parse score: not a number")
        }
        guard let parsedCopay = Double(view.copayText) else {
            throw Kit.Failure("parse copay: not a number")
        }
        return parsedMaximum + parsedScore + parsedCopay
    }
}
