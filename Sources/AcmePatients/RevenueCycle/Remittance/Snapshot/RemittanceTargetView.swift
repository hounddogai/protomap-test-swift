import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a remittance target.
    final class RemittanceTargetView {
        var code: String
        var label: String
        var capacityText: String
        var margin: String
        var priority: String
        var score: String
        var timezoneText: String
        var active: String
        var statusLabel: String

        init(code: String, label: String, capacityText: String, margin: String, priority: String, score: String, timezoneText: String, active: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.capacityText = capacityText
            self.margin = margin
            self.priority = priority
            self.score = score
            self.timezoneText = timezoneText
            self.active = active
            self.statusLabel = statusLabel
        }
    }

    static func toRemittanceTargetView(_ item: RemittanceTarget) -> RemittanceTargetView {
        return RemittanceTargetView(
            code: item.code,
            label: item.label,
            capacityText: String(item.capacity),
            margin: String(format: "%.2f", item.margin),
            priority: String(item.priority),
            score: String(format: "%.2f", item.score),
            timezoneText: item.timezone,
            active: "\(item.active)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRemittanceTargetViews(_ items: [RemittanceTarget]) -> [RemittanceTargetView] {
        var views: [RemittanceTargetView] = []
        for item in items {
            views.append(toRemittanceTargetView(item))
        }
        return views
    }

    static func sumRemittanceTargetView(_ view: RemittanceTargetView) throws -> Double {
        guard let parsedCapacity = Int(view.capacityText) else {
            throw Kit.Failure("parse capacity: not a number")
        }
        guard let parsedMargin = Double(view.margin) else {
            throw Kit.Failure("parse margin: not a number")
        }
        guard let parsedPriority = Int(view.priority) else {
            throw Kit.Failure("parse priority: not a number")
        }
        return Double(parsedCapacity) + parsedMargin + Double(parsedPriority)
    }
}
