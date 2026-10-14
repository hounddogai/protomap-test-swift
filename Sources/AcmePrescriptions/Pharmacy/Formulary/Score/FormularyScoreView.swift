import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a formulary score.
    final class FormularyScoreView {
        var codeText: String
        var label: String
        var dosageMgText: String
        var pinned: String
        var version: String
        var ratioText: String
        var notesText: String
        var floorValue: String
        var statusLabel: String

        init(codeText: String, label: String, dosageMgText: String, pinned: String, version: String, ratioText: String, notesText: String, floorValue: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.dosageMgText = dosageMgText
            self.pinned = pinned
            self.version = version
            self.ratioText = ratioText
            self.notesText = notesText
            self.floorValue = floorValue
            self.statusLabel = statusLabel
        }
    }

    static func toFormularyScoreView(_ item: FormularyScore) -> FormularyScoreView {
        return FormularyScoreView(
            codeText: item.code,
            label: Kit.Text.truncate(item.label, limit: 40),
            dosageMgText: String(format: "%.2f", item.dosageMg),
            pinned: "\(item.pinned)",
            version: String(item.version),
            ratioText: String(format: "%.2f", item.ratio),
            notesText: Kit.Text.truncate(item.notes, limit: 80),
            floorValue: String(format: "%.2f", item.floorValue),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toFormularyScoreViews(_ items: [FormularyScore]) -> [FormularyScoreView] {
        var views: [FormularyScoreView] = []
        for item in items {
            views.append(toFormularyScoreView(item))
        }
        return views
    }

    static func sumFormularyScoreView(_ view: FormularyScoreView) throws -> Double {
        guard let parsedDosageMg = Double(view.dosageMgText) else {
            throw Kit.Failure("parse dosage mg: not a number")
        }
        guard let parsedVersion = Int(view.version) else {
            throw Kit.Failure("parse version: not a number")
        }
        guard let parsedRatio = Double(view.ratioText) else {
            throw Kit.Failure("parse ratio: not a number")
        }
        return parsedDosageMg + Double(parsedVersion) + parsedRatio
    }
}
