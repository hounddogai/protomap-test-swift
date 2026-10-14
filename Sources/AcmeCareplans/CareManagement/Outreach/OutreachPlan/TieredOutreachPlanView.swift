import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a tiered outreach plan.
    final class TieredOutreachPlanView {
        var code: String
        var labelText: String
        var updatedAt: String
        var revision: String
        var procedureCode: String
        var statusLabel: String

        init(code: String, labelText: String, updatedAt: String, revision: String, procedureCode: String, statusLabel: String) {
            self.code = code
            self.labelText = labelText
            self.updatedAt = updatedAt
            self.revision = revision
            self.procedureCode = procedureCode
            self.statusLabel = statusLabel
        }
    }

    static func toTieredOutreachPlanView(_ item: TieredOutreachPlan) -> TieredOutreachPlanView {
        return TieredOutreachPlanView(
            code: Kit.Text.truncate(item.code, limit: 64),
            labelText: item.label,
            updatedAt: String(item.updatedAt),
            revision: String(item.revision),
            procedureCode: item.procedureCode,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toTieredOutreachPlanViews(_ items: [TieredOutreachPlan]) -> [TieredOutreachPlanView] {
        var views: [TieredOutreachPlanView] = []
        for item in items {
            views.append(toTieredOutreachPlanView(item))
        }
        return views
    }

    static func sumTieredOutreachPlanView(_ view: TieredOutreachPlanView) throws -> Double {
        guard let parsedUpdatedAt = Int(view.updatedAt) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        guard let parsedRevision = Int(view.revision) else {
            throw Kit.Failure("parse revision: not a number")
        }
        return Double(parsedUpdatedAt) + Double(parsedRevision)
    }
}
