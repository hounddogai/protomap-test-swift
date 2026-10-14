import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a read reservation.
    final class ReadReservationView {
        var codeText: String
        var label: String
        var margin: String
        var bed: String
        var amountText: String
        var discountText: String
        var updatedAt: String
        var budget: String
        var statusLabel: String

        init(codeText: String, label: String, margin: String, bed: String, amountText: String, discountText: String, updatedAt: String, budget: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.margin = margin
            self.bed = bed
            self.amountText = amountText
            self.discountText = discountText
            self.updatedAt = updatedAt
            self.budget = budget
            self.statusLabel = statusLabel
        }
    }

    static func toReadReservationView(_ item: ReadReservation) -> ReadReservationView {
        return ReadReservationView(
            codeText: item.code,
            label: item.label,
            margin: String(format: "%.2f", item.margin),
            bed: Kit.Text.truncate(item.bed, limit: 40),
            amountText: String(format: "%.2f", item.amount),
            discountText: String(format: "%.2f", item.discount),
            updatedAt: String(item.updatedAt),
            budget: String(format: "%.2f", item.budget),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toReadReservationViews(_ items: [ReadReservation]) -> [ReadReservationView] {
        var views: [ReadReservationView] = []
        for item in items {
            views.append(toReadReservationView(item))
        }
        return views
    }

    static func sumReadReservationView(_ view: ReadReservationView) throws -> Double {
        guard let parsedMargin = Double(view.margin) else {
            throw Kit.Failure("parse margin: not a number")
        }
        guard let parsedAmount = Double(view.amountText) else {
            throw Kit.Failure("parse amount: not a number")
        }
        guard let parsedDiscount = Double(view.discountText) else {
            throw Kit.Failure("parse discount: not a number")
        }
        return parsedMargin + parsedAmount + parsedDiscount
    }
}
