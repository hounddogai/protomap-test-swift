import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a scheduled float pool bundle.
    final class ScheduledFloatPoolBundleView {
        var code: String
        var name: String
        var copay: String
        var segment: String
        var priority: String
        var quantity: String
        var statusLabel: String

        init(code: String, name: String, copay: String, segment: String, priority: String, quantity: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.copay = copay
            self.segment = segment
            self.priority = priority
            self.quantity = quantity
            self.statusLabel = statusLabel
        }
    }

    static func toScheduledFloatPoolBundleView(_ item: ScheduledFloatPoolBundle) -> ScheduledFloatPoolBundleView {
        return ScheduledFloatPoolBundleView(
            code: Kit.Text.truncate(item.code, limit: 120),
            name: item.name,
            copay: String(format: "%.2f", item.copay),
            segment: Kit.Text.truncate(item.segment, limit: 120),
            priority: String(item.priority),
            quantity: String(item.quantity),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toScheduledFloatPoolBundleViews(_ items: [ScheduledFloatPoolBundle]) -> [ScheduledFloatPoolBundleView] {
        var views: [ScheduledFloatPoolBundleView] = []
        for item in items {
            views.append(toScheduledFloatPoolBundleView(item))
        }
        return views
    }

    static func sumScheduledFloatPoolBundleView(_ view: ScheduledFloatPoolBundleView) throws -> Double {
        guard let parsedCopay = Double(view.copay) else {
            throw Kit.Failure("parse copay: not a number")
        }
        guard let parsedPriority = Int(view.priority) else {
            throw Kit.Failure("parse priority: not a number")
        }
        guard let parsedQuantity = Int(view.quantity) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        return parsedCopay + Double(parsedPriority) + Double(parsedQuantity)
    }
}
