import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a weighted credential reservation.
    final class WeightedCredentialReservationView {
        var code: String
        var titleText: String
        var specialty: String
        var maximum: String
        var phone: String
        var archived: String
        var country: String
        var statusLabel: String

        init(code: String, titleText: String, specialty: String, maximum: String, phone: String, archived: String, country: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.specialty = specialty
            self.maximum = maximum
            self.phone = phone
            self.archived = archived
            self.country = country
            self.statusLabel = statusLabel
        }
    }

    static func toWeightedCredentialReservationView(_ item: WeightedCredentialReservation) -> WeightedCredentialReservationView {
        return WeightedCredentialReservationView(
            code: item.code,
            titleText: item.title,
            specialty: item.specialty,
            maximum: String(format: "%.2f", item.maximum),
            phone: Kit.Text.truncate(item.phone, limit: 120),
            archived: "\(item.archived)",
            country: item.country,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toWeightedCredentialReservationViews(_ items: [WeightedCredentialReservation]) -> [WeightedCredentialReservationView] {
        var views: [WeightedCredentialReservationView] = []
        for item in items {
            views.append(toWeightedCredentialReservationView(item))
        }
        return views
    }

    static func sumWeightedCredentialReservationView(_ view: WeightedCredentialReservationView) throws -> Double {
        guard let parsedMaximum = Double(view.maximum) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        return parsedMaximum
    }
}
