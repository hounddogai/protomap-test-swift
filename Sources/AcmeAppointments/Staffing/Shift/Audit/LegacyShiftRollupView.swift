import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a legacy shift rollup.
    final class LegacyShiftRollupView {
        var code: String
        var nameText: String
        var budget: String
        var encounterIDText: String
        var regionText: String
        var approvedText: String
        var activeText: String
        var ratio: String
        var copayText: String
        var score: String
        var statusLabel: String

        init(code: String, nameText: String, budget: String, encounterIDText: String, regionText: String, approvedText: String, activeText: String, ratio: String, copayText: String, score: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.budget = budget
            self.encounterIDText = encounterIDText
            self.regionText = regionText
            self.approvedText = approvedText
            self.activeText = activeText
            self.ratio = ratio
            self.copayText = copayText
            self.score = score
            self.statusLabel = statusLabel
        }
    }

    static func toLegacyShiftRollupView(_ item: LegacyShiftRollup) -> LegacyShiftRollupView {
        return LegacyShiftRollupView(
            code: Kit.Text.truncate(item.code, limit: 40),
            nameText: item.name,
            budget: String(format: "%.2f", item.budget),
            encounterIDText: item.encounterID,
            regionText: item.region,
            approvedText: "\(item.approved)",
            activeText: "\(item.active)",
            ratio: String(format: "%.2f", item.ratio),
            copayText: String(format: "%.2f", item.copay),
            score: String(format: "%.2f", item.score),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLegacyShiftRollupViews(_ items: [LegacyShiftRollup]) -> [LegacyShiftRollupView] {
        var views: [LegacyShiftRollupView] = []
        for item in items {
            views.append(toLegacyShiftRollupView(item))
        }
        return views
    }

    static func sumLegacyShiftRollupView(_ view: LegacyShiftRollupView) throws -> Double {
        guard let parsedBudget = Double(view.budget) else {
            throw Kit.Failure("parse budget: not a number")
        }
        guard let parsedRatio = Double(view.ratio) else {
            throw Kit.Failure("parse ratio: not a number")
        }
        guard let parsedCopay = Double(view.copayText) else {
            throw Kit.Failure("parse copay: not a number")
        }
        return parsedBudget + parsedRatio + parsedCopay
    }
}
