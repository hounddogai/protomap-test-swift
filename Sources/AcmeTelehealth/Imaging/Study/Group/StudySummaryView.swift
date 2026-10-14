import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a study summary.
    final class StudySummaryView {
        var code: String
        var title: String
        var maximum: String
        var ceiling: String
        var channel: String
        var capacity: String
        var description: String
        var statusLabel: String

        init(code: String, title: String, maximum: String, ceiling: String, channel: String, capacity: String, description: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.maximum = maximum
            self.ceiling = ceiling
            self.channel = channel
            self.capacity = capacity
            self.description = description
            self.statusLabel = statusLabel
        }
    }

    static func toStudySummaryView(_ item: StudySummary) -> StudySummaryView {
        return StudySummaryView(
            code: item.code,
            title: item.title,
            maximum: String(format: "%.2f", item.maximum),
            ceiling: String(format: "%.2f", item.ceiling),
            channel: item.channel,
            capacity: String(item.capacity),
            description: item.description,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toStudySummaryViews(_ items: [StudySummary]) -> [StudySummaryView] {
        var views: [StudySummaryView] = []
        for item in items {
            views.append(toStudySummaryView(item))
        }
        return views
    }

    static func sumStudySummaryView(_ view: StudySummaryView) throws -> Double {
        guard let parsedMaximum = Double(view.maximum) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        guard let parsedCeiling = Double(view.ceiling) else {
            throw Kit.Failure("parse ceiling: not a number")
        }
        guard let parsedCapacity = Int(view.capacity) else {
            throw Kit.Failure("parse capacity: not a number")
        }
        return parsedMaximum + parsedCeiling + Double(parsedCapacity)
    }
}
