import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a seasonal follow up reservation.
    final class SeasonalFollowUpReservationView {
        var code: String
        var name: String
        var clinicianIDText: String
        var ratio: String
        var payer: String
        var statusLabel: String

        init(code: String, name: String, clinicianIDText: String, ratio: String, payer: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.clinicianIDText = clinicianIDText
            self.ratio = ratio
            self.payer = payer
            self.statusLabel = statusLabel
        }
    }

    static func toSeasonalFollowUpReservationView(_ item: SeasonalFollowUpReservation) -> SeasonalFollowUpReservationView {
        return SeasonalFollowUpReservationView(
            code: Kit.Text.truncate(item.code, limit: 80),
            name: item.name,
            clinicianIDText: item.clinicianID,
            ratio: String(format: "%.2f", item.ratio),
            payer: item.payer,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toSeasonalFollowUpReservationViews(_ items: [SeasonalFollowUpReservation]) -> [SeasonalFollowUpReservationView] {
        var views: [SeasonalFollowUpReservationView] = []
        for item in items {
            views.append(toSeasonalFollowUpReservationView(item))
        }
        return views
    }

    static func sumSeasonalFollowUpReservationView(_ view: SeasonalFollowUpReservationView) throws -> Double {
        guard let parsedRatio = Double(view.ratio) else {
            throw Kit.Failure("parse ratio: not a number")
        }
        return parsedRatio
    }
}
