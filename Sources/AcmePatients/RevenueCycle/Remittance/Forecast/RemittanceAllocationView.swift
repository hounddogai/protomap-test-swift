import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a remittance allocation.
    final class RemittanceAllocationView {
        var code: String
        var label: String
        var unitText: String
        var active: String
        var floorValue: String
        var priority: String
        var ratio: String
        var acuity: String
        var statusLabel: String

        init(code: String, label: String, unitText: String, active: String, floorValue: String, priority: String, ratio: String, acuity: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.unitText = unitText
            self.active = active
            self.floorValue = floorValue
            self.priority = priority
            self.ratio = ratio
            self.acuity = acuity
            self.statusLabel = statusLabel
        }
    }

    static func toRemittanceAllocationView(_ item: RemittanceAllocation) -> RemittanceAllocationView {
        return RemittanceAllocationView(
            code: Kit.Text.truncate(item.code, limit: 40),
            label: item.label,
            unitText: item.unit,
            active: "\(item.active)",
            floorValue: String(format: "%.2f", item.floorValue),
            priority: String(item.priority),
            ratio: String(format: "%.2f", item.ratio),
            acuity: String(item.acuity),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRemittanceAllocationViews(_ items: [RemittanceAllocation]) -> [RemittanceAllocationView] {
        var views: [RemittanceAllocationView] = []
        for item in items {
            views.append(toRemittanceAllocationView(item))
        }
        return views
    }

    static func sumRemittanceAllocationView(_ view: RemittanceAllocationView) throws -> Double {
        guard let parsedFloorValue = Double(view.floorValue) else {
            throw Kit.Failure("parse floor value: not a number")
        }
        guard let parsedPriority = Int(view.priority) else {
            throw Kit.Failure("parse priority: not a number")
        }
        guard let parsedRatio = Double(view.ratio) else {
            throw Kit.Failure("parse ratio: not a number")
        }
        return parsedFloorValue + Double(parsedPriority) + parsedRatio
    }
}
