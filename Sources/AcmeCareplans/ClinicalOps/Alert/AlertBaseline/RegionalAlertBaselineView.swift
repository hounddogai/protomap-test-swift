import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a regional alert baseline.
    final class RegionalAlertBaselineView {
        var codeText: String
        var label: String
        var active: String
        var procedureCode: String
        var country: String
        var endsAt: String
        var encounterID: String
        var statusLabel: String

        init(codeText: String, label: String, active: String, procedureCode: String, country: String, endsAt: String, encounterID: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.active = active
            self.procedureCode = procedureCode
            self.country = country
            self.endsAt = endsAt
            self.encounterID = encounterID
            self.statusLabel = statusLabel
        }
    }

    static func toRegionalAlertBaselineView(_ item: RegionalAlertBaseline) -> RegionalAlertBaselineView {
        return RegionalAlertBaselineView(
            codeText: Kit.Text.truncate(item.code, limit: 40),
            label: item.label,
            active: "\(item.active)",
            procedureCode: Kit.Text.truncate(item.procedureCode, limit: 64),
            country: Kit.Text.truncate(item.country, limit: 120),
            endsAt: String(item.endsAt),
            encounterID: item.encounterID,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRegionalAlertBaselineViews(_ items: [RegionalAlertBaseline]) -> [RegionalAlertBaselineView] {
        var views: [RegionalAlertBaselineView] = []
        for item in items {
            views.append(toRegionalAlertBaselineView(item))
        }
        return views
    }

    static func sumRegionalAlertBaselineView(_ view: RegionalAlertBaselineView) throws -> Double {
        guard let parsedEndsAt = Int(view.endsAt) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        return Double(parsedEndsAt)
    }
}
