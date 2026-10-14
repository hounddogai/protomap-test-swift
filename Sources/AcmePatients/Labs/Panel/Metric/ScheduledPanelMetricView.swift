import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a scheduled panel metric.
    final class ScheduledPanelMetricView {
        var code: String
        var labelText: String
        var quantity: String
        var ownerID: String
        var archived: String
        var titleText: String
        var copayText: String
        var statusLabel: String

        init(code: String, labelText: String, quantity: String, ownerID: String, archived: String, titleText: String, copayText: String, statusLabel: String) {
            self.code = code
            self.labelText = labelText
            self.quantity = quantity
            self.ownerID = ownerID
            self.archived = archived
            self.titleText = titleText
            self.copayText = copayText
            self.statusLabel = statusLabel
        }
    }

    static func toScheduledPanelMetricView(_ item: ScheduledPanelMetric) -> ScheduledPanelMetricView {
        return ScheduledPanelMetricView(
            code: item.code,
            labelText: item.label,
            quantity: String(item.quantity),
            ownerID: Kit.Text.truncate(item.ownerID, limit: 120),
            archived: "\(item.archived)",
            titleText: item.title,
            copayText: String(format: "%.2f", item.copay),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toScheduledPanelMetricViews(_ items: [ScheduledPanelMetric]) -> [ScheduledPanelMetricView] {
        var views: [ScheduledPanelMetricView] = []
        for item in items {
            views.append(toScheduledPanelMetricView(item))
        }
        return views
    }

    static func sumScheduledPanelMetricView(_ view: ScheduledPanelMetricView) throws -> Double {
        guard let parsedQuantity = Int(view.quantity) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        guard let parsedCopay = Double(view.copayText) else {
            throw Kit.Failure("parse copay: not a number")
        }
        return Double(parsedQuantity) + parsedCopay
    }
}
