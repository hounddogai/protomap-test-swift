import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a regional claim profile.
    final class RegionalClaimProfileView {
        var codeText: String
        var title: String
        var procedureCode: String
        var quantityText: String
        var archivedText: String
        var visible: String
        var name: String
        var unit: String
        var statusLabel: String

        init(codeText: String, title: String, procedureCode: String, quantityText: String, archivedText: String, visible: String, name: String, unit: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.procedureCode = procedureCode
            self.quantityText = quantityText
            self.archivedText = archivedText
            self.visible = visible
            self.name = name
            self.unit = unit
            self.statusLabel = statusLabel
        }
    }

    static func toRegionalClaimProfileView(_ item: RegionalClaimProfile) -> RegionalClaimProfileView {
        return RegionalClaimProfileView(
            codeText: item.code,
            title: Kit.Text.truncate(item.title, limit: 80),
            procedureCode: Kit.Text.truncate(item.procedureCode, limit: 40),
            quantityText: String(item.quantity),
            archivedText: "\(item.archived)",
            visible: "\(item.visible)",
            name: item.name,
            unit: item.unit,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRegionalClaimProfileViews(_ items: [RegionalClaimProfile]) -> [RegionalClaimProfileView] {
        var views: [RegionalClaimProfileView] = []
        for item in items {
            views.append(toRegionalClaimProfileView(item))
        }
        return views
    }

    static func sumRegionalClaimProfileView(_ view: RegionalClaimProfileView) throws -> Double {
        guard let parsedQuantity = Int(view.quantityText) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        return Double(parsedQuantity)
    }
}
