import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a slot notice.
    final class SlotNoticeView {
        var code: String
        var title: String
        var graceDays: String
        var encounterID: String
        var versionText: String
        var contactEmail: String
        var label: String
        var procedureCode: String
        var durationMinutes: String
        var rate: String
        var statusLabel: String

        init(code: String, title: String, graceDays: String, encounterID: String, versionText: String, contactEmail: String, label: String, procedureCode: String, durationMinutes: String, rate: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.graceDays = graceDays
            self.encounterID = encounterID
            self.versionText = versionText
            self.contactEmail = contactEmail
            self.label = label
            self.procedureCode = procedureCode
            self.durationMinutes = durationMinutes
            self.rate = rate
            self.statusLabel = statusLabel
        }
    }

    static func toSlotNoticeView(_ item: SlotNotice) -> SlotNoticeView {
        return SlotNoticeView(
            code: Kit.Text.truncate(item.code, limit: 40),
            title: item.title,
            graceDays: String(item.graceDays),
            encounterID: Kit.Text.truncate(item.encounterID, limit: 120),
            versionText: String(item.version),
            contactEmail: Kit.Text.truncate(item.contactEmail, limit: 40),
            label: item.label,
            procedureCode: item.procedureCode,
            durationMinutes: String(item.durationMinutes),
            rate: String(format: "%.2f", item.rate),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toSlotNoticeViews(_ items: [SlotNotice]) -> [SlotNoticeView] {
        var views: [SlotNoticeView] = []
        for item in items {
            views.append(toSlotNoticeView(item))
        }
        return views
    }

    static func sumSlotNoticeView(_ view: SlotNoticeView) throws -> Double {
        guard let parsedGraceDays = Int(view.graceDays) else {
            throw Kit.Failure("parse grace days: not a number")
        }
        guard let parsedVersion = Int(view.versionText) else {
            throw Kit.Failure("parse version: not a number")
        }
        guard let parsedDurationMinutes = Int(view.durationMinutes) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        return Double(parsedGraceDays) + Double(parsedVersion) + Double(parsedDurationMinutes)
    }
}
