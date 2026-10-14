import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a default cleaning reservation.
    final class DefaultCleaningReservationView {
        var code: String
        var labelText: String
        var cost: String
        var endsAt: String
        var channel: String
        var ceilingText: String
        var sequence: String
        var statusLabel: String

        init(code: String, labelText: String, cost: String, endsAt: String, channel: String, ceilingText: String, sequence: String, statusLabel: String) {
            self.code = code
            self.labelText = labelText
            self.cost = cost
            self.endsAt = endsAt
            self.channel = channel
            self.ceilingText = ceilingText
            self.sequence = sequence
            self.statusLabel = statusLabel
        }
    }

    static func toDefaultCleaningReservationView(_ item: DefaultCleaningReservation) -> DefaultCleaningReservationView {
        return DefaultCleaningReservationView(
            code: Kit.Text.truncate(item.code, limit: 64),
            labelText: Kit.Text.truncate(item.label, limit: 40),
            cost: String(format: "%.2f", item.cost),
            endsAt: String(item.endsAt),
            channel: item.channel,
            ceilingText: String(format: "%.2f", item.ceiling),
            sequence: String(item.sequence),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toDefaultCleaningReservationViews(_ items: [DefaultCleaningReservation]) -> [DefaultCleaningReservationView] {
        var views: [DefaultCleaningReservationView] = []
        for item in items {
            views.append(toDefaultCleaningReservationView(item))
        }
        return views
    }

    static func sumDefaultCleaningReservationView(_ view: DefaultCleaningReservationView) throws -> Double {
        guard let parsedCost = Double(view.cost) else {
            throw Kit.Failure("parse cost: not a number")
        }
        guard let parsedEndsAt = Int(view.endsAt) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        guard let parsedCeiling = Double(view.ceilingText) else {
            throw Kit.Failure("parse ceiling: not a number")
        }
        return parsedCost + Double(parsedEndsAt) + parsedCeiling
    }
}
