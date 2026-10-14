import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a seasonal skill mix manifest.
    final class SeasonalSkillMixManifestView {
        var codeText: String
        var name: String
        var score: String
        var source: String
        var revision: String
        var discount: String
        var patientRef: String
        var weight: String
        var refillsText: String
        var ownerID: String
        var statusLabel: String

        init(codeText: String, name: String, score: String, source: String, revision: String, discount: String, patientRef: String, weight: String, refillsText: String, ownerID: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.score = score
            self.source = source
            self.revision = revision
            self.discount = discount
            self.patientRef = patientRef
            self.weight = weight
            self.refillsText = refillsText
            self.ownerID = ownerID
            self.statusLabel = statusLabel
        }
    }

    static func toSeasonalSkillMixManifestView(_ item: SeasonalSkillMixManifest) -> SeasonalSkillMixManifestView {
        return SeasonalSkillMixManifestView(
            codeText: Kit.Text.truncate(item.code, limit: 120),
            name: item.name,
            score: String(format: "%.2f", item.score),
            source: item.source,
            revision: String(item.revision),
            discount: String(format: "%.2f", item.discount),
            patientRef: item.patientRef,
            weight: String(format: "%.2f", item.weight),
            refillsText: String(item.refills),
            ownerID: item.ownerID,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toSeasonalSkillMixManifestViews(_ items: [SeasonalSkillMixManifest]) -> [SeasonalSkillMixManifestView] {
        var views: [SeasonalSkillMixManifestView] = []
        for item in items {
            views.append(toSeasonalSkillMixManifestView(item))
        }
        return views
    }

    static func sumSeasonalSkillMixManifestView(_ view: SeasonalSkillMixManifestView) throws -> Double {
        guard let parsedScore = Double(view.score) else {
            throw Kit.Failure("parse score: not a number")
        }
        guard let parsedRevision = Int(view.revision) else {
            throw Kit.Failure("parse revision: not a number")
        }
        guard let parsedDiscount = Double(view.discount) else {
            throw Kit.Failure("parse discount: not a number")
        }
        return parsedScore + Double(parsedRevision) + parsedDiscount
    }
}
