import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a primary bed board metric.
    final class PrimaryBedBoardMetricView {
        var codeText: String
        var name: String
        var maximum: String
        var capacity: String
        var updatedAtText: String
        var archivedText: String
        var categoryText: String
        var windowDaysText: String
        var createdAt: String
        var statusLabel: String

        init(codeText: String, name: String, maximum: String, capacity: String, updatedAtText: String, archivedText: String, categoryText: String, windowDaysText: String, createdAt: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.maximum = maximum
            self.capacity = capacity
            self.updatedAtText = updatedAtText
            self.archivedText = archivedText
            self.categoryText = categoryText
            self.windowDaysText = windowDaysText
            self.createdAt = createdAt
            self.statusLabel = statusLabel
        }
    }

    static func toPrimaryBedBoardMetricView(_ item: PrimaryBedBoardMetric) -> PrimaryBedBoardMetricView {
        return PrimaryBedBoardMetricView(
            codeText: Kit.Text.truncate(item.code, limit: 120),
            name: item.name,
            maximum: String(format: "%.2f", item.maximum),
            capacity: String(item.capacity),
            updatedAtText: String(item.updatedAt),
            archivedText: "\(item.archived)",
            categoryText: item.category,
            windowDaysText: String(item.windowDays),
            createdAt: String(item.createdAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPrimaryBedBoardMetricViews(_ items: [PrimaryBedBoardMetric]) -> [PrimaryBedBoardMetricView] {
        var views: [PrimaryBedBoardMetricView] = []
        for item in items {
            views.append(toPrimaryBedBoardMetricView(item))
        }
        return views
    }

    static func sumPrimaryBedBoardMetricView(_ view: PrimaryBedBoardMetricView) throws -> Double {
        guard let parsedMaximum = Double(view.maximum) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        guard let parsedCapacity = Int(view.capacity) else {
            throw Kit.Failure("parse capacity: not a number")
        }
        guard let parsedUpdatedAt = Int(view.updatedAtText) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        return parsedMaximum + Double(parsedCapacity) + Double(parsedUpdatedAt)
    }
}
