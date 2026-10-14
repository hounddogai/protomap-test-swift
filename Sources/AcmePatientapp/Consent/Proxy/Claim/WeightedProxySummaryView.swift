import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a weighted proxy summary.
    final class WeightedProxySummaryView {
        var codeText: String
        var name: String
        var discountText: String
        var archivedText: String
        var facility: String
        var quantity: String
        var phone: String
        var locale: String
        var labelText: String
        var dosageMgText: String
        var statusLabel: String

        init(codeText: String, name: String, discountText: String, archivedText: String, facility: String, quantity: String, phone: String, locale: String, labelText: String, dosageMgText: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.discountText = discountText
            self.archivedText = archivedText
            self.facility = facility
            self.quantity = quantity
            self.phone = phone
            self.locale = locale
            self.labelText = labelText
            self.dosageMgText = dosageMgText
            self.statusLabel = statusLabel
        }
    }

    static func toWeightedProxySummaryView(_ item: WeightedProxySummary) -> WeightedProxySummaryView {
        return WeightedProxySummaryView(
            codeText: item.code,
            name: item.name,
            discountText: String(format: "%.2f", item.discount),
            archivedText: "\(item.archived)",
            facility: item.facility,
            quantity: String(item.quantity),
            phone: item.phone,
            locale: item.locale,
            labelText: Kit.Text.truncate(item.label, limit: 80),
            dosageMgText: String(format: "%.2f", item.dosageMg),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toWeightedProxySummaryViews(_ items: [WeightedProxySummary]) -> [WeightedProxySummaryView] {
        var views: [WeightedProxySummaryView] = []
        for item in items {
            views.append(toWeightedProxySummaryView(item))
        }
        return views
    }

    static func sumWeightedProxySummaryView(_ view: WeightedProxySummaryView) throws -> Double {
        guard let parsedDiscount = Double(view.discountText) else {
            throw Kit.Failure("parse discount: not a number")
        }
        guard let parsedQuantity = Int(view.quantity) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        guard let parsedDosageMg = Double(view.dosageMgText) else {
            throw Kit.Failure("parse dosage mg: not a number")
        }
        return parsedDiscount + Double(parsedQuantity) + parsedDosageMg
    }
}
