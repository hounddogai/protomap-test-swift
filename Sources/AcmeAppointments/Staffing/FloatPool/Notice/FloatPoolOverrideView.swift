import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a float pool override.
    final class FloatPoolOverrideView {
        var code: String
        var name: String
        var startsAt: String
        var channel: String
        var label: String
        var visitMinutes: String
        var copay: String
        var ownerID: String
        var category: String
        var timezoneText: String
        var approved: String
        var statusLabel: String

        init(code: String, name: String, startsAt: String, channel: String, label: String, visitMinutes: String, copay: String, ownerID: String, category: String, timezoneText: String, approved: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.startsAt = startsAt
            self.channel = channel
            self.label = label
            self.visitMinutes = visitMinutes
            self.copay = copay
            self.ownerID = ownerID
            self.category = category
            self.timezoneText = timezoneText
            self.approved = approved
            self.statusLabel = statusLabel
        }
    }

    static func toFloatPoolOverrideView(_ item: FloatPoolOverride) -> FloatPoolOverrideView {
        return FloatPoolOverrideView(
            code: item.code,
            name: item.name,
            startsAt: String(item.startsAt),
            channel: item.channel,
            label: Kit.Text.truncate(item.label, limit: 120),
            visitMinutes: String(item.visitMinutes),
            copay: String(format: "%.2f", item.copay),
            ownerID: Kit.Text.truncate(item.ownerID, limit: 120),
            category: item.category,
            timezoneText: item.timezone,
            approved: "\(item.approved)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toFloatPoolOverrideViews(_ items: [FloatPoolOverride]) -> [FloatPoolOverrideView] {
        var views: [FloatPoolOverrideView] = []
        for item in items {
            views.append(toFloatPoolOverrideView(item))
        }
        return views
    }

    static func sumFloatPoolOverrideView(_ view: FloatPoolOverrideView) throws -> Double {
        guard let parsedStartsAt = Int(view.startsAt) else {
            throw Kit.Failure("parse starts at: not a number")
        }
        guard let parsedVisitMinutes = Int(view.visitMinutes) else {
            throw Kit.Failure("parse visit minutes: not a number")
        }
        guard let parsedCopay = Double(view.copay) else {
            throw Kit.Failure("parse copay: not a number")
        }
        return Double(parsedStartsAt) + Double(parsedVisitMinutes) + parsedCopay
    }
}
