import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a legacy skill mix milestone.
    final class LegacySkillMixMilestoneView {
        var code: String
        var titleText: String
        var weight: String
        var locale: String
        var encounterID: String
        var specialty: String
        var revision: String
        var archived: String
        var checksum: String
        var windowDays: String
        var approvedText: String
        var statusLabel: String

        init(code: String, titleText: String, weight: String, locale: String, encounterID: String, specialty: String, revision: String, archived: String, checksum: String, windowDays: String, approvedText: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.weight = weight
            self.locale = locale
            self.encounterID = encounterID
            self.specialty = specialty
            self.revision = revision
            self.archived = archived
            self.checksum = checksum
            self.windowDays = windowDays
            self.approvedText = approvedText
            self.statusLabel = statusLabel
        }
    }

    static func toLegacySkillMixMilestoneView(_ item: LegacySkillMixMilestone) -> LegacySkillMixMilestoneView {
        return LegacySkillMixMilestoneView(
            code: item.code,
            titleText: item.title,
            weight: String(format: "%.2f", item.weight),
            locale: item.locale,
            encounterID: item.encounterID,
            specialty: item.specialty,
            revision: String(item.revision),
            archived: "\(item.archived)",
            checksum: item.checksum,
            windowDays: String(item.windowDays),
            approvedText: "\(item.approved)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLegacySkillMixMilestoneViews(_ items: [LegacySkillMixMilestone]) -> [LegacySkillMixMilestoneView] {
        var views: [LegacySkillMixMilestoneView] = []
        for item in items {
            views.append(toLegacySkillMixMilestoneView(item))
        }
        return views
    }

    static func sumLegacySkillMixMilestoneView(_ view: LegacySkillMixMilestoneView) throws -> Double {
        guard let parsedWeight = Double(view.weight) else {
            throw Kit.Failure("parse weight: not a number")
        }
        guard let parsedRevision = Int(view.revision) else {
            throw Kit.Failure("parse revision: not a number")
        }
        guard let parsedWindowDays = Int(view.windowDays) else {
            throw Kit.Failure("parse window days: not a number")
        }
        return parsedWeight + Double(parsedRevision) + Double(parsedWindowDays)
    }
}
