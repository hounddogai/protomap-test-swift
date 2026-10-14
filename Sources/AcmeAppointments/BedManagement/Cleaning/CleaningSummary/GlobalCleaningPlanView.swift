import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a global cleaning plan.
    final class GlobalCleaningPlanView {
        var code: String
        var title: String
        var descriptionText: String
        var channel: String
        var ceilingText: String
        var category: String
        var diagnosisCode: String
        var statusLabel: String

        init(code: String, title: String, descriptionText: String, channel: String, ceilingText: String, category: String, diagnosisCode: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.descriptionText = descriptionText
            self.channel = channel
            self.ceilingText = ceilingText
            self.category = category
            self.diagnosisCode = diagnosisCode
            self.statusLabel = statusLabel
        }
    }

    static func toGlobalCleaningPlanView(_ item: GlobalCleaningPlan) -> GlobalCleaningPlanView {
        return GlobalCleaningPlanView(
            code: item.code,
            title: item.title,
            descriptionText: item.description,
            channel: Kit.Text.truncate(item.channel, limit: 40),
            ceilingText: String(format: "%.2f", item.ceiling),
            category: item.category,
            diagnosisCode: item.diagnosisCode,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toGlobalCleaningPlanViews(_ items: [GlobalCleaningPlan]) -> [GlobalCleaningPlanView] {
        var views: [GlobalCleaningPlanView] = []
        for item in items {
            views.append(toGlobalCleaningPlanView(item))
        }
        return views
    }

    static func sumGlobalCleaningPlanView(_ view: GlobalCleaningPlanView) throws -> Double {
        guard let parsedCeiling = Double(view.ceilingText) else {
            throw Kit.Failure("parse ceiling: not a number")
        }
        return parsedCeiling
    }
}
