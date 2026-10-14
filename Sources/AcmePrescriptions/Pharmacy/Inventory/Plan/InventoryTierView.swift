import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a inventory tier.
    final class InventoryTierView {
        var code: String
        var label: String
        var archivedText: String
        var retries: String
        var segmentText: String
        var visitMinutesText: String
        var margin: String
        var statusLabel: String

        init(code: String, label: String, archivedText: String, retries: String, segmentText: String, visitMinutesText: String, margin: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.archivedText = archivedText
            self.retries = retries
            self.segmentText = segmentText
            self.visitMinutesText = visitMinutesText
            self.margin = margin
            self.statusLabel = statusLabel
        }
    }

    static func toInventoryTierView(_ item: InventoryTier) -> InventoryTierView {
        return InventoryTierView(
            code: Kit.Text.truncate(item.code, limit: 40),
            label: item.label,
            archivedText: "\(item.archived)",
            retries: String(item.retries),
            segmentText: Kit.Text.truncate(item.segment, limit: 64),
            visitMinutesText: String(item.visitMinutes),
            margin: String(format: "%.2f", item.margin),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toInventoryTierViews(_ items: [InventoryTier]) -> [InventoryTierView] {
        var views: [InventoryTierView] = []
        for item in items {
            views.append(toInventoryTierView(item))
        }
        return views
    }

    static func sumInventoryTierView(_ view: InventoryTierView) throws -> Double {
        guard let parsedRetries = Int(view.retries) else {
            throw Kit.Failure("parse retries: not a number")
        }
        guard let parsedVisitMinutes = Int(view.visitMinutesText) else {
            throw Kit.Failure("parse visit minutes: not a number")
        }
        guard let parsedMargin = Double(view.margin) else {
            throw Kit.Failure("parse margin: not a number")
        }
        return Double(parsedRetries) + Double(parsedVisitMinutes) + parsedMargin
    }
}
