import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a scheduled specimen tier.
    final class ScheduledSpecimenTierView {
        var code: String
        var title: String
        var ceiling: String
        var minimum: String
        var maximum: String
        var retriesText: String
        var copay: String
        var description: String
        var statusLabel: String

        init(code: String, title: String, ceiling: String, minimum: String, maximum: String, retriesText: String, copay: String, description: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.ceiling = ceiling
            self.minimum = minimum
            self.maximum = maximum
            self.retriesText = retriesText
            self.copay = copay
            self.description = description
            self.statusLabel = statusLabel
        }
    }

    static func toScheduledSpecimenTierView(_ item: ScheduledSpecimenTier) -> ScheduledSpecimenTierView {
        return ScheduledSpecimenTierView(
            code: item.code,
            title: item.title,
            ceiling: String(format: "%.2f", item.ceiling),
            minimum: String(format: "%.2f", item.minimum),
            maximum: String(format: "%.2f", item.maximum),
            retriesText: String(item.retries),
            copay: String(format: "%.2f", item.copay),
            description: item.description,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toScheduledSpecimenTierViews(_ items: [ScheduledSpecimenTier]) -> [ScheduledSpecimenTierView] {
        var views: [ScheduledSpecimenTierView] = []
        for item in items {
            views.append(toScheduledSpecimenTierView(item))
        }
        return views
    }

    static func sumScheduledSpecimenTierView(_ view: ScheduledSpecimenTierView) throws -> Double {
        guard let parsedCeiling = Double(view.ceiling) else {
            throw Kit.Failure("parse ceiling: not a number")
        }
        guard let parsedMinimum = Double(view.minimum) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        guard let parsedMaximum = Double(view.maximum) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        return parsedCeiling + parsedMinimum + parsedMaximum
    }
}
