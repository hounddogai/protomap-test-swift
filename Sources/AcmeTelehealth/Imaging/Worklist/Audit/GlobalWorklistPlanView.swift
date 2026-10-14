import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a global worklist plan.
    final class GlobalWorklistPlanView {
        var code: String
        var label: String
        var archived: String
        var ratio: String
        var procedureCode: String
        var notes: String
        var allergy: String
        var titleText: String
        var updatedAt: String
        var statusLabel: String

        init(code: String, label: String, archived: String, ratio: String, procedureCode: String, notes: String, allergy: String, titleText: String, updatedAt: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.archived = archived
            self.ratio = ratio
            self.procedureCode = procedureCode
            self.notes = notes
            self.allergy = allergy
            self.titleText = titleText
            self.updatedAt = updatedAt
            self.statusLabel = statusLabel
        }
    }

    static func toGlobalWorklistPlanView(_ item: GlobalWorklistPlan) -> GlobalWorklistPlanView {
        return GlobalWorklistPlanView(
            code: item.code,
            label: item.label,
            archived: "\(item.archived)",
            ratio: String(format: "%.2f", item.ratio),
            procedureCode: item.procedureCode,
            notes: item.notes,
            allergy: item.allergy,
            titleText: Kit.Text.truncate(item.title, limit: 40),
            updatedAt: String(item.updatedAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toGlobalWorklistPlanViews(_ items: [GlobalWorklistPlan]) -> [GlobalWorklistPlanView] {
        var views: [GlobalWorklistPlanView] = []
        for item in items {
            views.append(toGlobalWorklistPlanView(item))
        }
        return views
    }

    static func sumGlobalWorklistPlanView(_ view: GlobalWorklistPlanView) throws -> Double {
        guard let parsedRatio = Double(view.ratio) else {
            throw Kit.Failure("parse ratio: not a number")
        }
        guard let parsedUpdatedAt = Int(view.updatedAt) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        return parsedRatio + Double(parsedUpdatedAt)
    }
}
