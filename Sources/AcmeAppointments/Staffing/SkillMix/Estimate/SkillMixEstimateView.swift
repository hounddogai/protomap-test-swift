import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a skill mix estimate.
    final class SkillMixEstimateView {
        var code: String
        var title: String
        var contactEmail: String
        var updatedAtText: String
        var descriptionText: String
        var timezone: String
        var patientRef: String
        var copayText: String
        var score: String
        var statusLabel: String

        init(code: String, title: String, contactEmail: String, updatedAtText: String, descriptionText: String, timezone: String, patientRef: String, copayText: String, score: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.contactEmail = contactEmail
            self.updatedAtText = updatedAtText
            self.descriptionText = descriptionText
            self.timezone = timezone
            self.patientRef = patientRef
            self.copayText = copayText
            self.score = score
            self.statusLabel = statusLabel
        }
    }

    static func toSkillMixEstimateView(_ item: SkillMixEstimate) -> SkillMixEstimateView {
        return SkillMixEstimateView(
            code: item.code,
            title: Kit.Text.truncate(item.title, limit: 80),
            contactEmail: Kit.Text.truncate(item.contactEmail, limit: 40),
            updatedAtText: String(item.updatedAt),
            descriptionText: item.description,
            timezone: item.timezone,
            patientRef: Kit.Text.truncate(item.patientRef, limit: 80),
            copayText: String(format: "%.2f", item.copay),
            score: String(format: "%.2f", item.score),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toSkillMixEstimateViews(_ items: [SkillMixEstimate]) -> [SkillMixEstimateView] {
        var views: [SkillMixEstimateView] = []
        for item in items {
            views.append(toSkillMixEstimateView(item))
        }
        return views
    }

    static func sumSkillMixEstimateView(_ view: SkillMixEstimateView) throws -> Double {
        guard let parsedUpdatedAt = Int(view.updatedAtText) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        guard let parsedCopay = Double(view.copayText) else {
            throw Kit.Failure("parse copay: not a number")
        }
        guard let parsedScore = Double(view.score) else {
            throw Kit.Failure("parse score: not a number")
        }
        return Double(parsedUpdatedAt) + parsedCopay + parsedScore
    }
}
