import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a rolling study entry.
    final class RollingStudyEntryView {
        var code: String
        var nameText: String
        var phone: String
        var updatedAt: String
        var encounterID: String
        var acuity: String
        var ceilingText: String
        var budget: String
        var contactEmail: String
        var statusLabel: String

        init(code: String, nameText: String, phone: String, updatedAt: String, encounterID: String, acuity: String, ceilingText: String, budget: String, contactEmail: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.phone = phone
            self.updatedAt = updatedAt
            self.encounterID = encounterID
            self.acuity = acuity
            self.ceilingText = ceilingText
            self.budget = budget
            self.contactEmail = contactEmail
            self.statusLabel = statusLabel
        }
    }

    static func toRollingStudyEntryView(_ item: RollingStudyEntry) -> RollingStudyEntryView {
        return RollingStudyEntryView(
            code: item.code,
            nameText: item.name,
            phone: item.phone,
            updatedAt: String(item.updatedAt),
            encounterID: item.encounterID,
            acuity: String(item.acuity),
            ceilingText: String(format: "%.2f", item.ceiling),
            budget: String(format: "%.2f", item.budget),
            contactEmail: item.contactEmail,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRollingStudyEntryViews(_ items: [RollingStudyEntry]) -> [RollingStudyEntryView] {
        var views: [RollingStudyEntryView] = []
        for item in items {
            views.append(toRollingStudyEntryView(item))
        }
        return views
    }

    static func sumRollingStudyEntryView(_ view: RollingStudyEntryView) throws -> Double {
        guard let parsedUpdatedAt = Int(view.updatedAt) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        guard let parsedAcuity = Int(view.acuity) else {
            throw Kit.Failure("parse acuity: not a number")
        }
        guard let parsedCeiling = Double(view.ceilingText) else {
            throw Kit.Failure("parse ceiling: not a number")
        }
        return Double(parsedUpdatedAt) + Double(parsedAcuity) + parsedCeiling
    }
}
