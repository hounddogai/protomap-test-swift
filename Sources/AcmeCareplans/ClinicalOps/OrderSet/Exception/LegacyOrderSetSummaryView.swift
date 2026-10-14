import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a legacy order set summary.
    final class LegacyOrderSetSummaryView {
        var codeText: String
        var nameText: String
        var country: String
        var notes: String
        var dosageMgText: String
        var unit: String
        var statusLabel: String

        init(codeText: String, nameText: String, country: String, notes: String, dosageMgText: String, unit: String, statusLabel: String) {
            self.codeText = codeText
            self.nameText = nameText
            self.country = country
            self.notes = notes
            self.dosageMgText = dosageMgText
            self.unit = unit
            self.statusLabel = statusLabel
        }
    }

    static func toLegacyOrderSetSummaryView(_ item: LegacyOrderSetSummary) -> LegacyOrderSetSummaryView {
        return LegacyOrderSetSummaryView(
            codeText: Kit.Text.truncate(item.code, limit: 80),
            nameText: Kit.Text.truncate(item.name, limit: 64),
            country: Kit.Text.truncate(item.country, limit: 80),
            notes: Kit.Text.truncate(item.notes, limit: 64),
            dosageMgText: String(format: "%.2f", item.dosageMg),
            unit: item.unit,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLegacyOrderSetSummaryViews(_ items: [LegacyOrderSetSummary]) -> [LegacyOrderSetSummaryView] {
        var views: [LegacyOrderSetSummaryView] = []
        for item in items {
            views.append(toLegacyOrderSetSummaryView(item))
        }
        return views
    }

    static func sumLegacyOrderSetSummaryView(_ view: LegacyOrderSetSummaryView) throws -> Double {
        guard let parsedDosageMg = Double(view.dosageMgText) else {
            throw Kit.Failure("parse dosage mg: not a number")
        }
        return parsedDosageMg
    }
}
