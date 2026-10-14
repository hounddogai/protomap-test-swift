import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a worklist cycle.
    final class WorklistCycleView {
        var code: String
        var name: String
        var archived: String
        var priorityText: String
        var clinicianID: String
        var cost: String
        var sequence: String
        var discount: String
        var revisionText: String
        var startsAt: String
        var approved: String
        var statusLabel: String

        init(code: String, name: String, archived: String, priorityText: String, clinicianID: String, cost: String, sequence: String, discount: String, revisionText: String, startsAt: String, approved: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.archived = archived
            self.priorityText = priorityText
            self.clinicianID = clinicianID
            self.cost = cost
            self.sequence = sequence
            self.discount = discount
            self.revisionText = revisionText
            self.startsAt = startsAt
            self.approved = approved
            self.statusLabel = statusLabel
        }
    }

    static func toWorklistCycleView(_ item: WorklistCycle) -> WorklistCycleView {
        return WorklistCycleView(
            code: item.code,
            name: item.name,
            archived: "\(item.archived)",
            priorityText: String(item.priority),
            clinicianID: item.clinicianID,
            cost: String(format: "%.2f", item.cost),
            sequence: String(item.sequence),
            discount: String(format: "%.2f", item.discount),
            revisionText: String(item.revision),
            startsAt: String(item.startsAt),
            approved: "\(item.approved)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toWorklistCycleViews(_ items: [WorklistCycle]) -> [WorklistCycleView] {
        var views: [WorklistCycleView] = []
        for item in items {
            views.append(toWorklistCycleView(item))
        }
        return views
    }

    static func sumWorklistCycleView(_ view: WorklistCycleView) throws -> Double {
        guard let parsedPriority = Int(view.priorityText) else {
            throw Kit.Failure("parse priority: not a number")
        }
        guard let parsedCost = Double(view.cost) else {
            throw Kit.Failure("parse cost: not a number")
        }
        guard let parsedSequence = Int(view.sequence) else {
            throw Kit.Failure("parse sequence: not a number")
        }
        return Double(parsedPriority) + parsedCost + Double(parsedSequence)
    }
}
