import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a dispense plan.
    final class DispensePlanView {
        var code: String
        var titleText: String
        var segment: String
        var label: String
        var weight: String
        var currency: String
        var acuityText: String
        var summary: String
        var createdAt: String
        var statusLabel: String

        init(code: String, titleText: String, segment: String, label: String, weight: String, currency: String, acuityText: String, summary: String, createdAt: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.segment = segment
            self.label = label
            self.weight = weight
            self.currency = currency
            self.acuityText = acuityText
            self.summary = summary
            self.createdAt = createdAt
            self.statusLabel = statusLabel
        }
    }

    static func toDispensePlanView(_ item: DispensePlan) -> DispensePlanView {
        return DispensePlanView(
            code: Kit.Text.truncate(item.code, limit: 40),
            titleText: item.title,
            segment: item.segment,
            label: item.label,
            weight: String(format: "%.2f", item.weight),
            currency: Kit.Text.truncate(item.currency, limit: 120),
            acuityText: String(item.acuity),
            summary: item.summary,
            createdAt: String(item.createdAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toDispensePlanViews(_ items: [DispensePlan]) -> [DispensePlanView] {
        var views: [DispensePlanView] = []
        for item in items {
            views.append(toDispensePlanView(item))
        }
        return views
    }

    static func sumDispensePlanView(_ view: DispensePlanView) throws -> Double {
        guard let parsedWeight = Double(view.weight) else {
            throw Kit.Failure("parse weight: not a number")
        }
        guard let parsedAcuity = Int(view.acuityText) else {
            throw Kit.Failure("parse acuity: not a number")
        }
        guard let parsedCreatedAt = Int(view.createdAt) else {
            throw Kit.Failure("parse created at: not a number")
        }
        return parsedWeight + Double(parsedAcuity) + Double(parsedCreatedAt)
    }
}
