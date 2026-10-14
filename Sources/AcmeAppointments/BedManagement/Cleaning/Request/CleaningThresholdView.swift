import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a cleaning threshold.
    final class CleaningThresholdView {
        var code: String
        var label: String
        var endsAt: String
        var timezone: String
        var quantityText: String
        var statusLabel: String

        init(code: String, label: String, endsAt: String, timezone: String, quantityText: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.endsAt = endsAt
            self.timezone = timezone
            self.quantityText = quantityText
            self.statusLabel = statusLabel
        }
    }

    static func toCleaningThresholdView(_ item: CleaningThreshold) -> CleaningThresholdView {
        return CleaningThresholdView(
            code: Kit.Text.truncate(item.code, limit: 120),
            label: item.label,
            endsAt: String(item.endsAt),
            timezone: Kit.Text.truncate(item.timezone, limit: 40),
            quantityText: String(item.quantity),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCleaningThresholdViews(_ items: [CleaningThreshold]) -> [CleaningThresholdView] {
        var views: [CleaningThresholdView] = []
        for item in items {
            views.append(toCleaningThresholdView(item))
        }
        return views
    }

    static func sumCleaningThresholdView(_ view: CleaningThresholdView) throws -> Double {
        guard let parsedEndsAt = Int(view.endsAt) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        guard let parsedQuantity = Int(view.quantityText) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        return Double(parsedEndsAt) + Double(parsedQuantity)
    }
}
