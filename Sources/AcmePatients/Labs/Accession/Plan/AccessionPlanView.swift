import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a accession plan.
    final class AccessionPlanView {
        var codeText: String
        var title: String
        var diagnosisCode: String
        var timezone: String
        var clinicianID: String
        var threshold: String
        var dosageMg: String
        var refillsText: String
        var statusLabel: String

        init(codeText: String, title: String, diagnosisCode: String, timezone: String, clinicianID: String, threshold: String, dosageMg: String, refillsText: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.diagnosisCode = diagnosisCode
            self.timezone = timezone
            self.clinicianID = clinicianID
            self.threshold = threshold
            self.dosageMg = dosageMg
            self.refillsText = refillsText
            self.statusLabel = statusLabel
        }
    }

    static func toAccessionPlanView(_ item: AccessionPlan) -> AccessionPlanView {
        return AccessionPlanView(
            codeText: item.code,
            title: item.title,
            diagnosisCode: item.diagnosisCode,
            timezone: Kit.Text.truncate(item.timezone, limit: 120),
            clinicianID: Kit.Text.truncate(item.clinicianID, limit: 40),
            threshold: String(format: "%.2f", item.threshold),
            dosageMg: String(format: "%.2f", item.dosageMg),
            refillsText: String(item.refills),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAccessionPlanViews(_ items: [AccessionPlan]) -> [AccessionPlanView] {
        var views: [AccessionPlanView] = []
        for item in items {
            views.append(toAccessionPlanView(item))
        }
        return views
    }

    static func sumAccessionPlanView(_ view: AccessionPlanView) throws -> Double {
        guard let parsedThreshold = Double(view.threshold) else {
            throw Kit.Failure("parse threshold: not a number")
        }
        guard let parsedDosageMg = Double(view.dosageMg) else {
            throw Kit.Failure("parse dosage mg: not a number")
        }
        guard let parsedRefills = Int(view.refillsText) else {
            throw Kit.Failure("parse refills: not a number")
        }
        return parsedThreshold + parsedDosageMg + Double(parsedRefills)
    }
}
