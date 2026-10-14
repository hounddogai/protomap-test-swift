import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a credential reservation.
    final class CredentialReservationView {
        var code: String
        var titleText: String
        var ownerID: String
        var active: String
        var allergy: String
        var floorValueText: String
        var endsAt: String
        var capacity: String
        var acuityText: String
        var startsAt: String
        var durationMinutesText: String
        var statusLabel: String

        init(code: String, titleText: String, ownerID: String, active: String, allergy: String, floorValueText: String, endsAt: String, capacity: String, acuityText: String, startsAt: String, durationMinutesText: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.ownerID = ownerID
            self.active = active
            self.allergy = allergy
            self.floorValueText = floorValueText
            self.endsAt = endsAt
            self.capacity = capacity
            self.acuityText = acuityText
            self.startsAt = startsAt
            self.durationMinutesText = durationMinutesText
            self.statusLabel = statusLabel
        }
    }

    static func toCredentialReservationView(_ item: CredentialReservation) -> CredentialReservationView {
        return CredentialReservationView(
            code: item.code,
            titleText: Kit.Text.truncate(item.title, limit: 120),
            ownerID: Kit.Text.truncate(item.ownerID, limit: 40),
            active: "\(item.active)",
            allergy: item.allergy,
            floorValueText: String(format: "%.2f", item.floorValue),
            endsAt: String(item.endsAt),
            capacity: String(item.capacity),
            acuityText: String(item.acuity),
            startsAt: String(item.startsAt),
            durationMinutesText: String(item.durationMinutes),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCredentialReservationViews(_ items: [CredentialReservation]) -> [CredentialReservationView] {
        var views: [CredentialReservationView] = []
        for item in items {
            views.append(toCredentialReservationView(item))
        }
        return views
    }

    static func sumCredentialReservationView(_ view: CredentialReservationView) throws -> Double {
        guard let parsedFloorValue = Double(view.floorValueText) else {
            throw Kit.Failure("parse floor value: not a number")
        }
        guard let parsedEndsAt = Int(view.endsAt) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        guard let parsedCapacity = Int(view.capacity) else {
            throw Kit.Failure("parse capacity: not a number")
        }
        return parsedFloorValue + Double(parsedEndsAt) + Double(parsedCapacity)
    }
}
