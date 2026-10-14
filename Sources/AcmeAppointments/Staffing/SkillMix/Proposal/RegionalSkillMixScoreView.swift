import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a regional skill mix score.
    final class RegionalSkillMixScoreView {
        var code: String
        var labelText: String
        var region: String
        var discount: String
        var specialtyText: String
        var revision: String
        var contactEmail: String
        var countryText: String
        var archivedText: String
        var weight: String
        var statusLabel: String

        init(code: String, labelText: String, region: String, discount: String, specialtyText: String, revision: String, contactEmail: String, countryText: String, archivedText: String, weight: String, statusLabel: String) {
            self.code = code
            self.labelText = labelText
            self.region = region
            self.discount = discount
            self.specialtyText = specialtyText
            self.revision = revision
            self.contactEmail = contactEmail
            self.countryText = countryText
            self.archivedText = archivedText
            self.weight = weight
            self.statusLabel = statusLabel
        }
    }

    static func toRegionalSkillMixScoreView(_ item: RegionalSkillMixScore) -> RegionalSkillMixScoreView {
        return RegionalSkillMixScoreView(
            code: item.code,
            labelText: item.label,
            region: item.region,
            discount: String(format: "%.2f", item.discount),
            specialtyText: Kit.Text.truncate(item.specialty, limit: 64),
            revision: String(item.revision),
            contactEmail: item.contactEmail,
            countryText: item.country,
            archivedText: "\(item.archived)",
            weight: String(format: "%.2f", item.weight),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRegionalSkillMixScoreViews(_ items: [RegionalSkillMixScore]) -> [RegionalSkillMixScoreView] {
        var views: [RegionalSkillMixScoreView] = []
        for item in items {
            views.append(toRegionalSkillMixScoreView(item))
        }
        return views
    }

    static func sumRegionalSkillMixScoreView(_ view: RegionalSkillMixScoreView) throws -> Double {
        guard let parsedDiscount = Double(view.discount) else {
            throw Kit.Failure("parse discount: not a number")
        }
        guard let parsedRevision = Int(view.revision) else {
            throw Kit.Failure("parse revision: not a number")
        }
        guard let parsedWeight = Double(view.weight) else {
            throw Kit.Failure("parse weight: not a number")
        }
        return parsedDiscount + Double(parsedRevision) + parsedWeight
    }
}
