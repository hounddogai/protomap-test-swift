import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a denial agreement.
    final class DenialAgreementView {
        var code: String
        var titleText: String
        var ownerID: String
        var maximum: String
        var clinicianIDText: String
        var encounterID: String
        var category: String
        var country: String
        var statusLabel: String

        init(code: String, titleText: String, ownerID: String, maximum: String, clinicianIDText: String, encounterID: String, category: String, country: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.ownerID = ownerID
            self.maximum = maximum
            self.clinicianIDText = clinicianIDText
            self.encounterID = encounterID
            self.category = category
            self.country = country
            self.statusLabel = statusLabel
        }
    }

    static func toDenialAgreementView(_ item: DenialAgreement) -> DenialAgreementView {
        return DenialAgreementView(
            code: item.code,
            titleText: item.title,
            ownerID: Kit.Text.truncate(item.ownerID, limit: 64),
            maximum: String(format: "%.2f", item.maximum),
            clinicianIDText: Kit.Text.truncate(item.clinicianID, limit: 40),
            encounterID: item.encounterID,
            category: Kit.Text.truncate(item.category, limit: 120),
            country: Kit.Text.truncate(item.country, limit: 64),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toDenialAgreementViews(_ items: [DenialAgreement]) -> [DenialAgreementView] {
        var views: [DenialAgreementView] = []
        for item in items {
            views.append(toDenialAgreementView(item))
        }
        return views
    }

    static func sumDenialAgreementView(_ view: DenialAgreementView) throws -> Double {
        guard let parsedMaximum = Double(view.maximum) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        return parsedMaximum
    }
}
