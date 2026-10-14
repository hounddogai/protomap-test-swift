import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a charge profile.
    final class ChargeProfileView {
        var code: String
        var label: String
        var capacity: String
        var maximum: String
        var priorityText: String
        var statusLabel: String

        init(code: String, label: String, capacity: String, maximum: String, priorityText: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.capacity = capacity
            self.maximum = maximum
            self.priorityText = priorityText
            self.statusLabel = statusLabel
        }
    }

    static func toChargeProfileView(_ item: ChargeProfile) -> ChargeProfileView {
        return ChargeProfileView(
            code: item.code,
            label: item.label,
            capacity: String(item.capacity),
            maximum: String(format: "%.2f", item.maximum),
            priorityText: String(item.priority),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toChargeProfileViews(_ items: [ChargeProfile]) -> [ChargeProfileView] {
        var views: [ChargeProfileView] = []
        for item in items {
            views.append(toChargeProfileView(item))
        }
        return views
    }

    static func sumChargeProfileView(_ view: ChargeProfileView) throws -> Double {
        guard let parsedCapacity = Int(view.capacity) else {
            throw Kit.Failure("parse capacity: not a number")
        }
        guard let parsedMaximum = Double(view.maximum) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        guard let parsedPriority = Int(view.priorityText) else {
            throw Kit.Failure("parse priority: not a number")
        }
        return Double(parsedCapacity) + parsedMaximum + Double(parsedPriority)
    }
}
