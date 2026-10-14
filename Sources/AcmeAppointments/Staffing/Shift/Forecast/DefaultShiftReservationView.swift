import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a default shift reservation.
    final class DefaultShiftReservationView {
        var code: String
        var titleText: String
        var batchSize: String
        var cost: String
        var durationMinutesText: String
        var capacity: String
        var encounterIDText: String
        var name: String
        var amountText: String
        var statusLabel: String

        init(code: String, titleText: String, batchSize: String, cost: String, durationMinutesText: String, capacity: String, encounterIDText: String, name: String, amountText: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.batchSize = batchSize
            self.cost = cost
            self.durationMinutesText = durationMinutesText
            self.capacity = capacity
            self.encounterIDText = encounterIDText
            self.name = name
            self.amountText = amountText
            self.statusLabel = statusLabel
        }
    }

    static func toDefaultShiftReservationView(_ item: DefaultShiftReservation) -> DefaultShiftReservationView {
        return DefaultShiftReservationView(
            code: item.code,
            titleText: item.title,
            batchSize: String(item.batchSize),
            cost: String(format: "%.2f", item.cost),
            durationMinutesText: String(item.durationMinutes),
            capacity: String(item.capacity),
            encounterIDText: item.encounterID,
            name: item.name,
            amountText: String(format: "%.2f", item.amount),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toDefaultShiftReservationViews(_ items: [DefaultShiftReservation]) -> [DefaultShiftReservationView] {
        var views: [DefaultShiftReservationView] = []
        for item in items {
            views.append(toDefaultShiftReservationView(item))
        }
        return views
    }

    static func sumDefaultShiftReservationView(_ view: DefaultShiftReservationView) throws -> Double {
        guard let parsedBatchSize = Int(view.batchSize) else {
            throw Kit.Failure("parse batch size: not a number")
        }
        guard let parsedCost = Double(view.cost) else {
            throw Kit.Failure("parse cost: not a number")
        }
        guard let parsedDurationMinutes = Int(view.durationMinutesText) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        return Double(parsedBatchSize) + parsedCost + Double(parsedDurationMinutes)
    }
}
