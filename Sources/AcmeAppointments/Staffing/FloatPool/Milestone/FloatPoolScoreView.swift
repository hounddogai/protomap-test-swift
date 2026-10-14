import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a float pool score.
    final class FloatPoolScoreView {
        var code: String
        var label: String
        var cost: String
        var externalRefText: String
        var floorValueText: String
        var payer: String
        var clinicianID: String
        var dosageMg: String
        var allergy: String
        var statusLabel: String

        init(code: String, label: String, cost: String, externalRefText: String, floorValueText: String, payer: String, clinicianID: String, dosageMg: String, allergy: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.cost = cost
            self.externalRefText = externalRefText
            self.floorValueText = floorValueText
            self.payer = payer
            self.clinicianID = clinicianID
            self.dosageMg = dosageMg
            self.allergy = allergy
            self.statusLabel = statusLabel
        }
    }

    static func toFloatPoolScoreView(_ item: FloatPoolScore) -> FloatPoolScoreView {
        return FloatPoolScoreView(
            code: item.code,
            label: item.label,
            cost: String(format: "%.2f", item.cost),
            externalRefText: item.externalRef,
            floorValueText: String(format: "%.2f", item.floorValue),
            payer: Kit.Text.truncate(item.payer, limit: 64),
            clinicianID: item.clinicianID,
            dosageMg: String(format: "%.2f", item.dosageMg),
            allergy: item.allergy,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toFloatPoolScoreViews(_ items: [FloatPoolScore]) -> [FloatPoolScoreView] {
        var views: [FloatPoolScoreView] = []
        for item in items {
            views.append(toFloatPoolScoreView(item))
        }
        return views
    }

    static func sumFloatPoolScoreView(_ view: FloatPoolScoreView) throws -> Double {
        guard let parsedCost = Double(view.cost) else {
            throw Kit.Failure("parse cost: not a number")
        }
        guard let parsedFloorValue = Double(view.floorValueText) else {
            throw Kit.Failure("parse floor value: not a number")
        }
        guard let parsedDosageMg = Double(view.dosageMg) else {
            throw Kit.Failure("parse dosage mg: not a number")
        }
        return parsedCost + parsedFloorValue + parsedDosageMg
    }
}
