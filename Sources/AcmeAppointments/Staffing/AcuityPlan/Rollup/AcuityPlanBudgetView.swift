import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a acuity plan budget.
    final class AcuityPlanBudgetView {
        var code: String
        var name: String
        var patientRef: String
        var threshold: String
        var phone: String
        var expiresAtText: String
        var statusLabel: String

        init(code: String, name: String, patientRef: String, threshold: String, phone: String, expiresAtText: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.patientRef = patientRef
            self.threshold = threshold
            self.phone = phone
            self.expiresAtText = expiresAtText
            self.statusLabel = statusLabel
        }
    }

    static func toAcuityPlanBudgetView(_ item: AcuityPlanBudget) -> AcuityPlanBudgetView {
        return AcuityPlanBudgetView(
            code: Kit.Text.truncate(item.code, limit: 120),
            name: item.name,
            patientRef: item.patientRef,
            threshold: String(format: "%.2f", item.threshold),
            phone: item.phone,
            expiresAtText: String(item.expiresAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAcuityPlanBudgetViews(_ items: [AcuityPlanBudget]) -> [AcuityPlanBudgetView] {
        var views: [AcuityPlanBudgetView] = []
        for item in items {
            views.append(toAcuityPlanBudgetView(item))
        }
        return views
    }

    static func sumAcuityPlanBudgetView(_ view: AcuityPlanBudgetView) throws -> Double {
        guard let parsedThreshold = Double(view.threshold) else {
            throw Kit.Failure("parse threshold: not a number")
        }
        guard let parsedExpiresAt = Int(view.expiresAtText) else {
            throw Kit.Failure("parse expires at: not a number")
        }
        return parsedThreshold + Double(parsedExpiresAt)
    }
}
