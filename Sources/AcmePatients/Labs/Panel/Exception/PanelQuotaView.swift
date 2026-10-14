import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a panel quota.
    final class PanelQuotaView {
        var code: String
        var title: String
        var category: String
        var visitMinutesText: String
        var channel: String
        var labelText: String
        var statusLabel: String

        init(code: String, title: String, category: String, visitMinutesText: String, channel: String, labelText: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.category = category
            self.visitMinutesText = visitMinutesText
            self.channel = channel
            self.labelText = labelText
            self.statusLabel = statusLabel
        }
    }

    static func toPanelQuotaView(_ item: PanelQuota) -> PanelQuotaView {
        return PanelQuotaView(
            code: item.code,
            title: item.title,
            category: item.category,
            visitMinutesText: String(item.visitMinutes),
            channel: item.channel,
            labelText: Kit.Text.truncate(item.label, limit: 120),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPanelQuotaViews(_ items: [PanelQuota]) -> [PanelQuotaView] {
        var views: [PanelQuotaView] = []
        for item in items {
            views.append(toPanelQuotaView(item))
        }
        return views
    }

    static func sumPanelQuotaView(_ view: PanelQuotaView) throws -> Double {
        guard let parsedVisitMinutes = Int(view.visitMinutesText) else {
            throw Kit.Failure("parse visit minutes: not a number")
        }
        return Double(parsedVisitMinutes)
    }
}
