import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a panel batch.
    final class PanelBatchView {
        var code: String
        var label: String
        var unit: String
        var countryText: String
        var notesText: String
        var segment: String
        var attempts: String
        var dosageMg: String
        var bed: String
        var statusLabel: String

        init(code: String, label: String, unit: String, countryText: String, notesText: String, segment: String, attempts: String, dosageMg: String, bed: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.unit = unit
            self.countryText = countryText
            self.notesText = notesText
            self.segment = segment
            self.attempts = attempts
            self.dosageMg = dosageMg
            self.bed = bed
            self.statusLabel = statusLabel
        }
    }

    static func toPanelBatchView(_ item: PanelBatch) -> PanelBatchView {
        return PanelBatchView(
            code: item.code,
            label: Kit.Text.truncate(item.label, limit: 120),
            unit: item.unit,
            countryText: item.country,
            notesText: item.notes,
            segment: item.segment,
            attempts: String(item.attempts),
            dosageMg: String(format: "%.2f", item.dosageMg),
            bed: item.bed,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPanelBatchViews(_ items: [PanelBatch]) -> [PanelBatchView] {
        var views: [PanelBatchView] = []
        for item in items {
            views.append(toPanelBatchView(item))
        }
        return views
    }

    static func sumPanelBatchView(_ view: PanelBatchView) throws -> Double {
        guard let parsedAttempts = Int(view.attempts) else {
            throw Kit.Failure("parse attempts: not a number")
        }
        guard let parsedDosageMg = Double(view.dosageMg) else {
            throw Kit.Failure("parse dosage mg: not a number")
        }
        return Double(parsedAttempts) + parsedDosageMg
    }
}
