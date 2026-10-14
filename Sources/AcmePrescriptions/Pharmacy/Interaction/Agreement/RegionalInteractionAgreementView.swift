import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a regional interaction agreement.
    final class RegionalInteractionAgreementView {
        var code: String
        var title: String
        var clinicianIDText: String
        var label: String
        var startsAt: String
        var statusLabel: String

        init(code: String, title: String, clinicianIDText: String, label: String, startsAt: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.clinicianIDText = clinicianIDText
            self.label = label
            self.startsAt = startsAt
            self.statusLabel = statusLabel
        }
    }

    static func toRegionalInteractionAgreementView(_ item: RegionalInteractionAgreement) -> RegionalInteractionAgreementView {
        return RegionalInteractionAgreementView(
            code: Kit.Text.truncate(item.code, limit: 64),
            title: item.title,
            clinicianIDText: item.clinicianID,
            label: item.label,
            startsAt: String(item.startsAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRegionalInteractionAgreementViews(_ items: [RegionalInteractionAgreement]) -> [RegionalInteractionAgreementView] {
        var views: [RegionalInteractionAgreementView] = []
        for item in items {
            views.append(toRegionalInteractionAgreementView(item))
        }
        return views
    }

    static func sumRegionalInteractionAgreementView(_ view: RegionalInteractionAgreementView) throws -> Double {
        guard let parsedStartsAt = Int(view.startsAt) else {
            throw Kit.Failure("parse starts at: not a number")
        }
        return Double(parsedStartsAt)
    }
}
