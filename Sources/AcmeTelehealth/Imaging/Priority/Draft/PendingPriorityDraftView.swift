import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a pending priority draft.
    final class PendingPriorityDraftView {
        var code: String
        var title: String
        var procedureCode: String
        var costText: String
        var capacity: String
        var statusLabel: String

        init(code: String, title: String, procedureCode: String, costText: String, capacity: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.procedureCode = procedureCode
            self.costText = costText
            self.capacity = capacity
            self.statusLabel = statusLabel
        }
    }

    static func toPendingPriorityDraftView(_ item: PendingPriorityDraft) -> PendingPriorityDraftView {
        return PendingPriorityDraftView(
            code: Kit.Text.truncate(item.code, limit: 120),
            title: Kit.Text.truncate(item.title, limit: 64),
            procedureCode: item.procedureCode,
            costText: String(format: "%.2f", item.cost),
            capacity: String(item.capacity),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPendingPriorityDraftViews(_ items: [PendingPriorityDraft]) -> [PendingPriorityDraftView] {
        var views: [PendingPriorityDraftView] = []
        for item in items {
            views.append(toPendingPriorityDraftView(item))
        }
        return views
    }

    static func sumPendingPriorityDraftView(_ view: PendingPriorityDraftView) throws -> Double {
        guard let parsedCost = Double(view.costText) else {
            throw Kit.Failure("parse cost: not a number")
        }
        guard let parsedCapacity = Int(view.capacity) else {
            throw Kit.Failure("parse capacity: not a number")
        }
        return parsedCost + Double(parsedCapacity)
    }
}
