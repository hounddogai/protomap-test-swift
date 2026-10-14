import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a global disclosure rule.
    final class GlobalDisclosureRuleView {
        var code: String
        var label: String
        var createdAt: String
        var currencyText: String
        var dosageMgText: String
        var floorValue: String
        var statusLabel: String

        init(code: String, label: String, createdAt: String, currencyText: String, dosageMgText: String, floorValue: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.createdAt = createdAt
            self.currencyText = currencyText
            self.dosageMgText = dosageMgText
            self.floorValue = floorValue
            self.statusLabel = statusLabel
        }
    }

    static func toGlobalDisclosureRuleView(_ item: GlobalDisclosureRule) -> GlobalDisclosureRuleView {
        return GlobalDisclosureRuleView(
            code: Kit.Text.truncate(item.code, limit: 40),
            label: item.label,
            createdAt: String(item.createdAt),
            currencyText: item.currency,
            dosageMgText: String(format: "%.2f", item.dosageMg),
            floorValue: String(format: "%.2f", item.floorValue),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toGlobalDisclosureRuleViews(_ items: [GlobalDisclosureRule]) -> [GlobalDisclosureRuleView] {
        var views: [GlobalDisclosureRuleView] = []
        for item in items {
            views.append(toGlobalDisclosureRuleView(item))
        }
        return views
    }

    static func sumGlobalDisclosureRuleView(_ view: GlobalDisclosureRuleView) throws -> Double {
        guard let parsedCreatedAt = Int(view.createdAt) else {
            throw Kit.Failure("parse created at: not a number")
        }
        guard let parsedDosageMg = Double(view.dosageMgText) else {
            throw Kit.Failure("parse dosage mg: not a number")
        }
        guard let parsedFloorValue = Double(view.floorValue) else {
            throw Kit.Failure("parse floor value: not a number")
        }
        return Double(parsedCreatedAt) + parsedDosageMg + parsedFloorValue
    }
}
