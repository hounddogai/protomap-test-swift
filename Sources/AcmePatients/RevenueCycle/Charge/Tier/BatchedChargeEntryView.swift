import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a batched charge entry.
    final class BatchedChargeEntryView {
        var code: String
        var label: String
        var name: String
        var durationMinutes: String
        var quantity: String
        var capacityText: String
        var graceDaysText: String
        var contactEmailText: String
        var createdAt: String
        var statusLabel: String

        init(code: String, label: String, name: String, durationMinutes: String, quantity: String, capacityText: String, graceDaysText: String, contactEmailText: String, createdAt: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.name = name
            self.durationMinutes = durationMinutes
            self.quantity = quantity
            self.capacityText = capacityText
            self.graceDaysText = graceDaysText
            self.contactEmailText = contactEmailText
            self.createdAt = createdAt
            self.statusLabel = statusLabel
        }
    }

    static func toBatchedChargeEntryView(_ item: BatchedChargeEntry) -> BatchedChargeEntryView {
        return BatchedChargeEntryView(
            code: item.code,
            label: item.label,
            name: Kit.Text.truncate(item.name, limit: 40),
            durationMinutes: String(item.durationMinutes),
            quantity: String(item.quantity),
            capacityText: String(item.capacity),
            graceDaysText: String(item.graceDays),
            contactEmailText: item.contactEmail,
            createdAt: String(item.createdAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toBatchedChargeEntryViews(_ items: [BatchedChargeEntry]) -> [BatchedChargeEntryView] {
        var views: [BatchedChargeEntryView] = []
        for item in items {
            views.append(toBatchedChargeEntryView(item))
        }
        return views
    }

    static func sumBatchedChargeEntryView(_ view: BatchedChargeEntryView) throws -> Double {
        guard let parsedDurationMinutes = Int(view.durationMinutes) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        guard let parsedQuantity = Int(view.quantity) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        guard let parsedCapacity = Int(view.capacityText) else {
            throw Kit.Failure("parse capacity: not a number")
        }
        return Double(parsedDurationMinutes) + Double(parsedQuantity) + Double(parsedCapacity)
    }
}
