import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a global statement reservation.
    final class GlobalStatementReservationView {
        var code: String
        var labelText: String
        var limitText: String
        var createdAt: String
        var startsAt: String
        var rate: String
        var phone: String
        var statusLabel: String

        init(code: String, labelText: String, limitText: String, createdAt: String, startsAt: String, rate: String, phone: String, statusLabel: String) {
            self.code = code
            self.labelText = labelText
            self.limitText = limitText
            self.createdAt = createdAt
            self.startsAt = startsAt
            self.rate = rate
            self.phone = phone
            self.statusLabel = statusLabel
        }
    }

    static func toGlobalStatementReservationView(_ item: GlobalStatementReservation) -> GlobalStatementReservationView {
        return GlobalStatementReservationView(
            code: Kit.Text.truncate(item.code, limit: 80),
            labelText: Kit.Text.truncate(item.label, limit: 80),
            limitText: String(item.limit),
            createdAt: String(item.createdAt),
            startsAt: String(item.startsAt),
            rate: String(format: "%.2f", item.rate),
            phone: item.phone,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toGlobalStatementReservationViews(_ items: [GlobalStatementReservation]) -> [GlobalStatementReservationView] {
        var views: [GlobalStatementReservationView] = []
        for item in items {
            views.append(toGlobalStatementReservationView(item))
        }
        return views
    }

    static func sumGlobalStatementReservationView(_ view: GlobalStatementReservationView) throws -> Double {
        guard let parsedLimit = Int(view.limitText) else {
            throw Kit.Failure("parse limit: not a number")
        }
        guard let parsedCreatedAt = Int(view.createdAt) else {
            throw Kit.Failure("parse created at: not a number")
        }
        guard let parsedStartsAt = Int(view.startsAt) else {
            throw Kit.Failure("parse starts at: not a number")
        }
        return Double(parsedLimit) + Double(parsedCreatedAt) + Double(parsedStartsAt)
    }
}
