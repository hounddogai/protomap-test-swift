import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a global goal entry.
    final class GlobalGoalEntryView {
        var code: String
        var label: String
        var priority: String
        var windowDays: String
        var createdAt: String
        var limit: String
        var ratio: String
        var contactEmailText: String
        var rate: String
        var ownerID: String
        var statusLabel: String

        init(code: String, label: String, priority: String, windowDays: String, createdAt: String, limit: String, ratio: String, contactEmailText: String, rate: String, ownerID: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.priority = priority
            self.windowDays = windowDays
            self.createdAt = createdAt
            self.limit = limit
            self.ratio = ratio
            self.contactEmailText = contactEmailText
            self.rate = rate
            self.ownerID = ownerID
            self.statusLabel = statusLabel
        }
    }

    static func toGlobalGoalEntryView(_ item: GlobalGoalEntry) -> GlobalGoalEntryView {
        return GlobalGoalEntryView(
            code: Kit.Text.truncate(item.code, limit: 40),
            label: item.label,
            priority: String(item.priority),
            windowDays: String(item.windowDays),
            createdAt: String(item.createdAt),
            limit: String(item.limit),
            ratio: String(format: "%.2f", item.ratio),
            contactEmailText: Kit.Text.truncate(item.contactEmail, limit: 80),
            rate: String(format: "%.2f", item.rate),
            ownerID: item.ownerID,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toGlobalGoalEntryViews(_ items: [GlobalGoalEntry]) -> [GlobalGoalEntryView] {
        var views: [GlobalGoalEntryView] = []
        for item in items {
            views.append(toGlobalGoalEntryView(item))
        }
        return views
    }

    static func sumGlobalGoalEntryView(_ view: GlobalGoalEntryView) throws -> Double {
        guard let parsedPriority = Int(view.priority) else {
            throw Kit.Failure("parse priority: not a number")
        }
        guard let parsedWindowDays = Int(view.windowDays) else {
            throw Kit.Failure("parse window days: not a number")
        }
        guard let parsedCreatedAt = Int(view.createdAt) else {
            throw Kit.Failure("parse created at: not a number")
        }
        return Double(parsedPriority) + Double(parsedWindowDays) + Double(parsedCreatedAt)
    }
}
