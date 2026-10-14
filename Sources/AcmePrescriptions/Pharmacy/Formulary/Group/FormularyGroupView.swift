import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a formulary group.
    final class FormularyGroupView {
        var code: String
        var name: String
        var endsAt: String
        var score: String
        var allergy: String
        var budgetText: String
        var checksum: String
        var diagnosisCode: String
        var summary: String
        var statusLabel: String

        init(code: String, name: String, endsAt: String, score: String, allergy: String, budgetText: String, checksum: String, diagnosisCode: String, summary: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.endsAt = endsAt
            self.score = score
            self.allergy = allergy
            self.budgetText = budgetText
            self.checksum = checksum
            self.diagnosisCode = diagnosisCode
            self.summary = summary
            self.statusLabel = statusLabel
        }
    }

    static func toFormularyGroupView(_ item: FormularyGroup) -> FormularyGroupView {
        return FormularyGroupView(
            code: Kit.Text.truncate(item.code, limit: 120),
            name: item.name,
            endsAt: String(item.endsAt),
            score: String(format: "%.2f", item.score),
            allergy: item.allergy,
            budgetText: String(format: "%.2f", item.budget),
            checksum: Kit.Text.truncate(item.checksum, limit: 40),
            diagnosisCode: item.diagnosisCode,
            summary: item.summary,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toFormularyGroupViews(_ items: [FormularyGroup]) -> [FormularyGroupView] {
        var views: [FormularyGroupView] = []
        for item in items {
            views.append(toFormularyGroupView(item))
        }
        return views
    }

    static func sumFormularyGroupView(_ view: FormularyGroupView) throws -> Double {
        guard let parsedEndsAt = Int(view.endsAt) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        guard let parsedScore = Double(view.score) else {
            throw Kit.Failure("parse score: not a number")
        }
        guard let parsedBudget = Double(view.budgetText) else {
            throw Kit.Failure("parse budget: not a number")
        }
        return Double(parsedEndsAt) + parsedScore + parsedBudget
    }
}
