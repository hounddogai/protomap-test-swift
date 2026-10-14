import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a default courier slot.
    final class DefaultCourierSlotView {
        var code: String
        var name: String
        var capacity: String
        var amountText: String
        var durationMinutes: String
        var visibleText: String
        var startsAt: String
        var budget: String
        var windowDays: String
        var statusLabel: String

        init(code: String, name: String, capacity: String, amountText: String, durationMinutes: String, visibleText: String, startsAt: String, budget: String, windowDays: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.capacity = capacity
            self.amountText = amountText
            self.durationMinutes = durationMinutes
            self.visibleText = visibleText
            self.startsAt = startsAt
            self.budget = budget
            self.windowDays = windowDays
            self.statusLabel = statusLabel
        }
    }

    static func toDefaultCourierSlotView(_ item: DefaultCourierSlot) -> DefaultCourierSlotView {
        return DefaultCourierSlotView(
            code: item.code,
            name: item.name,
            capacity: String(item.capacity),
            amountText: String(format: "%.2f", item.amount),
            durationMinutes: String(item.durationMinutes),
            visibleText: "\(item.visible)",
            startsAt: String(item.startsAt),
            budget: String(format: "%.2f", item.budget),
            windowDays: String(item.windowDays),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toDefaultCourierSlotViews(_ items: [DefaultCourierSlot]) -> [DefaultCourierSlotView] {
        var views: [DefaultCourierSlotView] = []
        for item in items {
            views.append(toDefaultCourierSlotView(item))
        }
        return views
    }

    static func sumDefaultCourierSlotView(_ view: DefaultCourierSlotView) throws -> Double {
        guard let parsedCapacity = Int(view.capacity) else {
            throw Kit.Failure("parse capacity: not a number")
        }
        guard let parsedAmount = Double(view.amountText) else {
            throw Kit.Failure("parse amount: not a number")
        }
        guard let parsedDurationMinutes = Int(view.durationMinutes) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        return Double(parsedCapacity) + parsedAmount + Double(parsedDurationMinutes)
    }
}
