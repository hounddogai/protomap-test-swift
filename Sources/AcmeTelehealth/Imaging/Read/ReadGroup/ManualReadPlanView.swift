import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a manual read plan.
    final class ManualReadPlanView {
        var code: String
        var name: String
        var reviewer: String
        var ownerID: String
        var limit: String
        var updatedAt: String
        var windowDays: String
        var batchSize: String
        var statusLabel: String

        init(code: String, name: String, reviewer: String, ownerID: String, limit: String, updatedAt: String, windowDays: String, batchSize: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.reviewer = reviewer
            self.ownerID = ownerID
            self.limit = limit
            self.updatedAt = updatedAt
            self.windowDays = windowDays
            self.batchSize = batchSize
            self.statusLabel = statusLabel
        }
    }

    static func toManualReadPlanView(_ item: ManualReadPlan) -> ManualReadPlanView {
        return ManualReadPlanView(
            code: item.code,
            name: Kit.Text.truncate(item.name, limit: 64),
            reviewer: Kit.Text.truncate(item.reviewer, limit: 40),
            ownerID: item.ownerID,
            limit: String(item.limit),
            updatedAt: String(item.updatedAt),
            windowDays: String(item.windowDays),
            batchSize: String(item.batchSize),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toManualReadPlanViews(_ items: [ManualReadPlan]) -> [ManualReadPlanView] {
        var views: [ManualReadPlanView] = []
        for item in items {
            views.append(toManualReadPlanView(item))
        }
        return views
    }

    static func sumManualReadPlanView(_ view: ManualReadPlanView) throws -> Double {
        guard let parsedLimit = Int(view.limit) else {
            throw Kit.Failure("parse limit: not a number")
        }
        guard let parsedUpdatedAt = Int(view.updatedAt) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        guard let parsedWindowDays = Int(view.windowDays) else {
            throw Kit.Failure("parse window days: not a number")
        }
        return Double(parsedLimit) + Double(parsedUpdatedAt) + Double(parsedWindowDays)
    }
}
