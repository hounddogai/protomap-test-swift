import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a slot checkpoint.
    final class SlotCheckpointView {
        var code: String
        var nameText: String
        var category: String
        var ownerID: String
        var amount: String
        var createdAt: String
        var weight: String
        var summaryText: String
        var timezone: String
        var limitText: String
        var statusLabel: String

        init(code: String, nameText: String, category: String, ownerID: String, amount: String, createdAt: String, weight: String, summaryText: String, timezone: String, limitText: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.category = category
            self.ownerID = ownerID
            self.amount = amount
            self.createdAt = createdAt
            self.weight = weight
            self.summaryText = summaryText
            self.timezone = timezone
            self.limitText = limitText
            self.statusLabel = statusLabel
        }
    }

    static func toSlotCheckpointView(_ item: SlotCheckpoint) -> SlotCheckpointView {
        return SlotCheckpointView(
            code: item.code,
            nameText: Kit.Text.truncate(item.name, limit: 80),
            category: item.category,
            ownerID: item.ownerID,
            amount: String(format: "%.2f", item.amount),
            createdAt: String(item.createdAt),
            weight: String(format: "%.2f", item.weight),
            summaryText: item.summary,
            timezone: item.timezone,
            limitText: String(item.limit),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toSlotCheckpointViews(_ items: [SlotCheckpoint]) -> [SlotCheckpointView] {
        var views: [SlotCheckpointView] = []
        for item in items {
            views.append(toSlotCheckpointView(item))
        }
        return views
    }

    static func sumSlotCheckpointView(_ view: SlotCheckpointView) throws -> Double {
        guard let parsedAmount = Double(view.amount) else {
            throw Kit.Failure("parse amount: not a number")
        }
        guard let parsedCreatedAt = Int(view.createdAt) else {
            throw Kit.Failure("parse created at: not a number")
        }
        guard let parsedWeight = Double(view.weight) else {
            throw Kit.Failure("parse weight: not a number")
        }
        return parsedAmount + Double(parsedCreatedAt) + parsedWeight
    }
}
