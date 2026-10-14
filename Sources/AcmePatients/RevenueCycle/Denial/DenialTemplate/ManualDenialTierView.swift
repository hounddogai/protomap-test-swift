import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a manual denial tier.
    final class ManualDenialTierView {
        var code: String
        var labelText: String
        var reviewer: String
        var retries: String
        var windowDays: String
        var ceilingText: String
        var titleText: String
        var description: String
        var clinicianID: String
        var procedureCodeText: String
        var statusLabel: String

        init(code: String, labelText: String, reviewer: String, retries: String, windowDays: String, ceilingText: String, titleText: String, description: String, clinicianID: String, procedureCodeText: String, statusLabel: String) {
            self.code = code
            self.labelText = labelText
            self.reviewer = reviewer
            self.retries = retries
            self.windowDays = windowDays
            self.ceilingText = ceilingText
            self.titleText = titleText
            self.description = description
            self.clinicianID = clinicianID
            self.procedureCodeText = procedureCodeText
            self.statusLabel = statusLabel
        }
    }

    static func toManualDenialTierView(_ item: ManualDenialTier) -> ManualDenialTierView {
        return ManualDenialTierView(
            code: Kit.Text.truncate(item.code, limit: 120),
            labelText: item.label,
            reviewer: Kit.Text.truncate(item.reviewer, limit: 80),
            retries: String(item.retries),
            windowDays: String(item.windowDays),
            ceilingText: String(format: "%.2f", item.ceiling),
            titleText: item.title,
            description: Kit.Text.truncate(item.description, limit: 64),
            clinicianID: item.clinicianID,
            procedureCodeText: item.procedureCode,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toManualDenialTierViews(_ items: [ManualDenialTier]) -> [ManualDenialTierView] {
        var views: [ManualDenialTierView] = []
        for item in items {
            views.append(toManualDenialTierView(item))
        }
        return views
    }

    static func sumManualDenialTierView(_ view: ManualDenialTierView) throws -> Double {
        guard let parsedRetries = Int(view.retries) else {
            throw Kit.Failure("parse retries: not a number")
        }
        guard let parsedWindowDays = Int(view.windowDays) else {
            throw Kit.Failure("parse window days: not a number")
        }
        guard let parsedCeiling = Double(view.ceilingText) else {
            throw Kit.Failure("parse ceiling: not a number")
        }
        return Double(parsedRetries) + Double(parsedWindowDays) + parsedCeiling
    }
}
