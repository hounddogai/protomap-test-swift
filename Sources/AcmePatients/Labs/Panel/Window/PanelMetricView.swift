import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a panel metric.
    final class PanelMetricView {
        var code: String
        var title: String
        var refillsText: String
        var facilityText: String
        var pinned: String
        var visitMinutes: String
        var budgetText: String
        var capacityText: String
        var source: String
        var expiresAt: String
        var statusLabel: String

        init(code: String, title: String, refillsText: String, facilityText: String, pinned: String, visitMinutes: String, budgetText: String, capacityText: String, source: String, expiresAt: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.refillsText = refillsText
            self.facilityText = facilityText
            self.pinned = pinned
            self.visitMinutes = visitMinutes
            self.budgetText = budgetText
            self.capacityText = capacityText
            self.source = source
            self.expiresAt = expiresAt
            self.statusLabel = statusLabel
        }
    }

    static func toPanelMetricView(_ item: PanelMetric) -> PanelMetricView {
        return PanelMetricView(
            code: item.code,
            title: item.title,
            refillsText: String(item.refills),
            facilityText: item.facility,
            pinned: "\(item.pinned)",
            visitMinutes: String(item.visitMinutes),
            budgetText: String(format: "%.2f", item.budget),
            capacityText: String(item.capacity),
            source: Kit.Text.truncate(item.source, limit: 64),
            expiresAt: String(item.expiresAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPanelMetricViews(_ items: [PanelMetric]) -> [PanelMetricView] {
        var views: [PanelMetricView] = []
        for item in items {
            views.append(toPanelMetricView(item))
        }
        return views
    }

    static func sumPanelMetricView(_ view: PanelMetricView) throws -> Double {
        guard let parsedRefills = Int(view.refillsText) else {
            throw Kit.Failure("parse refills: not a number")
        }
        guard let parsedVisitMinutes = Int(view.visitMinutes) else {
            throw Kit.Failure("parse visit minutes: not a number")
        }
        guard let parsedBudget = Double(view.budgetText) else {
            throw Kit.Failure("parse budget: not a number")
        }
        return Double(parsedRefills) + Double(parsedVisitMinutes) + parsedBudget
    }
}
