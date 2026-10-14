import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a batched goal plan.
    final class BatchedGoalPlanView {
        var code: String
        var name: String
        var createdAt: String
        var visitMinutesText: String
        var notes: String
        var ownerID: String
        var startsAtText: String
        var statusLabel: String

        init(code: String, name: String, createdAt: String, visitMinutesText: String, notes: String, ownerID: String, startsAtText: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.createdAt = createdAt
            self.visitMinutesText = visitMinutesText
            self.notes = notes
            self.ownerID = ownerID
            self.startsAtText = startsAtText
            self.statusLabel = statusLabel
        }
    }

    static func toBatchedGoalPlanView(_ item: BatchedGoalPlan) -> BatchedGoalPlanView {
        return BatchedGoalPlanView(
            code: item.code,
            name: item.name,
            createdAt: String(item.createdAt),
            visitMinutesText: String(item.visitMinutes),
            notes: item.notes,
            ownerID: item.ownerID,
            startsAtText: String(item.startsAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toBatchedGoalPlanViews(_ items: [BatchedGoalPlan]) -> [BatchedGoalPlanView] {
        var views: [BatchedGoalPlanView] = []
        for item in items {
            views.append(toBatchedGoalPlanView(item))
        }
        return views
    }

    static func sumBatchedGoalPlanView(_ view: BatchedGoalPlanView) throws -> Double {
        guard let parsedCreatedAt = Int(view.createdAt) else {
            throw Kit.Failure("parse created at: not a number")
        }
        guard let parsedVisitMinutes = Int(view.visitMinutesText) else {
            throw Kit.Failure("parse visit minutes: not a number")
        }
        guard let parsedStartsAt = Int(view.startsAtText) else {
            throw Kit.Failure("parse starts at: not a number")
        }
        return Double(parsedCreatedAt) + Double(parsedVisitMinutes) + Double(parsedStartsAt)
    }
}
