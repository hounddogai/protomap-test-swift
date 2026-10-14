import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a scheduled denial baseline.
    final class ScheduledDenialBaselineView {
        var codeText: String
        var name: String
        var title: String
        var refillsText: String
        var wardText: String
        var visible: String
        var statusLabel: String

        init(codeText: String, name: String, title: String, refillsText: String, wardText: String, visible: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.title = title
            self.refillsText = refillsText
            self.wardText = wardText
            self.visible = visible
            self.statusLabel = statusLabel
        }
    }

    static func toScheduledDenialBaselineView(_ item: ScheduledDenialBaseline) -> ScheduledDenialBaselineView {
        return ScheduledDenialBaselineView(
            codeText: Kit.Text.truncate(item.code, limit: 80),
            name: item.name,
            title: item.title,
            refillsText: String(item.refills),
            wardText: item.ward,
            visible: "\(item.visible)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toScheduledDenialBaselineViews(_ items: [ScheduledDenialBaseline]) -> [ScheduledDenialBaselineView] {
        var views: [ScheduledDenialBaselineView] = []
        for item in items {
            views.append(toScheduledDenialBaselineView(item))
        }
        return views
    }

    static func sumScheduledDenialBaselineView(_ view: ScheduledDenialBaselineView) throws -> Double {
        guard let parsedRefills = Int(view.refillsText) else {
            throw Kit.Failure("parse refills: not a number")
        }
        return Double(parsedRefills)
    }
}
