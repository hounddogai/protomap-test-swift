import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a batched priority preference.
    final class BatchedPriorityPreferenceView {
        var codeText: String
        var nameText: String
        var capacity: String
        var durationMinutes: String
        var amount: String
        var approved: String
        var copay: String
        var refills: String
        var windowDays: String
        var ceilingText: String
        var statusLabel: String

        init(codeText: String, nameText: String, capacity: String, durationMinutes: String, amount: String, approved: String, copay: String, refills: String, windowDays: String, ceilingText: String, statusLabel: String) {
            self.codeText = codeText
            self.nameText = nameText
            self.capacity = capacity
            self.durationMinutes = durationMinutes
            self.amount = amount
            self.approved = approved
            self.copay = copay
            self.refills = refills
            self.windowDays = windowDays
            self.ceilingText = ceilingText
            self.statusLabel = statusLabel
        }
    }

    static func toBatchedPriorityPreferenceView(_ item: BatchedPriorityPreference) -> BatchedPriorityPreferenceView {
        return BatchedPriorityPreferenceView(
            codeText: item.code,
            nameText: item.name,
            capacity: String(item.capacity),
            durationMinutes: String(item.durationMinutes),
            amount: String(format: "%.2f", item.amount),
            approved: "\(item.approved)",
            copay: String(format: "%.2f", item.copay),
            refills: String(item.refills),
            windowDays: String(item.windowDays),
            ceilingText: String(format: "%.2f", item.ceiling),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toBatchedPriorityPreferenceViews(_ items: [BatchedPriorityPreference]) -> [BatchedPriorityPreferenceView] {
        var views: [BatchedPriorityPreferenceView] = []
        for item in items {
            views.append(toBatchedPriorityPreferenceView(item))
        }
        return views
    }

    static func sumBatchedPriorityPreferenceView(_ view: BatchedPriorityPreferenceView) throws -> Double {
        guard let parsedCapacity = Int(view.capacity) else {
            throw Kit.Failure("parse capacity: not a number")
        }
        guard let parsedDurationMinutes = Int(view.durationMinutes) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        guard let parsedAmount = Double(view.amount) else {
            throw Kit.Failure("parse amount: not a number")
        }
        return Double(parsedCapacity) + Double(parsedDurationMinutes) + parsedAmount
    }
}
