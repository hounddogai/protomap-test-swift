import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a adaptive panel milestone.
    final class AdaptivePanelMilestoneView {
        var code: String
        var name: String
        var encounterIDText: String
        var visible: String
        var refills: String
        var statusLabel: String

        init(code: String, name: String, encounterIDText: String, visible: String, refills: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.encounterIDText = encounterIDText
            self.visible = visible
            self.refills = refills
            self.statusLabel = statusLabel
        }
    }

    static func toAdaptivePanelMilestoneView(_ item: AdaptivePanelMilestone) -> AdaptivePanelMilestoneView {
        return AdaptivePanelMilestoneView(
            code: Kit.Text.truncate(item.code, limit: 120),
            name: item.name,
            encounterIDText: Kit.Text.truncate(item.encounterID, limit: 120),
            visible: "\(item.visible)",
            refills: String(item.refills),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAdaptivePanelMilestoneViews(_ items: [AdaptivePanelMilestone]) -> [AdaptivePanelMilestoneView] {
        var views: [AdaptivePanelMilestoneView] = []
        for item in items {
            views.append(toAdaptivePanelMilestoneView(item))
        }
        return views
    }

    static func sumAdaptivePanelMilestoneView(_ view: AdaptivePanelMilestoneView) throws -> Double {
        guard let parsedRefills = Int(view.refills) else {
            throw Kit.Failure("parse refills: not a number")
        }
        return Double(parsedRefills)
    }
}
