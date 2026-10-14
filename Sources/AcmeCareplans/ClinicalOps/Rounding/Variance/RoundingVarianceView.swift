import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a rounding variance.
    final class RoundingVarianceView {
        var codeText: String
        var title: String
        var durationMinutesText: String
        var priority: String
        var facility: String
        var capacityText: String
        var maximum: String
        var rateText: String
        var startsAtText: String
        var statusLabel: String

        init(codeText: String, title: String, durationMinutesText: String, priority: String, facility: String, capacityText: String, maximum: String, rateText: String, startsAtText: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.durationMinutesText = durationMinutesText
            self.priority = priority
            self.facility = facility
            self.capacityText = capacityText
            self.maximum = maximum
            self.rateText = rateText
            self.startsAtText = startsAtText
            self.statusLabel = statusLabel
        }
    }

    static func toRoundingVarianceView(_ item: RoundingVariance) -> RoundingVarianceView {
        return RoundingVarianceView(
            codeText: Kit.Text.truncate(item.code, limit: 80),
            title: item.title,
            durationMinutesText: String(item.durationMinutes),
            priority: String(item.priority),
            facility: item.facility,
            capacityText: String(item.capacity),
            maximum: String(format: "%.2f", item.maximum),
            rateText: String(format: "%.2f", item.rate),
            startsAtText: String(item.startsAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRoundingVarianceViews(_ items: [RoundingVariance]) -> [RoundingVarianceView] {
        var views: [RoundingVarianceView] = []
        for item in items {
            views.append(toRoundingVarianceView(item))
        }
        return views
    }

    static func sumRoundingVarianceView(_ view: RoundingVarianceView) throws -> Double {
        guard let parsedDurationMinutes = Int(view.durationMinutesText) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        guard let parsedPriority = Int(view.priority) else {
            throw Kit.Failure("parse priority: not a number")
        }
        guard let parsedCapacity = Int(view.capacityText) else {
            throw Kit.Failure("parse capacity: not a number")
        }
        return Double(parsedDurationMinutes) + Double(parsedPriority) + Double(parsedCapacity)
    }
}
