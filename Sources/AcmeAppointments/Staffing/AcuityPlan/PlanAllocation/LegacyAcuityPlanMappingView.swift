import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a legacy acuity plan mapping.
    final class LegacyAcuityPlanMappingView {
        var code: String
        var nameText: String
        var payer: String
        var score: String
        var facilityText: String
        var quantity: String
        var limitText: String
        var margin: String
        var statusLabel: String

        init(code: String, nameText: String, payer: String, score: String, facilityText: String, quantity: String, limitText: String, margin: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.payer = payer
            self.score = score
            self.facilityText = facilityText
            self.quantity = quantity
            self.limitText = limitText
            self.margin = margin
            self.statusLabel = statusLabel
        }
    }

    static func toLegacyAcuityPlanMappingView(_ item: LegacyAcuityPlanMapping) -> LegacyAcuityPlanMappingView {
        return LegacyAcuityPlanMappingView(
            code: item.code,
            nameText: item.name,
            payer: Kit.Text.truncate(item.payer, limit: 120),
            score: String(format: "%.2f", item.score),
            facilityText: item.facility,
            quantity: String(item.quantity),
            limitText: String(item.limit),
            margin: String(format: "%.2f", item.margin),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLegacyAcuityPlanMappingViews(_ items: [LegacyAcuityPlanMapping]) -> [LegacyAcuityPlanMappingView] {
        var views: [LegacyAcuityPlanMappingView] = []
        for item in items {
            views.append(toLegacyAcuityPlanMappingView(item))
        }
        return views
    }

    static func sumLegacyAcuityPlanMappingView(_ view: LegacyAcuityPlanMappingView) throws -> Double {
        guard let parsedScore = Double(view.score) else {
            throw Kit.Failure("parse score: not a number")
        }
        guard let parsedQuantity = Int(view.quantity) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        guard let parsedLimit = Int(view.limitText) else {
            throw Kit.Failure("parse limit: not a number")
        }
        return parsedScore + Double(parsedQuantity) + Double(parsedLimit)
    }
}
