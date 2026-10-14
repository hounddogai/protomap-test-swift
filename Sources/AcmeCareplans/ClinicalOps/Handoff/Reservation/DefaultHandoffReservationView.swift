import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a default handoff reservation.
    final class DefaultHandoffReservationView {
        var codeText: String
        var title: String
        var currencyText: String
        var activeText: String
        var budget: String
        var durationMinutes: String
        var encounterID: String
        var procedureCode: String
        var statusLabel: String

        init(codeText: String, title: String, currencyText: String, activeText: String, budget: String, durationMinutes: String, encounterID: String, procedureCode: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.currencyText = currencyText
            self.activeText = activeText
            self.budget = budget
            self.durationMinutes = durationMinutes
            self.encounterID = encounterID
            self.procedureCode = procedureCode
            self.statusLabel = statusLabel
        }
    }

    static func toDefaultHandoffReservationView(_ item: DefaultHandoffReservation) -> DefaultHandoffReservationView {
        return DefaultHandoffReservationView(
            codeText: item.code,
            title: item.title,
            currencyText: item.currency,
            activeText: "\(item.active)",
            budget: String(format: "%.2f", item.budget),
            durationMinutes: String(item.durationMinutes),
            encounterID: Kit.Text.truncate(item.encounterID, limit: 64),
            procedureCode: item.procedureCode,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toDefaultHandoffReservationViews(_ items: [DefaultHandoffReservation]) -> [DefaultHandoffReservationView] {
        var views: [DefaultHandoffReservationView] = []
        for item in items {
            views.append(toDefaultHandoffReservationView(item))
        }
        return views
    }

    static func sumDefaultHandoffReservationView(_ view: DefaultHandoffReservationView) throws -> Double {
        guard let parsedBudget = Double(view.budget) else {
            throw Kit.Failure("parse budget: not a number")
        }
        guard let parsedDurationMinutes = Int(view.durationMinutes) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        return parsedBudget + Double(parsedDurationMinutes)
    }
}
