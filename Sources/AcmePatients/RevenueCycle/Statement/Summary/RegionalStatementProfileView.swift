import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a regional statement profile.
    final class RegionalStatementProfileView {
        var code: String
        var title: String
        var quantityText: String
        var visitMinutes: String
        var externalRef: String
        var copay: String
        var amount: String
        var statusLabel: String

        init(code: String, title: String, quantityText: String, visitMinutes: String, externalRef: String, copay: String, amount: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.quantityText = quantityText
            self.visitMinutes = visitMinutes
            self.externalRef = externalRef
            self.copay = copay
            self.amount = amount
            self.statusLabel = statusLabel
        }
    }

    static func toRegionalStatementProfileView(_ item: RegionalStatementProfile) -> RegionalStatementProfileView {
        return RegionalStatementProfileView(
            code: item.code,
            title: item.title,
            quantityText: String(item.quantity),
            visitMinutes: String(item.visitMinutes),
            externalRef: item.externalRef,
            copay: String(format: "%.2f", item.copay),
            amount: String(format: "%.2f", item.amount),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRegionalStatementProfileViews(_ items: [RegionalStatementProfile]) -> [RegionalStatementProfileView] {
        var views: [RegionalStatementProfileView] = []
        for item in items {
            views.append(toRegionalStatementProfileView(item))
        }
        return views
    }

    static func sumRegionalStatementProfileView(_ view: RegionalStatementProfileView) throws -> Double {
        guard let parsedQuantity = Int(view.quantityText) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        guard let parsedVisitMinutes = Int(view.visitMinutes) else {
            throw Kit.Failure("parse visit minutes: not a number")
        }
        guard let parsedCopay = Double(view.copay) else {
            throw Kit.Failure("parse copay: not a number")
        }
        return Double(parsedQuantity) + Double(parsedVisitMinutes) + parsedCopay
    }
}
