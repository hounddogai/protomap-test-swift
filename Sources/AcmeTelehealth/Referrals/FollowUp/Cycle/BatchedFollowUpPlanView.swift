import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a batched follow up plan.
    final class BatchedFollowUpPlanView {
        var codeText: String
        var titleText: String
        var name: String
        var bed: String
        var expiresAtText: String
        var statusLabel: String

        init(codeText: String, titleText: String, name: String, bed: String, expiresAtText: String, statusLabel: String) {
            self.codeText = codeText
            self.titleText = titleText
            self.name = name
            self.bed = bed
            self.expiresAtText = expiresAtText
            self.statusLabel = statusLabel
        }
    }

    static func toBatchedFollowUpPlanView(_ item: BatchedFollowUpPlan) -> BatchedFollowUpPlanView {
        return BatchedFollowUpPlanView(
            codeText: item.code,
            titleText: item.title,
            name: Kit.Text.truncate(item.name, limit: 80),
            bed: Kit.Text.truncate(item.bed, limit: 64),
            expiresAtText: String(item.expiresAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toBatchedFollowUpPlanViews(_ items: [BatchedFollowUpPlan]) -> [BatchedFollowUpPlanView] {
        var views: [BatchedFollowUpPlanView] = []
        for item in items {
            views.append(toBatchedFollowUpPlanView(item))
        }
        return views
    }

    static func sumBatchedFollowUpPlanView(_ view: BatchedFollowUpPlanView) throws -> Double {
        guard let parsedExpiresAt = Int(view.expiresAtText) else {
            throw Kit.Failure("parse expires at: not a number")
        }
        return Double(parsedExpiresAt)
    }
}
