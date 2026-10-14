import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a regional overtime plan.
    final class RegionalOvertimePlanView {
        var code: String
        var name: String
        var weight: String
        var procedureCodeText: String
        var externalRef: String
        var statusLabel: String

        init(code: String, name: String, weight: String, procedureCodeText: String, externalRef: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.weight = weight
            self.procedureCodeText = procedureCodeText
            self.externalRef = externalRef
            self.statusLabel = statusLabel
        }
    }

    static func toRegionalOvertimePlanView(_ item: RegionalOvertimePlan) -> RegionalOvertimePlanView {
        return RegionalOvertimePlanView(
            code: Kit.Text.truncate(item.code, limit: 80),
            name: item.name,
            weight: String(format: "%.2f", item.weight),
            procedureCodeText: item.procedureCode,
            externalRef: Kit.Text.truncate(item.externalRef, limit: 80),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRegionalOvertimePlanViews(_ items: [RegionalOvertimePlan]) -> [RegionalOvertimePlanView] {
        var views: [RegionalOvertimePlanView] = []
        for item in items {
            views.append(toRegionalOvertimePlanView(item))
        }
        return views
    }

    static func sumRegionalOvertimePlanView(_ view: RegionalOvertimePlanView) throws -> Double {
        guard let parsedWeight = Double(view.weight) else {
            throw Kit.Failure("parse weight: not a number")
        }
        return parsedWeight
    }
}
