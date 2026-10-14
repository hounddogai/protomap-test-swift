import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a weighted alert plan.
    final class WeightedAlertPlanView {
        var codeText: String
        var title: String
        var ratio: String
        var weight: String
        var encounterID: String
        var copay: String
        var timezone: String
        var windowDays: String
        var acuityText: String
        var statusLabel: String

        init(codeText: String, title: String, ratio: String, weight: String, encounterID: String, copay: String, timezone: String, windowDays: String, acuityText: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.ratio = ratio
            self.weight = weight
            self.encounterID = encounterID
            self.copay = copay
            self.timezone = timezone
            self.windowDays = windowDays
            self.acuityText = acuityText
            self.statusLabel = statusLabel
        }
    }

    static func toWeightedAlertPlanView(_ item: WeightedAlertPlan) -> WeightedAlertPlanView {
        return WeightedAlertPlanView(
            codeText: Kit.Text.truncate(item.code, limit: 40),
            title: item.title,
            ratio: String(format: "%.2f", item.ratio),
            weight: String(format: "%.2f", item.weight),
            encounterID: item.encounterID,
            copay: String(format: "%.2f", item.copay),
            timezone: item.timezone,
            windowDays: String(item.windowDays),
            acuityText: String(item.acuity),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toWeightedAlertPlanViews(_ items: [WeightedAlertPlan]) -> [WeightedAlertPlanView] {
        var views: [WeightedAlertPlanView] = []
        for item in items {
            views.append(toWeightedAlertPlanView(item))
        }
        return views
    }

    static func sumWeightedAlertPlanView(_ view: WeightedAlertPlanView) throws -> Double {
        guard let parsedRatio = Double(view.ratio) else {
            throw Kit.Failure("parse ratio: not a number")
        }
        guard let parsedWeight = Double(view.weight) else {
            throw Kit.Failure("parse weight: not a number")
        }
        guard let parsedCopay = Double(view.copay) else {
            throw Kit.Failure("parse copay: not a number")
        }
        return parsedRatio + parsedWeight + parsedCopay
    }
}
