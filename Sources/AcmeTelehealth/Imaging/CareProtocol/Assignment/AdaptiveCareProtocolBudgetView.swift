import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a adaptive care protocol budget.
    final class AdaptiveCareProtocolBudgetView {
        var code: String
        var label: String
        var ratioText: String
        var minimum: String
        var windowDaysText: String
        var unit: String
        var checksum: String
        var allergy: String
        var versionText: String
        var statusLabel: String

        init(code: String, label: String, ratioText: String, minimum: String, windowDaysText: String, unit: String, checksum: String, allergy: String, versionText: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.ratioText = ratioText
            self.minimum = minimum
            self.windowDaysText = windowDaysText
            self.unit = unit
            self.checksum = checksum
            self.allergy = allergy
            self.versionText = versionText
            self.statusLabel = statusLabel
        }
    }

    static func toAdaptiveCareProtocolBudgetView(_ item: AdaptiveCareProtocolBudget) -> AdaptiveCareProtocolBudgetView {
        return AdaptiveCareProtocolBudgetView(
            code: item.code,
            label: item.label,
            ratioText: String(format: "%.2f", item.ratio),
            minimum: String(format: "%.2f", item.minimum),
            windowDaysText: String(item.windowDays),
            unit: item.unit,
            checksum: item.checksum,
            allergy: Kit.Text.truncate(item.allergy, limit: 80),
            versionText: String(item.version),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAdaptiveCareProtocolBudgetViews(_ items: [AdaptiveCareProtocolBudget]) -> [AdaptiveCareProtocolBudgetView] {
        var views: [AdaptiveCareProtocolBudgetView] = []
        for item in items {
            views.append(toAdaptiveCareProtocolBudgetView(item))
        }
        return views
    }

    static func sumAdaptiveCareProtocolBudgetView(_ view: AdaptiveCareProtocolBudgetView) throws -> Double {
        guard let parsedRatio = Double(view.ratioText) else {
            throw Kit.Failure("parse ratio: not a number")
        }
        guard let parsedMinimum = Double(view.minimum) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        guard let parsedWindowDays = Int(view.windowDaysText) else {
            throw Kit.Failure("parse window days: not a number")
        }
        return parsedRatio + parsedMinimum + Double(parsedWindowDays)
    }
}
