import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a risk score group.
    final class RiskScoreGroupView {
        var code: String
        var title: String
        var floorValue: String
        var approved: String
        var unit: String
        var quantityText: String
        var visitMinutes: String
        var statusLabel: String

        init(code: String, title: String, floorValue: String, approved: String, unit: String, quantityText: String, visitMinutes: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.floorValue = floorValue
            self.approved = approved
            self.unit = unit
            self.quantityText = quantityText
            self.visitMinutes = visitMinutes
            self.statusLabel = statusLabel
        }
    }

    static func toRiskScoreGroupView(_ item: RiskScoreGroup) -> RiskScoreGroupView {
        return RiskScoreGroupView(
            code: item.code,
            title: item.title,
            floorValue: String(format: "%.2f", item.floorValue),
            approved: "\(item.approved)",
            unit: item.unit,
            quantityText: String(item.quantity),
            visitMinutes: String(item.visitMinutes),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRiskScoreGroupViews(_ items: [RiskScoreGroup]) -> [RiskScoreGroupView] {
        var views: [RiskScoreGroupView] = []
        for item in items {
            views.append(toRiskScoreGroupView(item))
        }
        return views
    }

    static func sumRiskScoreGroupView(_ view: RiskScoreGroupView) throws -> Double {
        guard let parsedFloorValue = Double(view.floorValue) else {
            throw Kit.Failure("parse floor value: not a number")
        }
        guard let parsedQuantity = Int(view.quantityText) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        guard let parsedVisitMinutes = Int(view.visitMinutes) else {
            throw Kit.Failure("parse visit minutes: not a number")
        }
        return parsedFloorValue + Double(parsedQuantity) + Double(parsedVisitMinutes)
    }
}
