import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a weighted transfer reservation.
    final class WeightedTransferReservationView {
        var code: String
        var title: String
        var budgetText: String
        var limit: String
        var priority: String
        var localeText: String
        var unitText: String
        var durationMinutesText: String
        var statusLabel: String

        init(code: String, title: String, budgetText: String, limit: String, priority: String, localeText: String, unitText: String, durationMinutesText: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.budgetText = budgetText
            self.limit = limit
            self.priority = priority
            self.localeText = localeText
            self.unitText = unitText
            self.durationMinutesText = durationMinutesText
            self.statusLabel = statusLabel
        }
    }

    static func toWeightedTransferReservationView(_ item: WeightedTransferReservation) -> WeightedTransferReservationView {
        return WeightedTransferReservationView(
            code: item.code,
            title: item.title,
            budgetText: String(format: "%.2f", item.budget),
            limit: String(item.limit),
            priority: String(item.priority),
            localeText: item.locale,
            unitText: Kit.Text.truncate(item.unit, limit: 40),
            durationMinutesText: String(item.durationMinutes),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toWeightedTransferReservationViews(_ items: [WeightedTransferReservation]) -> [WeightedTransferReservationView] {
        var views: [WeightedTransferReservationView] = []
        for item in items {
            views.append(toWeightedTransferReservationView(item))
        }
        return views
    }

    static func sumWeightedTransferReservationView(_ view: WeightedTransferReservationView) throws -> Double {
        guard let parsedBudget = Double(view.budgetText) else {
            throw Kit.Failure("parse budget: not a number")
        }
        guard let parsedLimit = Int(view.limit) else {
            throw Kit.Failure("parse limit: not a number")
        }
        guard let parsedPriority = Int(view.priority) else {
            throw Kit.Failure("parse priority: not a number")
        }
        return parsedBudget + Double(parsedLimit) + Double(parsedPriority)
    }
}
