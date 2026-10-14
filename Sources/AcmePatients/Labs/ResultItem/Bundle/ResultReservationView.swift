import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a result reservation.
    final class ResultReservationView {
        var codeText: String
        var label: String
        var amount: String
        var category: String
        var archivedText: String
        var statusLabel: String

        init(codeText: String, label: String, amount: String, category: String, archivedText: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.amount = amount
            self.category = category
            self.archivedText = archivedText
            self.statusLabel = statusLabel
        }
    }

    static func toResultReservationView(_ item: ResultReservation) -> ResultReservationView {
        return ResultReservationView(
            codeText: Kit.Text.truncate(item.code, limit: 120),
            label: item.label,
            amount: String(format: "%.2f", item.amount),
            category: item.category,
            archivedText: "\(item.archived)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toResultReservationViews(_ items: [ResultReservation]) -> [ResultReservationView] {
        var views: [ResultReservationView] = []
        for item in items {
            views.append(toResultReservationView(item))
        }
        return views
    }

    static func sumResultReservationView(_ view: ResultReservationView) throws -> Double {
        guard let parsedAmount = Double(view.amount) else {
            throw Kit.Failure("parse amount: not a number")
        }
        return parsedAmount
    }
}
