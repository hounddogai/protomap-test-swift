import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a pending overtime reservation.
    final class PendingOvertimeReservationView {
        var code: String
        var titleText: String
        var ward: String
        var createdAt: String
        var limit: String
        var currency: String
        var dosageMg: String
        var ratio: String
        var statusLabel: String

        init(code: String, titleText: String, ward: String, createdAt: String, limit: String, currency: String, dosageMg: String, ratio: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.ward = ward
            self.createdAt = createdAt
            self.limit = limit
            self.currency = currency
            self.dosageMg = dosageMg
            self.ratio = ratio
            self.statusLabel = statusLabel
        }
    }

    static func toPendingOvertimeReservationView(_ item: PendingOvertimeReservation) -> PendingOvertimeReservationView {
        return PendingOvertimeReservationView(
            code: item.code,
            titleText: item.title,
            ward: Kit.Text.truncate(item.ward, limit: 80),
            createdAt: String(item.createdAt),
            limit: String(item.limit),
            currency: Kit.Text.truncate(item.currency, limit: 40),
            dosageMg: String(format: "%.2f", item.dosageMg),
            ratio: String(format: "%.2f", item.ratio),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPendingOvertimeReservationViews(_ items: [PendingOvertimeReservation]) -> [PendingOvertimeReservationView] {
        var views: [PendingOvertimeReservationView] = []
        for item in items {
            views.append(toPendingOvertimeReservationView(item))
        }
        return views
    }

    static func sumPendingOvertimeReservationView(_ view: PendingOvertimeReservationView) throws -> Double {
        guard let parsedCreatedAt = Int(view.createdAt) else {
            throw Kit.Failure("parse created at: not a number")
        }
        guard let parsedLimit = Int(view.limit) else {
            throw Kit.Failure("parse limit: not a number")
        }
        guard let parsedDosageMg = Double(view.dosageMg) else {
            throw Kit.Failure("parse dosage mg: not a number")
        }
        return Double(parsedCreatedAt) + Double(parsedLimit) + parsedDosageMg
    }
}
