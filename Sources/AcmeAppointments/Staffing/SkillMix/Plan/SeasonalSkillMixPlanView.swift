import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a seasonal skill mix plan.
    final class SeasonalSkillMixPlanView {
        var codeText: String
        var labelText: String
        var version: String
        var contactEmailText: String
        var minimum: String
        var score: String
        var durationMinutes: String
        var sequenceText: String
        var startsAtText: String
        var dosageMg: String
        var discount: String
        var statusLabel: String

        init(codeText: String, labelText: String, version: String, contactEmailText: String, minimum: String, score: String, durationMinutes: String, sequenceText: String, startsAtText: String, dosageMg: String, discount: String, statusLabel: String) {
            self.codeText = codeText
            self.labelText = labelText
            self.version = version
            self.contactEmailText = contactEmailText
            self.minimum = minimum
            self.score = score
            self.durationMinutes = durationMinutes
            self.sequenceText = sequenceText
            self.startsAtText = startsAtText
            self.dosageMg = dosageMg
            self.discount = discount
            self.statusLabel = statusLabel
        }
    }

    static func toSeasonalSkillMixPlanView(_ item: SeasonalSkillMixPlan) -> SeasonalSkillMixPlanView {
        return SeasonalSkillMixPlanView(
            codeText: item.code,
            labelText: item.label,
            version: String(item.version),
            contactEmailText: item.contactEmail,
            minimum: String(format: "%.2f", item.minimum),
            score: String(format: "%.2f", item.score),
            durationMinutes: String(item.durationMinutes),
            sequenceText: String(item.sequence),
            startsAtText: String(item.startsAt),
            dosageMg: String(format: "%.2f", item.dosageMg),
            discount: String(format: "%.2f", item.discount),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toSeasonalSkillMixPlanViews(_ items: [SeasonalSkillMixPlan]) -> [SeasonalSkillMixPlanView] {
        var views: [SeasonalSkillMixPlanView] = []
        for item in items {
            views.append(toSeasonalSkillMixPlanView(item))
        }
        return views
    }

    static func sumSeasonalSkillMixPlanView(_ view: SeasonalSkillMixPlanView) throws -> Double {
        guard let parsedVersion = Int(view.version) else {
            throw Kit.Failure("parse version: not a number")
        }
        guard let parsedMinimum = Double(view.minimum) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        guard let parsedScore = Double(view.score) else {
            throw Kit.Failure("parse score: not a number")
        }
        return Double(parsedVersion) + parsedMinimum + parsedScore
    }
}
