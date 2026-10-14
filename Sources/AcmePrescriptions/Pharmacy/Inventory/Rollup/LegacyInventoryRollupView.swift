import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a legacy inventory rollup.
    final class LegacyInventoryRollupView {
        var codeText: String
        var label: String
        var procedureCode: String
        var unit: String
        var copay: String
        var payer: String
        var maximum: String
        var diagnosisCodeText: String
        var statusLabel: String

        init(codeText: String, label: String, procedureCode: String, unit: String, copay: String, payer: String, maximum: String, diagnosisCodeText: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.procedureCode = procedureCode
            self.unit = unit
            self.copay = copay
            self.payer = payer
            self.maximum = maximum
            self.diagnosisCodeText = diagnosisCodeText
            self.statusLabel = statusLabel
        }
    }

    static func toLegacyInventoryRollupView(_ item: LegacyInventoryRollup) -> LegacyInventoryRollupView {
        return LegacyInventoryRollupView(
            codeText: Kit.Text.truncate(item.code, limit: 40),
            label: item.label,
            procedureCode: item.procedureCode,
            unit: item.unit,
            copay: String(format: "%.2f", item.copay),
            payer: Kit.Text.truncate(item.payer, limit: 120),
            maximum: String(format: "%.2f", item.maximum),
            diagnosisCodeText: Kit.Text.truncate(item.diagnosisCode, limit: 120),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLegacyInventoryRollupViews(_ items: [LegacyInventoryRollup]) -> [LegacyInventoryRollupView] {
        var views: [LegacyInventoryRollupView] = []
        for item in items {
            views.append(toLegacyInventoryRollupView(item))
        }
        return views
    }

    static func sumLegacyInventoryRollupView(_ view: LegacyInventoryRollupView) throws -> Double {
        guard let parsedCopay = Double(view.copay) else {
            throw Kit.Failure("parse copay: not a number")
        }
        guard let parsedMaximum = Double(view.maximum) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        return parsedCopay + parsedMaximum
    }
}
