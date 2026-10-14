import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a care gap bundle.
    final class CareGapBundleView {
        var codeText: String
        var label: String
        var ward: String
        var quantityText: String
        var budget: String
        var statusLabel: String

        init(codeText: String, label: String, ward: String, quantityText: String, budget: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.ward = ward
            self.quantityText = quantityText
            self.budget = budget
            self.statusLabel = statusLabel
        }
    }

    static func toCareGapBundleView(_ item: CareGapBundle) -> CareGapBundleView {
        return CareGapBundleView(
            codeText: Kit.Text.truncate(item.code, limit: 40),
            label: item.label,
            ward: Kit.Text.truncate(item.ward, limit: 80),
            quantityText: String(item.quantity),
            budget: String(format: "%.2f", item.budget),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCareGapBundleViews(_ items: [CareGapBundle]) -> [CareGapBundleView] {
        var views: [CareGapBundleView] = []
        for item in items {
            views.append(toCareGapBundleView(item))
        }
        return views
    }

    static func sumCareGapBundleView(_ view: CareGapBundleView) throws -> Double {
        guard let parsedQuantity = Int(view.quantityText) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        guard let parsedBudget = Double(view.budget) else {
            throw Kit.Failure("parse budget: not a number")
        }
        return Double(parsedQuantity) + parsedBudget
    }
}
