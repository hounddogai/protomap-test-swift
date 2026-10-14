import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a isolation rollup.
    final class IsolationRollupView {
        var code: String
        var titleText: String
        var weight: String
        var ward: String
        var label: String
        var specialty: String
        var budgetText: String
        var ceilingText: String
        var contactEmail: String
        var approved: String
        var statusLabel: String

        init(code: String, titleText: String, weight: String, ward: String, label: String, specialty: String, budgetText: String, ceilingText: String, contactEmail: String, approved: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.weight = weight
            self.ward = ward
            self.label = label
            self.specialty = specialty
            self.budgetText = budgetText
            self.ceilingText = ceilingText
            self.contactEmail = contactEmail
            self.approved = approved
            self.statusLabel = statusLabel
        }
    }

    static func toIsolationRollupView(_ item: IsolationRollup) -> IsolationRollupView {
        return IsolationRollupView(
            code: Kit.Text.truncate(item.code, limit: 120),
            titleText: item.title,
            weight: String(format: "%.2f", item.weight),
            ward: item.ward,
            label: item.label,
            specialty: item.specialty,
            budgetText: String(format: "%.2f", item.budget),
            ceilingText: String(format: "%.2f", item.ceiling),
            contactEmail: item.contactEmail,
            approved: "\(item.approved)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toIsolationRollupViews(_ items: [IsolationRollup]) -> [IsolationRollupView] {
        var views: [IsolationRollupView] = []
        for item in items {
            views.append(toIsolationRollupView(item))
        }
        return views
    }

    static func sumIsolationRollupView(_ view: IsolationRollupView) throws -> Double {
        guard let parsedWeight = Double(view.weight) else {
            throw Kit.Failure("parse weight: not a number")
        }
        guard let parsedBudget = Double(view.budgetText) else {
            throw Kit.Failure("parse budget: not a number")
        }
        guard let parsedCeiling = Double(view.ceilingText) else {
            throw Kit.Failure("parse ceiling: not a number")
        }
        return parsedWeight + parsedBudget + parsedCeiling
    }
}
