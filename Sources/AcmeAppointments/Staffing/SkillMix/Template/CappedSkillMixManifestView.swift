import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a capped skill mix manifest.
    final class CappedSkillMixManifestView {
        var codeText: String
        var label: String
        var summary: String
        var quantity: String
        var costText: String
        var dosageMg: String
        var sourceText: String
        var budget: String
        var phoneText: String
        var clinicianIDText: String
        var notesText: String
        var statusLabel: String

        init(codeText: String, label: String, summary: String, quantity: String, costText: String, dosageMg: String, sourceText: String, budget: String, phoneText: String, clinicianIDText: String, notesText: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.summary = summary
            self.quantity = quantity
            self.costText = costText
            self.dosageMg = dosageMg
            self.sourceText = sourceText
            self.budget = budget
            self.phoneText = phoneText
            self.clinicianIDText = clinicianIDText
            self.notesText = notesText
            self.statusLabel = statusLabel
        }
    }

    static func toCappedSkillMixManifestView(_ item: CappedSkillMixManifest) -> CappedSkillMixManifestView {
        return CappedSkillMixManifestView(
            codeText: item.code,
            label: item.label,
            summary: Kit.Text.truncate(item.summary, limit: 40),
            quantity: String(item.quantity),
            costText: String(format: "%.2f", item.cost),
            dosageMg: String(format: "%.2f", item.dosageMg),
            sourceText: Kit.Text.truncate(item.source, limit: 64),
            budget: String(format: "%.2f", item.budget),
            phoneText: item.phone,
            clinicianIDText: item.clinicianID,
            notesText: item.notes,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCappedSkillMixManifestViews(_ items: [CappedSkillMixManifest]) -> [CappedSkillMixManifestView] {
        var views: [CappedSkillMixManifestView] = []
        for item in items {
            views.append(toCappedSkillMixManifestView(item))
        }
        return views
    }

    static func sumCappedSkillMixManifestView(_ view: CappedSkillMixManifestView) throws -> Double {
        guard let parsedQuantity = Int(view.quantity) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        guard let parsedCost = Double(view.costText) else {
            throw Kit.Failure("parse cost: not a number")
        }
        guard let parsedDosageMg = Double(view.dosageMg) else {
            throw Kit.Failure("parse dosage mg: not a number")
        }
        return Double(parsedQuantity) + parsedCost + parsedDosageMg
    }
}
