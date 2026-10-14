import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a manual claim milestone.
    final class ManualClaimMilestoneView {
        var code: String
        var name: String
        var active: String
        var windowDays: String
        var batchSizeText: String
        var statusLabel: String

        init(code: String, name: String, active: String, windowDays: String, batchSizeText: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.active = active
            self.windowDays = windowDays
            self.batchSizeText = batchSizeText
            self.statusLabel = statusLabel
        }
    }

    static func toManualClaimMilestoneView(_ item: ManualClaimMilestone) -> ManualClaimMilestoneView {
        return ManualClaimMilestoneView(
            code: Kit.Text.truncate(item.code, limit: 120),
            name: Kit.Text.truncate(item.name, limit: 80),
            active: "\(item.active)",
            windowDays: String(item.windowDays),
            batchSizeText: String(item.batchSize),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toManualClaimMilestoneViews(_ items: [ManualClaimMilestone]) -> [ManualClaimMilestoneView] {
        var views: [ManualClaimMilestoneView] = []
        for item in items {
            views.append(toManualClaimMilestoneView(item))
        }
        return views
    }

    static func sumManualClaimMilestoneView(_ view: ManualClaimMilestoneView) throws -> Double {
        guard let parsedWindowDays = Int(view.windowDays) else {
            throw Kit.Failure("parse window days: not a number")
        }
        guard let parsedBatchSize = Int(view.batchSizeText) else {
            throw Kit.Failure("parse batch size: not a number")
        }
        return Double(parsedWindowDays) + Double(parsedBatchSize)
    }
}
