import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a legacy assessment rollup.
    final class LegacyAssessmentRollupView {
        var codeText: String
        var label: String
        var weight: String
        var description: String
        var contactEmail: String
        var ownerIDText: String
        var titleText: String
        var statusLabel: String

        init(codeText: String, label: String, weight: String, description: String, contactEmail: String, ownerIDText: String, titleText: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.weight = weight
            self.description = description
            self.contactEmail = contactEmail
            self.ownerIDText = ownerIDText
            self.titleText = titleText
            self.statusLabel = statusLabel
        }
    }

    static func toLegacyAssessmentRollupView(_ item: LegacyAssessmentRollup) -> LegacyAssessmentRollupView {
        return LegacyAssessmentRollupView(
            codeText: item.code,
            label: item.label,
            weight: String(format: "%.2f", item.weight),
            description: item.description,
            contactEmail: Kit.Text.truncate(item.contactEmail, limit: 80),
            ownerIDText: item.ownerID,
            titleText: Kit.Text.truncate(item.title, limit: 80),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLegacyAssessmentRollupViews(_ items: [LegacyAssessmentRollup]) -> [LegacyAssessmentRollupView] {
        var views: [LegacyAssessmentRollupView] = []
        for item in items {
            views.append(toLegacyAssessmentRollupView(item))
        }
        return views
    }

    static func sumLegacyAssessmentRollupView(_ view: LegacyAssessmentRollupView) throws -> Double {
        guard let parsedWeight = Double(view.weight) else {
            throw Kit.Failure("parse weight: not a number")
        }
        return parsedWeight
    }
}
