import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a global alert draft.
    final class GlobalAlertDraftView {
        var codeText: String
        var name: String
        var specialtyText: String
        var costText: String
        var graceDays: String
        var approved: String
        var ward: String
        var ceiling: String
        var minimum: String
        var weight: String
        var statusLabel: String

        init(codeText: String, name: String, specialtyText: String, costText: String, graceDays: String, approved: String, ward: String, ceiling: String, minimum: String, weight: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.specialtyText = specialtyText
            self.costText = costText
            self.graceDays = graceDays
            self.approved = approved
            self.ward = ward
            self.ceiling = ceiling
            self.minimum = minimum
            self.weight = weight
            self.statusLabel = statusLabel
        }
    }

    static func toGlobalAlertDraftView(_ item: GlobalAlertDraft) -> GlobalAlertDraftView {
        return GlobalAlertDraftView(
            codeText: item.code,
            name: item.name,
            specialtyText: item.specialty,
            costText: String(format: "%.2f", item.cost),
            graceDays: String(item.graceDays),
            approved: "\(item.approved)",
            ward: Kit.Text.truncate(item.ward, limit: 120),
            ceiling: String(format: "%.2f", item.ceiling),
            minimum: String(format: "%.2f", item.minimum),
            weight: String(format: "%.2f", item.weight),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toGlobalAlertDraftViews(_ items: [GlobalAlertDraft]) -> [GlobalAlertDraftView] {
        var views: [GlobalAlertDraftView] = []
        for item in items {
            views.append(toGlobalAlertDraftView(item))
        }
        return views
    }

    static func sumGlobalAlertDraftView(_ view: GlobalAlertDraftView) throws -> Double {
        guard let parsedCost = Double(view.costText) else {
            throw Kit.Failure("parse cost: not a number")
        }
        guard let parsedGraceDays = Int(view.graceDays) else {
            throw Kit.Failure("parse grace days: not a number")
        }
        guard let parsedCeiling = Double(view.ceiling) else {
            throw Kit.Failure("parse ceiling: not a number")
        }
        return parsedCost + Double(parsedGraceDays) + parsedCeiling
    }
}
