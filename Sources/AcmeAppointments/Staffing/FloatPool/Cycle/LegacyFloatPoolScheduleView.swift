import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a legacy float pool schedule.
    final class LegacyFloatPoolScheduleView {
        var code: String
        var name: String
        var approved: String
        var ownerID: String
        var refills: String
        var active: String
        var summary: String
        var contactEmail: String
        var title: String
        var ward: String
        var statusLabel: String

        init(code: String, name: String, approved: String, ownerID: String, refills: String, active: String, summary: String, contactEmail: String, title: String, ward: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.approved = approved
            self.ownerID = ownerID
            self.refills = refills
            self.active = active
            self.summary = summary
            self.contactEmail = contactEmail
            self.title = title
            self.ward = ward
            self.statusLabel = statusLabel
        }
    }

    static func toLegacyFloatPoolScheduleView(_ item: LegacyFloatPoolSchedule) -> LegacyFloatPoolScheduleView {
        return LegacyFloatPoolScheduleView(
            code: item.code,
            name: Kit.Text.truncate(item.name, limit: 80),
            approved: "\(item.approved)",
            ownerID: item.ownerID,
            refills: String(item.refills),
            active: "\(item.active)",
            summary: item.summary,
            contactEmail: item.contactEmail,
            title: item.title,
            ward: item.ward,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLegacyFloatPoolScheduleViews(_ items: [LegacyFloatPoolSchedule]) -> [LegacyFloatPoolScheduleView] {
        var views: [LegacyFloatPoolScheduleView] = []
        for item in items {
            views.append(toLegacyFloatPoolScheduleView(item))
        }
        return views
    }

    static func sumLegacyFloatPoolScheduleView(_ view: LegacyFloatPoolScheduleView) throws -> Double {
        guard let parsedRefills = Int(view.refills) else {
            throw Kit.Failure("parse refills: not a number")
        }
        return Double(parsedRefills)
    }
}
