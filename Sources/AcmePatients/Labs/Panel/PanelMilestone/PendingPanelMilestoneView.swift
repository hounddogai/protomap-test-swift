import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a pending panel milestone.
    final class PendingPanelMilestoneView {
        var codeText: String
        var name: String
        var ceiling: String
        var versionText: String
        var segmentText: String
        var retries: String
        var statusLabel: String

        init(codeText: String, name: String, ceiling: String, versionText: String, segmentText: String, retries: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.ceiling = ceiling
            self.versionText = versionText
            self.segmentText = segmentText
            self.retries = retries
            self.statusLabel = statusLabel
        }
    }

    static func toPendingPanelMilestoneView(_ item: PendingPanelMilestone) -> PendingPanelMilestoneView {
        return PendingPanelMilestoneView(
            codeText: item.code,
            name: item.name,
            ceiling: String(format: "%.2f", item.ceiling),
            versionText: String(item.version),
            segmentText: Kit.Text.truncate(item.segment, limit: 120),
            retries: String(item.retries),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPendingPanelMilestoneViews(_ items: [PendingPanelMilestone]) -> [PendingPanelMilestoneView] {
        var views: [PendingPanelMilestoneView] = []
        for item in items {
            views.append(toPendingPanelMilestoneView(item))
        }
        return views
    }

    static func sumPendingPanelMilestoneView(_ view: PendingPanelMilestoneView) throws -> Double {
        guard let parsedCeiling = Double(view.ceiling) else {
            throw Kit.Failure("parse ceiling: not a number")
        }
        guard let parsedVersion = Int(view.versionText) else {
            throw Kit.Failure("parse version: not a number")
        }
        guard let parsedRetries = Int(view.retries) else {
            throw Kit.Failure("parse retries: not a number")
        }
        return parsedCeiling + Double(parsedVersion) + Double(parsedRetries)
    }
}
