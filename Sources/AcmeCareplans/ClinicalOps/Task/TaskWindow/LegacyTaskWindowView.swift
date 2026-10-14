import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a legacy task window.
    final class LegacyTaskWindowView {
        var code: String
        var title: String
        var checksum: String
        var country: String
        var acuityText: String
        var encounterIDText: String
        var phone: String
        var statusLabel: String

        init(code: String, title: String, checksum: String, country: String, acuityText: String, encounterIDText: String, phone: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.checksum = checksum
            self.country = country
            self.acuityText = acuityText
            self.encounterIDText = encounterIDText
            self.phone = phone
            self.statusLabel = statusLabel
        }
    }

    static func toLegacyTaskWindowView(_ item: LegacyTaskWindow) -> LegacyTaskWindowView {
        return LegacyTaskWindowView(
            code: item.code,
            title: Kit.Text.truncate(item.title, limit: 120),
            checksum: item.checksum,
            country: item.country,
            acuityText: String(item.acuity),
            encounterIDText: Kit.Text.truncate(item.encounterID, limit: 64),
            phone: Kit.Text.truncate(item.phone, limit: 40),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLegacyTaskWindowViews(_ items: [LegacyTaskWindow]) -> [LegacyTaskWindowView] {
        var views: [LegacyTaskWindowView] = []
        for item in items {
            views.append(toLegacyTaskWindowView(item))
        }
        return views
    }

    static func sumLegacyTaskWindowView(_ view: LegacyTaskWindowView) throws -> Double {
        guard let parsedAcuity = Int(view.acuityText) else {
            throw Kit.Failure("parse acuity: not a number")
        }
        return Double(parsedAcuity)
    }
}
