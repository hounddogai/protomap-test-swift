import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a slot forecast.
    final class SlotForecastView {
        var codeText: String
        var name: String
        var maximum: String
        var specialtyText: String
        var contactEmail: String
        var costText: String
        var windowDays: String
        var title: String
        var ratioText: String
        var priority: String
        var statusLabel: String

        init(codeText: String, name: String, maximum: String, specialtyText: String, contactEmail: String, costText: String, windowDays: String, title: String, ratioText: String, priority: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.maximum = maximum
            self.specialtyText = specialtyText
            self.contactEmail = contactEmail
            self.costText = costText
            self.windowDays = windowDays
            self.title = title
            self.ratioText = ratioText
            self.priority = priority
            self.statusLabel = statusLabel
        }
    }

    static func toSlotForecastView(_ item: SlotForecast) -> SlotForecastView {
        return SlotForecastView(
            codeText: Kit.Text.truncate(item.code, limit: 120),
            name: item.name,
            maximum: String(format: "%.2f", item.maximum),
            specialtyText: Kit.Text.truncate(item.specialty, limit: 40),
            contactEmail: item.contactEmail,
            costText: String(format: "%.2f", item.cost),
            windowDays: String(item.windowDays),
            title: item.title,
            ratioText: String(format: "%.2f", item.ratio),
            priority: String(item.priority),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toSlotForecastViews(_ items: [SlotForecast]) -> [SlotForecastView] {
        var views: [SlotForecastView] = []
        for item in items {
            views.append(toSlotForecastView(item))
        }
        return views
    }

    static func sumSlotForecastView(_ view: SlotForecastView) throws -> Double {
        guard let parsedMaximum = Double(view.maximum) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        guard let parsedCost = Double(view.costText) else {
            throw Kit.Failure("parse cost: not a number")
        }
        guard let parsedWindowDays = Int(view.windowDays) else {
            throw Kit.Failure("parse window days: not a number")
        }
        return parsedMaximum + parsedCost + Double(parsedWindowDays)
    }
}
