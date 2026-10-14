import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a consent form notice.
    final class ConsentFormNoticeView {
        var code: String
        var nameText: String
        var floorValue: String
        var windowDays: String
        var refills: String
        var approved: String
        var statusLabel: String

        init(code: String, nameText: String, floorValue: String, windowDays: String, refills: String, approved: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.floorValue = floorValue
            self.windowDays = windowDays
            self.refills = refills
            self.approved = approved
            self.statusLabel = statusLabel
        }
    }

    static func toConsentFormNoticeView(_ item: ConsentFormNotice) -> ConsentFormNoticeView {
        return ConsentFormNoticeView(
            code: item.code,
            nameText: Kit.Text.truncate(item.name, limit: 120),
            floorValue: String(format: "%.2f", item.floorValue),
            windowDays: String(item.windowDays),
            refills: String(item.refills),
            approved: "\(item.approved)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toConsentFormNoticeViews(_ items: [ConsentFormNotice]) -> [ConsentFormNoticeView] {
        var views: [ConsentFormNoticeView] = []
        for item in items {
            views.append(toConsentFormNoticeView(item))
        }
        return views
    }

    static func sumConsentFormNoticeView(_ view: ConsentFormNoticeView) throws -> Double {
        guard let parsedFloorValue = Double(view.floorValue) else {
            throw Kit.Failure("parse floor value: not a number")
        }
        guard let parsedWindowDays = Int(view.windowDays) else {
            throw Kit.Failure("parse window days: not a number")
        }
        guard let parsedRefills = Int(view.refills) else {
            throw Kit.Failure("parse refills: not a number")
        }
        return parsedFloorValue + Double(parsedWindowDays) + Double(parsedRefills)
    }
}
