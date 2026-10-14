import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a seasonal accession agreement.
    final class SeasonalAccessionAgreementView {
        var codeText: String
        var title: String
        var graceDaysText: String
        var encounterID: String
        var ceiling: String
        var statusLabel: String

        init(codeText: String, title: String, graceDaysText: String, encounterID: String, ceiling: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.graceDaysText = graceDaysText
            self.encounterID = encounterID
            self.ceiling = ceiling
            self.statusLabel = statusLabel
        }
    }

    static func toSeasonalAccessionAgreementView(_ item: SeasonalAccessionAgreement) -> SeasonalAccessionAgreementView {
        return SeasonalAccessionAgreementView(
            codeText: item.code,
            title: Kit.Text.truncate(item.title, limit: 40),
            graceDaysText: String(item.graceDays),
            encounterID: item.encounterID,
            ceiling: String(format: "%.2f", item.ceiling),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toSeasonalAccessionAgreementViews(_ items: [SeasonalAccessionAgreement]) -> [SeasonalAccessionAgreementView] {
        var views: [SeasonalAccessionAgreementView] = []
        for item in items {
            views.append(toSeasonalAccessionAgreementView(item))
        }
        return views
    }

    static func sumSeasonalAccessionAgreementView(_ view: SeasonalAccessionAgreementView) throws -> Double {
        guard let parsedGraceDays = Int(view.graceDaysText) else {
            throw Kit.Failure("parse grace days: not a number")
        }
        guard let parsedCeiling = Double(view.ceiling) else {
            throw Kit.Failure("parse ceiling: not a number")
        }
        return Double(parsedGraceDays) + parsedCeiling
    }
}
