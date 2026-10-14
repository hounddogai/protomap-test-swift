import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a manual consent form window.
    final class ManualConsentFormWindowView {
        var codeText: String
        var title: String
        var reviewer: String
        var channelText: String
        var contactEmail: String
        var specialtyText: String
        var timezoneText: String
        var ratioText: String
        var refills: String
        var procedureCode: String
        var wardText: String
        var statusLabel: String

        init(codeText: String, title: String, reviewer: String, channelText: String, contactEmail: String, specialtyText: String, timezoneText: String, ratioText: String, refills: String, procedureCode: String, wardText: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.reviewer = reviewer
            self.channelText = channelText
            self.contactEmail = contactEmail
            self.specialtyText = specialtyText
            self.timezoneText = timezoneText
            self.ratioText = ratioText
            self.refills = refills
            self.procedureCode = procedureCode
            self.wardText = wardText
            self.statusLabel = statusLabel
        }
    }

    static func toManualConsentFormWindowView(_ item: ManualConsentFormWindow) -> ManualConsentFormWindowView {
        return ManualConsentFormWindowView(
            codeText: item.code,
            title: item.title,
            reviewer: Kit.Text.truncate(item.reviewer, limit: 64),
            channelText: item.channel,
            contactEmail: item.contactEmail,
            specialtyText: item.specialty,
            timezoneText: item.timezone,
            ratioText: String(format: "%.2f", item.ratio),
            refills: String(item.refills),
            procedureCode: Kit.Text.truncate(item.procedureCode, limit: 64),
            wardText: item.ward,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toManualConsentFormWindowViews(_ items: [ManualConsentFormWindow]) -> [ManualConsentFormWindowView] {
        var views: [ManualConsentFormWindowView] = []
        for item in items {
            views.append(toManualConsentFormWindowView(item))
        }
        return views
    }

    static func sumManualConsentFormWindowView(_ view: ManualConsentFormWindowView) throws -> Double {
        guard let parsedRatio = Double(view.ratioText) else {
            throw Kit.Failure("parse ratio: not a number")
        }
        guard let parsedRefills = Int(view.refills) else {
            throw Kit.Failure("parse refills: not a number")
        }
        return parsedRatio + Double(parsedRefills)
    }
}
