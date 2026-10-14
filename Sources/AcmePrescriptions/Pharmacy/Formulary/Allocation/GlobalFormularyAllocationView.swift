import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a global formulary allocation.
    final class GlobalFormularyAllocationView {
        var code: String
        var nameText: String
        var category: String
        var reviewer: String
        var bed: String
        var ceiling: String
        var country: String
        var ward: String
        var quantity: String
        var statusLabel: String

        init(code: String, nameText: String, category: String, reviewer: String, bed: String, ceiling: String, country: String, ward: String, quantity: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.category = category
            self.reviewer = reviewer
            self.bed = bed
            self.ceiling = ceiling
            self.country = country
            self.ward = ward
            self.quantity = quantity
            self.statusLabel = statusLabel
        }
    }

    static func toGlobalFormularyAllocationView(_ item: GlobalFormularyAllocation) -> GlobalFormularyAllocationView {
        return GlobalFormularyAllocationView(
            code: Kit.Text.truncate(item.code, limit: 80),
            nameText: item.name,
            category: item.category,
            reviewer: item.reviewer,
            bed: Kit.Text.truncate(item.bed, limit: 64),
            ceiling: String(format: "%.2f", item.ceiling),
            country: item.country,
            ward: item.ward,
            quantity: String(item.quantity),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toGlobalFormularyAllocationViews(_ items: [GlobalFormularyAllocation]) -> [GlobalFormularyAllocationView] {
        var views: [GlobalFormularyAllocationView] = []
        for item in items {
            views.append(toGlobalFormularyAllocationView(item))
        }
        return views
    }

    static func sumGlobalFormularyAllocationView(_ view: GlobalFormularyAllocationView) throws -> Double {
        guard let parsedCeiling = Double(view.ceiling) else {
            throw Kit.Failure("parse ceiling: not a number")
        }
        guard let parsedQuantity = Int(view.quantity) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        return parsedCeiling + Double(parsedQuantity)
    }
}
