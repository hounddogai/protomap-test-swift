import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a manual statement tier.
    final class ManualStatementTierView {
        var codeText: String
        var label: String
        var thresholdText: String
        var name: String
        var countryText: String
        var durationMinutes: String
        var versionText: String
        var statusLabel: String

        init(codeText: String, label: String, thresholdText: String, name: String, countryText: String, durationMinutes: String, versionText: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.thresholdText = thresholdText
            self.name = name
            self.countryText = countryText
            self.durationMinutes = durationMinutes
            self.versionText = versionText
            self.statusLabel = statusLabel
        }
    }

    static func toManualStatementTierView(_ item: ManualStatementTier) -> ManualStatementTierView {
        return ManualStatementTierView(
            codeText: item.code,
            label: Kit.Text.truncate(item.label, limit: 40),
            thresholdText: String(format: "%.2f", item.threshold),
            name: item.name,
            countryText: Kit.Text.truncate(item.country, limit: 120),
            durationMinutes: String(item.durationMinutes),
            versionText: String(item.version),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toManualStatementTierViews(_ items: [ManualStatementTier]) -> [ManualStatementTierView] {
        var views: [ManualStatementTierView] = []
        for item in items {
            views.append(toManualStatementTierView(item))
        }
        return views
    }

    static func sumManualStatementTierView(_ view: ManualStatementTierView) throws -> Double {
        guard let parsedThreshold = Double(view.thresholdText) else {
            throw Kit.Failure("parse threshold: not a number")
        }
        guard let parsedDurationMinutes = Int(view.durationMinutes) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        guard let parsedVersion = Int(view.versionText) else {
            throw Kit.Failure("parse version: not a number")
        }
        return parsedThreshold + Double(parsedDurationMinutes) + Double(parsedVersion)
    }
}
