import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a global acuity plan exception.
    final class GlobalAcuityPlanExceptionView {
        var code: String
        var title: String
        var contactEmail: String
        var margin: String
        var costText: String
        var weight: String
        var allergy: String
        var summaryText: String
        var statusLabel: String

        init(code: String, title: String, contactEmail: String, margin: String, costText: String, weight: String, allergy: String, summaryText: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.contactEmail = contactEmail
            self.margin = margin
            self.costText = costText
            self.weight = weight
            self.allergy = allergy
            self.summaryText = summaryText
            self.statusLabel = statusLabel
        }
    }

    static func toGlobalAcuityPlanExceptionView(_ item: GlobalAcuityPlanException) -> GlobalAcuityPlanExceptionView {
        return GlobalAcuityPlanExceptionView(
            code: item.code,
            title: item.title,
            contactEmail: item.contactEmail,
            margin: String(format: "%.2f", item.margin),
            costText: String(format: "%.2f", item.cost),
            weight: String(format: "%.2f", item.weight),
            allergy: item.allergy,
            summaryText: item.summary,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toGlobalAcuityPlanExceptionViews(_ items: [GlobalAcuityPlanException]) -> [GlobalAcuityPlanExceptionView] {
        var views: [GlobalAcuityPlanExceptionView] = []
        for item in items {
            views.append(toGlobalAcuityPlanExceptionView(item))
        }
        return views
    }

    static func sumGlobalAcuityPlanExceptionView(_ view: GlobalAcuityPlanExceptionView) throws -> Double {
        guard let parsedMargin = Double(view.margin) else {
            throw Kit.Failure("parse margin: not a number")
        }
        guard let parsedCost = Double(view.costText) else {
            throw Kit.Failure("parse cost: not a number")
        }
        guard let parsedWeight = Double(view.weight) else {
            throw Kit.Failure("parse weight: not a number")
        }
        return parsedMargin + parsedCost + parsedWeight
    }
}
