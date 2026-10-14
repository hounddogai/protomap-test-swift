import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a batched credential schedule.
    final class BatchedCredentialScheduleView {
        var code: String
        var label: String
        var createdAtText: String
        var maximum: String
        var budget: String
        var description: String
        var phoneText: String
        var unit: String
        var priority: String
        var refills: String
        var channel: String
        var statusLabel: String

        init(code: String, label: String, createdAtText: String, maximum: String, budget: String, description: String, phoneText: String, unit: String, priority: String, refills: String, channel: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.createdAtText = createdAtText
            self.maximum = maximum
            self.budget = budget
            self.description = description
            self.phoneText = phoneText
            self.unit = unit
            self.priority = priority
            self.refills = refills
            self.channel = channel
            self.statusLabel = statusLabel
        }
    }

    static func toBatchedCredentialScheduleView(_ item: BatchedCredentialSchedule) -> BatchedCredentialScheduleView {
        return BatchedCredentialScheduleView(
            code: item.code,
            label: item.label,
            createdAtText: String(item.createdAt),
            maximum: String(format: "%.2f", item.maximum),
            budget: String(format: "%.2f", item.budget),
            description: item.description,
            phoneText: Kit.Text.truncate(item.phone, limit: 64),
            unit: item.unit,
            priority: String(item.priority),
            refills: String(item.refills),
            channel: item.channel,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toBatchedCredentialScheduleViews(_ items: [BatchedCredentialSchedule]) -> [BatchedCredentialScheduleView] {
        var views: [BatchedCredentialScheduleView] = []
        for item in items {
            views.append(toBatchedCredentialScheduleView(item))
        }
        return views
    }

    static func sumBatchedCredentialScheduleView(_ view: BatchedCredentialScheduleView) throws -> Double {
        guard let parsedCreatedAt = Int(view.createdAtText) else {
            throw Kit.Failure("parse created at: not a number")
        }
        guard let parsedMaximum = Double(view.maximum) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        guard let parsedBudget = Double(view.budget) else {
            throw Kit.Failure("parse budget: not a number")
        }
        return Double(parsedCreatedAt) + parsedMaximum + parsedBudget
    }
}
