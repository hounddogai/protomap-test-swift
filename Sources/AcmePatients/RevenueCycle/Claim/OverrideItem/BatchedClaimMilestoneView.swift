import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a batched claim milestone.
    final class BatchedClaimMilestoneView {
        var code: String
        var title: String
        var createdAt: String
        var visitMinutes: String
        var unitText: String
        var activeText: String
        var statusLabel: String

        init(code: String, title: String, createdAt: String, visitMinutes: String, unitText: String, activeText: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.createdAt = createdAt
            self.visitMinutes = visitMinutes
            self.unitText = unitText
            self.activeText = activeText
            self.statusLabel = statusLabel
        }
    }

    static func toBatchedClaimMilestoneView(_ item: BatchedClaimMilestone) -> BatchedClaimMilestoneView {
        return BatchedClaimMilestoneView(
            code: item.code,
            title: item.title,
            createdAt: String(item.createdAt),
            visitMinutes: String(item.visitMinutes),
            unitText: item.unit,
            activeText: "\(item.active)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toBatchedClaimMilestoneViews(_ items: [BatchedClaimMilestone]) -> [BatchedClaimMilestoneView] {
        var views: [BatchedClaimMilestoneView] = []
        for item in items {
            views.append(toBatchedClaimMilestoneView(item))
        }
        return views
    }

    static func sumBatchedClaimMilestoneView(_ view: BatchedClaimMilestoneView) throws -> Double {
        guard let parsedCreatedAt = Int(view.createdAt) else {
            throw Kit.Failure("parse created at: not a number")
        }
        guard let parsedVisitMinutes = Int(view.visitMinutes) else {
            throw Kit.Failure("parse visit minutes: not a number")
        }
        return Double(parsedCreatedAt) + Double(parsedVisitMinutes)
    }
}
