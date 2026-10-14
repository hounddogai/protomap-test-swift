import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a reference range rule.
    final class ReferenceRangeRuleView {
        var codeText: String
        var label: String
        var dosageMg: String
        var score: String
        var graceDays: String
        var country: String
        var patientRef: String
        var statusLabel: String

        init(codeText: String, label: String, dosageMg: String, score: String, graceDays: String, country: String, patientRef: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.dosageMg = dosageMg
            self.score = score
            self.graceDays = graceDays
            self.country = country
            self.patientRef = patientRef
            self.statusLabel = statusLabel
        }
    }

    static func toReferenceRangeRuleView(_ item: ReferenceRangeRule) -> ReferenceRangeRuleView {
        return ReferenceRangeRuleView(
            codeText: Kit.Text.truncate(item.code, limit: 40),
            label: Kit.Text.truncate(item.label, limit: 64),
            dosageMg: String(format: "%.2f", item.dosageMg),
            score: String(format: "%.2f", item.score),
            graceDays: String(item.graceDays),
            country: item.country,
            patientRef: item.patientRef,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toReferenceRangeRuleViews(_ items: [ReferenceRangeRule]) -> [ReferenceRangeRuleView] {
        var views: [ReferenceRangeRuleView] = []
        for item in items {
            views.append(toReferenceRangeRuleView(item))
        }
        return views
    }

    static func sumReferenceRangeRuleView(_ view: ReferenceRangeRuleView) throws -> Double {
        guard let parsedDosageMg = Double(view.dosageMg) else {
            throw Kit.Failure("parse dosage mg: not a number")
        }
        guard let parsedScore = Double(view.score) else {
            throw Kit.Failure("parse score: not a number")
        }
        guard let parsedGraceDays = Int(view.graceDays) else {
            throw Kit.Failure("parse grace days: not a number")
        }
        return parsedDosageMg + parsedScore + Double(parsedGraceDays)
    }
}
