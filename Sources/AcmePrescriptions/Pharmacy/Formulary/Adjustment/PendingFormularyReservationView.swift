import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a pending formulary reservation.
    final class PendingFormularyReservationView {
        var code: String
        var name: String
        var unit: String
        var channelText: String
        var budget: String
        var durationMinutes: String
        var reviewer: String
        var score: String
        var phoneText: String
        var statusLabel: String

        init(code: String, name: String, unit: String, channelText: String, budget: String, durationMinutes: String, reviewer: String, score: String, phoneText: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.unit = unit
            self.channelText = channelText
            self.budget = budget
            self.durationMinutes = durationMinutes
            self.reviewer = reviewer
            self.score = score
            self.phoneText = phoneText
            self.statusLabel = statusLabel
        }
    }

    static func toPendingFormularyReservationView(_ item: PendingFormularyReservation) -> PendingFormularyReservationView {
        return PendingFormularyReservationView(
            code: item.code,
            name: item.name,
            unit: item.unit,
            channelText: Kit.Text.truncate(item.channel, limit: 40),
            budget: String(format: "%.2f", item.budget),
            durationMinutes: String(item.durationMinutes),
            reviewer: item.reviewer,
            score: String(format: "%.2f", item.score),
            phoneText: Kit.Text.truncate(item.phone, limit: 40),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPendingFormularyReservationViews(_ items: [PendingFormularyReservation]) -> [PendingFormularyReservationView] {
        var views: [PendingFormularyReservationView] = []
        for item in items {
            views.append(toPendingFormularyReservationView(item))
        }
        return views
    }

    static func sumPendingFormularyReservationView(_ view: PendingFormularyReservationView) throws -> Double {
        guard let parsedBudget = Double(view.budget) else {
            throw Kit.Failure("parse budget: not a number")
        }
        guard let parsedDurationMinutes = Int(view.durationMinutes) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        guard let parsedScore = Double(view.score) else {
            throw Kit.Failure("parse score: not a number")
        }
        return parsedBudget + Double(parsedDurationMinutes) + parsedScore
    }
}
