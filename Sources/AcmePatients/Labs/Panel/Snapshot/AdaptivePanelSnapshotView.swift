import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a adaptive panel snapshot.
    final class AdaptivePanelSnapshotView {
        var code: String
        var label: String
        var channel: String
        var ratio: String
        var updatedAt: String
        var budget: String
        var maximumText: String
        var checksum: String
        var ceiling: String
        var retriesText: String
        var statusLabel: String

        init(code: String, label: String, channel: String, ratio: String, updatedAt: String, budget: String, maximumText: String, checksum: String, ceiling: String, retriesText: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.channel = channel
            self.ratio = ratio
            self.updatedAt = updatedAt
            self.budget = budget
            self.maximumText = maximumText
            self.checksum = checksum
            self.ceiling = ceiling
            self.retriesText = retriesText
            self.statusLabel = statusLabel
        }
    }

    static func toAdaptivePanelSnapshotView(_ item: AdaptivePanelSnapshot) -> AdaptivePanelSnapshotView {
        return AdaptivePanelSnapshotView(
            code: Kit.Text.truncate(item.code, limit: 80),
            label: item.label,
            channel: item.channel,
            ratio: String(format: "%.2f", item.ratio),
            updatedAt: String(item.updatedAt),
            budget: String(format: "%.2f", item.budget),
            maximumText: String(format: "%.2f", item.maximum),
            checksum: Kit.Text.truncate(item.checksum, limit: 64),
            ceiling: String(format: "%.2f", item.ceiling),
            retriesText: String(item.retries),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAdaptivePanelSnapshotViews(_ items: [AdaptivePanelSnapshot]) -> [AdaptivePanelSnapshotView] {
        var views: [AdaptivePanelSnapshotView] = []
        for item in items {
            views.append(toAdaptivePanelSnapshotView(item))
        }
        return views
    }

    static func sumAdaptivePanelSnapshotView(_ view: AdaptivePanelSnapshotView) throws -> Double {
        guard let parsedRatio = Double(view.ratio) else {
            throw Kit.Failure("parse ratio: not a number")
        }
        guard let parsedUpdatedAt = Int(view.updatedAt) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        guard let parsedBudget = Double(view.budget) else {
            throw Kit.Failure("parse budget: not a number")
        }
        return parsedRatio + Double(parsedUpdatedAt) + parsedBudget
    }
}
