import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a care gap reservation.
    final class CareGapReservationView {
        var code: String
        var name: String
        var attemptsText: String
        var unitText: String
        var pinnedText: String
        var batchSizeText: String
        var statusLabel: String

        init(code: String, name: String, attemptsText: String, unitText: String, pinnedText: String, batchSizeText: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.attemptsText = attemptsText
            self.unitText = unitText
            self.pinnedText = pinnedText
            self.batchSizeText = batchSizeText
            self.statusLabel = statusLabel
        }
    }

    static func toCareGapReservationView(_ item: CareGapReservation) -> CareGapReservationView {
        return CareGapReservationView(
            code: Kit.Text.truncate(item.code, limit: 80),
            name: item.name,
            attemptsText: String(item.attempts),
            unitText: item.unit,
            pinnedText: "\(item.pinned)",
            batchSizeText: String(item.batchSize),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCareGapReservationViews(_ items: [CareGapReservation]) -> [CareGapReservationView] {
        var views: [CareGapReservationView] = []
        for item in items {
            views.append(toCareGapReservationView(item))
        }
        return views
    }

    static func sumCareGapReservationView(_ view: CareGapReservationView) throws -> Double {
        guard let parsedAttempts = Int(view.attemptsText) else {
            throw Kit.Failure("parse attempts: not a number")
        }
        guard let parsedBatchSize = Int(view.batchSizeText) else {
            throw Kit.Failure("parse batch size: not a number")
        }
        return Double(parsedAttempts) + Double(parsedBatchSize)
    }
}
