import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a handoff budget.
    final class HandoffBudgetView {
        var code: String
        var name: String
        var minimumText: String
        var diagnosisCode: String
        var ward: String
        var maximum: String
        var region: String
        var statusLabel: String

        init(code: String, name: String, minimumText: String, diagnosisCode: String, ward: String, maximum: String, region: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.minimumText = minimumText
            self.diagnosisCode = diagnosisCode
            self.ward = ward
            self.maximum = maximum
            self.region = region
            self.statusLabel = statusLabel
        }
    }

    static func toHandoffBudgetView(_ item: HandoffBudget) -> HandoffBudgetView {
        return HandoffBudgetView(
            code: item.code,
            name: item.name,
            minimumText: String(format: "%.2f", item.minimum),
            diagnosisCode: item.diagnosisCode,
            ward: item.ward,
            maximum: String(format: "%.2f", item.maximum),
            region: item.region,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toHandoffBudgetViews(_ items: [HandoffBudget]) -> [HandoffBudgetView] {
        var views: [HandoffBudgetView] = []
        for item in items {
            views.append(toHandoffBudgetView(item))
        }
        return views
    }

    static func sumHandoffBudgetView(_ view: HandoffBudgetView) throws -> Double {
        guard let parsedMinimum = Double(view.minimumText) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        guard let parsedMaximum = Double(view.maximum) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        return parsedMinimum + parsedMaximum
    }
}
