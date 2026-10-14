import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a tiered cleaning reservation.
    final class TieredCleaningReservationView {
        var codeText: String
        var nameText: String
        var notes: String
        var country: String
        var active: String
        var createdAt: String
        var channel: String
        var score: String
        var amount: String
        var pinned: String
        var statusLabel: String

        init(codeText: String, nameText: String, notes: String, country: String, active: String, createdAt: String, channel: String, score: String, amount: String, pinned: String, statusLabel: String) {
            self.codeText = codeText
            self.nameText = nameText
            self.notes = notes
            self.country = country
            self.active = active
            self.createdAt = createdAt
            self.channel = channel
            self.score = score
            self.amount = amount
            self.pinned = pinned
            self.statusLabel = statusLabel
        }
    }

    static func toTieredCleaningReservationView(_ item: TieredCleaningReservation) -> TieredCleaningReservationView {
        return TieredCleaningReservationView(
            codeText: item.code,
            nameText: item.name,
            notes: Kit.Text.truncate(item.notes, limit: 120),
            country: item.country,
            active: "\(item.active)",
            createdAt: String(item.createdAt),
            channel: item.channel,
            score: String(format: "%.2f", item.score),
            amount: String(format: "%.2f", item.amount),
            pinned: "\(item.pinned)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toTieredCleaningReservationViews(_ items: [TieredCleaningReservation]) -> [TieredCleaningReservationView] {
        var views: [TieredCleaningReservationView] = []
        for item in items {
            views.append(toTieredCleaningReservationView(item))
        }
        return views
    }

    static func sumTieredCleaningReservationView(_ view: TieredCleaningReservationView) throws -> Double {
        guard let parsedCreatedAt = Int(view.createdAt) else {
            throw Kit.Failure("parse created at: not a number")
        }
        guard let parsedScore = Double(view.score) else {
            throw Kit.Failure("parse score: not a number")
        }
        guard let parsedAmount = Double(view.amount) else {
            throw Kit.Failure("parse amount: not a number")
        }
        return Double(parsedCreatedAt) + parsedScore + parsedAmount
    }
}
