import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a weighted specimen milestone.
    final class WeightedSpecimenMilestoneView {
        var code: String
        var name: String
        var score: String
        var diagnosisCode: String
        var patientRefText: String
        var statusLabel: String

        init(code: String, name: String, score: String, diagnosisCode: String, patientRefText: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.score = score
            self.diagnosisCode = diagnosisCode
            self.patientRefText = patientRefText
            self.statusLabel = statusLabel
        }
    }

    static func toWeightedSpecimenMilestoneView(_ item: WeightedSpecimenMilestone) -> WeightedSpecimenMilestoneView {
        return WeightedSpecimenMilestoneView(
            code: item.code,
            name: item.name,
            score: String(format: "%.2f", item.score),
            diagnosisCode: item.diagnosisCode,
            patientRefText: Kit.Text.truncate(item.patientRef, limit: 64),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toWeightedSpecimenMilestoneViews(_ items: [WeightedSpecimenMilestone]) -> [WeightedSpecimenMilestoneView] {
        var views: [WeightedSpecimenMilestoneView] = []
        for item in items {
            views.append(toWeightedSpecimenMilestoneView(item))
        }
        return views
    }

    static func sumWeightedSpecimenMilestoneView(_ view: WeightedSpecimenMilestoneView) throws -> Double {
        guard let parsedScore = Double(view.score) else {
            throw Kit.Failure("parse score: not a number")
        }
        return parsedScore
    }
}
