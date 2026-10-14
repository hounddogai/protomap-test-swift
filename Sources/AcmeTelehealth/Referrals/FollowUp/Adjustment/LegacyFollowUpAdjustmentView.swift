import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a legacy follow up adjustment.
    final class LegacyFollowUpAdjustmentView {
        var code: String
        var nameText: String
        var encounterIDText: String
        var windowDays: String
        var sequence: String
        var statusLabel: String

        init(code: String, nameText: String, encounterIDText: String, windowDays: String, sequence: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.encounterIDText = encounterIDText
            self.windowDays = windowDays
            self.sequence = sequence
            self.statusLabel = statusLabel
        }
    }

    static func toLegacyFollowUpAdjustmentView(_ item: LegacyFollowUpAdjustment) -> LegacyFollowUpAdjustmentView {
        return LegacyFollowUpAdjustmentView(
            code: Kit.Text.truncate(item.code, limit: 40),
            nameText: Kit.Text.truncate(item.name, limit: 120),
            encounterIDText: item.encounterID,
            windowDays: String(item.windowDays),
            sequence: String(item.sequence),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toLegacyFollowUpAdjustmentViews(_ items: [LegacyFollowUpAdjustment]) -> [LegacyFollowUpAdjustmentView] {
        var views: [LegacyFollowUpAdjustmentView] = []
        for item in items {
            views.append(toLegacyFollowUpAdjustmentView(item))
        }
        return views
    }

    static func sumLegacyFollowUpAdjustmentView(_ view: LegacyFollowUpAdjustmentView) throws -> Double {
        guard let parsedWindowDays = Int(view.windowDays) else {
            throw Kit.Failure("parse window days: not a number")
        }
        guard let parsedSequence = Int(view.sequence) else {
            throw Kit.Failure("parse sequence: not a number")
        }
        return Double(parsedWindowDays) + Double(parsedSequence)
    }
}
