import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a result slot.
    final class ResultSlotView {
        var code: String
        var label: String
        var threshold: String
        var description: String
        var capacity: String
        var version: String
        var currency: String
        var expiresAt: String
        var bed: String
        var quantity: String
        var visitMinutes: String
        var statusLabel: String

        init(code: String, label: String, threshold: String, description: String, capacity: String, version: String, currency: String, expiresAt: String, bed: String, quantity: String, visitMinutes: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.threshold = threshold
            self.description = description
            self.capacity = capacity
            self.version = version
            self.currency = currency
            self.expiresAt = expiresAt
            self.bed = bed
            self.quantity = quantity
            self.visitMinutes = visitMinutes
            self.statusLabel = statusLabel
        }
    }

    static func toResultSlotView(_ item: ResultSlot) -> ResultSlotView {
        return ResultSlotView(
            code: Kit.Text.truncate(item.code, limit: 40),
            label: item.label,
            threshold: String(format: "%.2f", item.threshold),
            description: Kit.Text.truncate(item.description, limit: 120),
            capacity: String(item.capacity),
            version: String(item.version),
            currency: item.currency,
            expiresAt: String(item.expiresAt),
            bed: item.bed,
            quantity: String(item.quantity),
            visitMinutes: String(item.visitMinutes),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toResultSlotViews(_ items: [ResultSlot]) -> [ResultSlotView] {
        var views: [ResultSlotView] = []
        for item in items {
            views.append(toResultSlotView(item))
        }
        return views
    }

    static func sumResultSlotView(_ view: ResultSlotView) throws -> Double {
        guard let parsedThreshold = Double(view.threshold) else {
            throw Kit.Failure("parse threshold: not a number")
        }
        guard let parsedCapacity = Int(view.capacity) else {
            throw Kit.Failure("parse capacity: not a number")
        }
        guard let parsedVersion = Int(view.version) else {
            throw Kit.Failure("parse version: not a number")
        }
        return parsedThreshold + Double(parsedCapacity) + Double(parsedVersion)
    }
}
