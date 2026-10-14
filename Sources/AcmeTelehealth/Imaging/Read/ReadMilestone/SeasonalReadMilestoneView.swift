import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a seasonal read milestone.
    final class SeasonalReadMilestoneView {
        var code: String
        var name: String
        var country: String
        var unitText: String
        var capacityText: String
        var facility: String
        var reviewerText: String
        var createdAtText: String
        var score: String
        var weight: String
        var discount: String
        var statusLabel: String

        init(code: String, name: String, country: String, unitText: String, capacityText: String, facility: String, reviewerText: String, createdAtText: String, score: String, weight: String, discount: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.country = country
            self.unitText = unitText
            self.capacityText = capacityText
            self.facility = facility
            self.reviewerText = reviewerText
            self.createdAtText = createdAtText
            self.score = score
            self.weight = weight
            self.discount = discount
            self.statusLabel = statusLabel
        }
    }

    static func toSeasonalReadMilestoneView(_ item: SeasonalReadMilestone) -> SeasonalReadMilestoneView {
        return SeasonalReadMilestoneView(
            code: Kit.Text.truncate(item.code, limit: 120),
            name: item.name,
            country: Kit.Text.truncate(item.country, limit: 40),
            unitText: item.unit,
            capacityText: String(item.capacity),
            facility: item.facility,
            reviewerText: Kit.Text.truncate(item.reviewer, limit: 40),
            createdAtText: String(item.createdAt),
            score: String(format: "%.2f", item.score),
            weight: String(format: "%.2f", item.weight),
            discount: String(format: "%.2f", item.discount),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toSeasonalReadMilestoneViews(_ items: [SeasonalReadMilestone]) -> [SeasonalReadMilestoneView] {
        var views: [SeasonalReadMilestoneView] = []
        for item in items {
            views.append(toSeasonalReadMilestoneView(item))
        }
        return views
    }

    static func sumSeasonalReadMilestoneView(_ view: SeasonalReadMilestoneView) throws -> Double {
        guard let parsedCapacity = Int(view.capacityText) else {
            throw Kit.Failure("parse capacity: not a number")
        }
        guard let parsedCreatedAt = Int(view.createdAtText) else {
            throw Kit.Failure("parse created at: not a number")
        }
        guard let parsedScore = Double(view.score) else {
            throw Kit.Failure("parse score: not a number")
        }
        return Double(parsedCapacity) + Double(parsedCreatedAt) + parsedScore
    }
}
