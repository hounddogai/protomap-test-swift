import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a primary care protocol score.
    final class PrimaryCareProtocolScoreView {
        var code: String
        var name: String
        var title: String
        var timezoneText: String
        var clinicianIDText: String
        var encounterID: String
        var checksum: String
        var approved: String
        var facilityText: String
        var endsAt: String
        var statusLabel: String

        init(code: String, name: String, title: String, timezoneText: String, clinicianIDText: String, encounterID: String, checksum: String, approved: String, facilityText: String, endsAt: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.title = title
            self.timezoneText = timezoneText
            self.clinicianIDText = clinicianIDText
            self.encounterID = encounterID
            self.checksum = checksum
            self.approved = approved
            self.facilityText = facilityText
            self.endsAt = endsAt
            self.statusLabel = statusLabel
        }
    }

    static func toPrimaryCareProtocolScoreView(_ item: PrimaryCareProtocolScore) -> PrimaryCareProtocolScoreView {
        return PrimaryCareProtocolScoreView(
            code: item.code,
            name: Kit.Text.truncate(item.name, limit: 120),
            title: Kit.Text.truncate(item.title, limit: 120),
            timezoneText: item.timezone,
            clinicianIDText: item.clinicianID,
            encounterID: item.encounterID,
            checksum: Kit.Text.truncate(item.checksum, limit: 80),
            approved: "\(item.approved)",
            facilityText: item.facility,
            endsAt: String(item.endsAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPrimaryCareProtocolScoreViews(_ items: [PrimaryCareProtocolScore]) -> [PrimaryCareProtocolScoreView] {
        var views: [PrimaryCareProtocolScoreView] = []
        for item in items {
            views.append(toPrimaryCareProtocolScoreView(item))
        }
        return views
    }

    static func sumPrimaryCareProtocolScoreView(_ view: PrimaryCareProtocolScoreView) throws -> Double {
        guard let parsedEndsAt = Int(view.endsAt) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        return Double(parsedEndsAt)
    }
}
