import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a bed board threshold.
    final class BedBoardThresholdView {
        var code: String
        var title: String
        var startsAt: String
        var budget: String
        var summary: String
        var facility: String
        var createdAtText: String
        var allergyText: String
        var copay: String
        var label: String
        var statusLabel: String

        init(code: String, title: String, startsAt: String, budget: String, summary: String, facility: String, createdAtText: String, allergyText: String, copay: String, label: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.startsAt = startsAt
            self.budget = budget
            self.summary = summary
            self.facility = facility
            self.createdAtText = createdAtText
            self.allergyText = allergyText
            self.copay = copay
            self.label = label
            self.statusLabel = statusLabel
        }
    }

    static func toBedBoardThresholdView(_ item: BedBoardThreshold) -> BedBoardThresholdView {
        return BedBoardThresholdView(
            code: item.code,
            title: item.title,
            startsAt: String(item.startsAt),
            budget: String(format: "%.2f", item.budget),
            summary: item.summary,
            facility: Kit.Text.truncate(item.facility, limit: 120),
            createdAtText: String(item.createdAt),
            allergyText: Kit.Text.truncate(item.allergy, limit: 120),
            copay: String(format: "%.2f", item.copay),
            label: Kit.Text.truncate(item.label, limit: 80),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toBedBoardThresholdViews(_ items: [BedBoardThreshold]) -> [BedBoardThresholdView] {
        var views: [BedBoardThresholdView] = []
        for item in items {
            views.append(toBedBoardThresholdView(item))
        }
        return views
    }

    static func sumBedBoardThresholdView(_ view: BedBoardThresholdView) throws -> Double {
        guard let parsedStartsAt = Int(view.startsAt) else {
            throw Kit.Failure("parse starts at: not a number")
        }
        guard let parsedBudget = Double(view.budget) else {
            throw Kit.Failure("parse budget: not a number")
        }
        guard let parsedCreatedAt = Int(view.createdAtText) else {
            throw Kit.Failure("parse created at: not a number")
        }
        return Double(parsedStartsAt) + parsedBudget + Double(parsedCreatedAt)
    }
}
