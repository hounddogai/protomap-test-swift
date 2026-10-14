import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a batched dispense profile.
    final class BatchedDispenseProfileView {
        var code: String
        var nameText: String
        var durationMinutes: String
        var windowDaysText: String
        var pinned: String
        var capacityText: String
        var channel: String
        var maximum: String
        var ratio: String
        var timezone: String
        var statusLabel: String

        init(code: String, nameText: String, durationMinutes: String, windowDaysText: String, pinned: String, capacityText: String, channel: String, maximum: String, ratio: String, timezone: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.durationMinutes = durationMinutes
            self.windowDaysText = windowDaysText
            self.pinned = pinned
            self.capacityText = capacityText
            self.channel = channel
            self.maximum = maximum
            self.ratio = ratio
            self.timezone = timezone
            self.statusLabel = statusLabel
        }
    }

    static func toBatchedDispenseProfileView(_ item: BatchedDispenseProfile) -> BatchedDispenseProfileView {
        return BatchedDispenseProfileView(
            code: item.code,
            nameText: item.name,
            durationMinutes: String(item.durationMinutes),
            windowDaysText: String(item.windowDays),
            pinned: "\(item.pinned)",
            capacityText: String(item.capacity),
            channel: item.channel,
            maximum: String(format: "%.2f", item.maximum),
            ratio: String(format: "%.2f", item.ratio),
            timezone: item.timezone,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toBatchedDispenseProfileViews(_ items: [BatchedDispenseProfile]) -> [BatchedDispenseProfileView] {
        var views: [BatchedDispenseProfileView] = []
        for item in items {
            views.append(toBatchedDispenseProfileView(item))
        }
        return views
    }

    static func sumBatchedDispenseProfileView(_ view: BatchedDispenseProfileView) throws -> Double {
        guard let parsedDurationMinutes = Int(view.durationMinutes) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        guard let parsedWindowDays = Int(view.windowDaysText) else {
            throw Kit.Failure("parse window days: not a number")
        }
        guard let parsedCapacity = Int(view.capacityText) else {
            throw Kit.Failure("parse capacity: not a number")
        }
        return Double(parsedDurationMinutes) + Double(parsedWindowDays) + Double(parsedCapacity)
    }
}
