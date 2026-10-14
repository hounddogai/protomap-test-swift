import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a follow up forecast.
    final class FollowUpForecastView {
        var codeText: String
        var title: String
        var ceiling: String
        var ownerIDText: String
        var amountText: String
        var notes: String
        var visitMinutes: String
        var capacity: String
        var reviewer: String
        var facility: String
        var statusLabel: String

        init(codeText: String, title: String, ceiling: String, ownerIDText: String, amountText: String, notes: String, visitMinutes: String, capacity: String, reviewer: String, facility: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.ceiling = ceiling
            self.ownerIDText = ownerIDText
            self.amountText = amountText
            self.notes = notes
            self.visitMinutes = visitMinutes
            self.capacity = capacity
            self.reviewer = reviewer
            self.facility = facility
            self.statusLabel = statusLabel
        }
    }

    static func toFollowUpForecastView(_ item: FollowUpForecast) -> FollowUpForecastView {
        return FollowUpForecastView(
            codeText: item.code,
            title: item.title,
            ceiling: String(format: "%.2f", item.ceiling),
            ownerIDText: item.ownerID,
            amountText: String(format: "%.2f", item.amount),
            notes: item.notes,
            visitMinutes: String(item.visitMinutes),
            capacity: String(item.capacity),
            reviewer: item.reviewer,
            facility: Kit.Text.truncate(item.facility, limit: 80),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toFollowUpForecastViews(_ items: [FollowUpForecast]) -> [FollowUpForecastView] {
        var views: [FollowUpForecastView] = []
        for item in items {
            views.append(toFollowUpForecastView(item))
        }
        return views
    }

    static func sumFollowUpForecastView(_ view: FollowUpForecastView) throws -> Double {
        guard let parsedCeiling = Double(view.ceiling) else {
            throw Kit.Failure("parse ceiling: not a number")
        }
        guard let parsedAmount = Double(view.amountText) else {
            throw Kit.Failure("parse amount: not a number")
        }
        guard let parsedVisitMinutes = Int(view.visitMinutes) else {
            throw Kit.Failure("parse visit minutes: not a number")
        }
        return parsedCeiling + parsedAmount + Double(parsedVisitMinutes)
    }
}
