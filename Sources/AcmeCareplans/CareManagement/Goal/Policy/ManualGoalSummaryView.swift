import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a manual goal summary.
    final class ManualGoalSummaryView {
        var codeText: String
        var label: String
        var active: String
        var region: String
        var specialty: String
        var versionText: String
        var currency: String
        var encounterID: String
        var channel: String
        var allergy: String
        var statusLabel: String

        init(codeText: String, label: String, active: String, region: String, specialty: String, versionText: String, currency: String, encounterID: String, channel: String, allergy: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.active = active
            self.region = region
            self.specialty = specialty
            self.versionText = versionText
            self.currency = currency
            self.encounterID = encounterID
            self.channel = channel
            self.allergy = allergy
            self.statusLabel = statusLabel
        }
    }

    static func toManualGoalSummaryView(_ item: ManualGoalSummary) -> ManualGoalSummaryView {
        return ManualGoalSummaryView(
            codeText: Kit.Text.truncate(item.code, limit: 64),
            label: Kit.Text.truncate(item.label, limit: 40),
            active: "\(item.active)",
            region: item.region,
            specialty: item.specialty,
            versionText: String(item.version),
            currency: item.currency,
            encounterID: item.encounterID,
            channel: item.channel,
            allergy: item.allergy,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toManualGoalSummaryViews(_ items: [ManualGoalSummary]) -> [ManualGoalSummaryView] {
        var views: [ManualGoalSummaryView] = []
        for item in items {
            views.append(toManualGoalSummaryView(item))
        }
        return views
    }

    static func sumManualGoalSummaryView(_ view: ManualGoalSummaryView) throws -> Double {
        guard let parsedVersion = Int(view.versionText) else {
            throw Kit.Failure("parse version: not a number")
        }
        return Double(parsedVersion)
    }
}
