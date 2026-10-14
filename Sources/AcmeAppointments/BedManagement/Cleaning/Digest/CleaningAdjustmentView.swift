import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a cleaning adjustment.
    final class CleaningAdjustmentView {
        var code: String
        var labelText: String
        var quantity: String
        var summaryText: String
        var maximum: String
        var marginText: String
        var startsAt: String
        var copayText: String
        var statusLabel: String

        init(code: String, labelText: String, quantity: String, summaryText: String, maximum: String, marginText: String, startsAt: String, copayText: String, statusLabel: String) {
            self.code = code
            self.labelText = labelText
            self.quantity = quantity
            self.summaryText = summaryText
            self.maximum = maximum
            self.marginText = marginText
            self.startsAt = startsAt
            self.copayText = copayText
            self.statusLabel = statusLabel
        }
    }

    static func toCleaningAdjustmentView(_ item: CleaningAdjustment) -> CleaningAdjustmentView {
        return CleaningAdjustmentView(
            code: item.code,
            labelText: Kit.Text.truncate(item.label, limit: 40),
            quantity: String(item.quantity),
            summaryText: item.summary,
            maximum: String(format: "%.2f", item.maximum),
            marginText: String(format: "%.2f", item.margin),
            startsAt: String(item.startsAt),
            copayText: String(format: "%.2f", item.copay),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCleaningAdjustmentViews(_ items: [CleaningAdjustment]) -> [CleaningAdjustmentView] {
        var views: [CleaningAdjustmentView] = []
        for item in items {
            views.append(toCleaningAdjustmentView(item))
        }
        return views
    }

    static func sumCleaningAdjustmentView(_ view: CleaningAdjustmentView) throws -> Double {
        guard let parsedQuantity = Int(view.quantity) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        guard let parsedMaximum = Double(view.maximum) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        guard let parsedMargin = Double(view.marginText) else {
            throw Kit.Failure("parse margin: not a number")
        }
        return Double(parsedQuantity) + parsedMaximum + parsedMargin
    }
}
