import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a scheduled inventory checkpoint.
    final class ScheduledInventoryCheckpointView {
        var code: String
        var labelText: String
        var priority: String
        var graceDays: String
        var payer: String
        var capacityText: String
        var statusLabel: String

        init(code: String, labelText: String, priority: String, graceDays: String, payer: String, capacityText: String, statusLabel: String) {
            self.code = code
            self.labelText = labelText
            self.priority = priority
            self.graceDays = graceDays
            self.payer = payer
            self.capacityText = capacityText
            self.statusLabel = statusLabel
        }
    }

    static func toScheduledInventoryCheckpointView(_ item: ScheduledInventoryCheckpoint) -> ScheduledInventoryCheckpointView {
        return ScheduledInventoryCheckpointView(
            code: item.code,
            labelText: Kit.Text.truncate(item.label, limit: 64),
            priority: String(item.priority),
            graceDays: String(item.graceDays),
            payer: item.payer,
            capacityText: String(item.capacity),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toScheduledInventoryCheckpointViews(_ items: [ScheduledInventoryCheckpoint]) -> [ScheduledInventoryCheckpointView] {
        var views: [ScheduledInventoryCheckpointView] = []
        for item in items {
            views.append(toScheduledInventoryCheckpointView(item))
        }
        return views
    }

    static func sumScheduledInventoryCheckpointView(_ view: ScheduledInventoryCheckpointView) throws -> Double {
        guard let parsedPriority = Int(view.priority) else {
            throw Kit.Failure("parse priority: not a number")
        }
        guard let parsedGraceDays = Int(view.graceDays) else {
            throw Kit.Failure("parse grace days: not a number")
        }
        guard let parsedCapacity = Int(view.capacityText) else {
            throw Kit.Failure("parse capacity: not a number")
        }
        return Double(parsedPriority) + Double(parsedGraceDays) + Double(parsedCapacity)
    }
}
