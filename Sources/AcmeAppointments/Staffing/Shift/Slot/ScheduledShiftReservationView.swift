import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a scheduled shift reservation.
    final class ScheduledShiftReservationView {
        var code: String
        var title: String
        var region: String
        var updatedAt: String
        var encounterID: String
        var maximumText: String
        var acuity: String
        var contactEmail: String
        var statusLabel: String

        init(code: String, title: String, region: String, updatedAt: String, encounterID: String, maximumText: String, acuity: String, contactEmail: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.region = region
            self.updatedAt = updatedAt
            self.encounterID = encounterID
            self.maximumText = maximumText
            self.acuity = acuity
            self.contactEmail = contactEmail
            self.statusLabel = statusLabel
        }
    }

    static func toScheduledShiftReservationView(_ item: ScheduledShiftReservation) -> ScheduledShiftReservationView {
        return ScheduledShiftReservationView(
            code: Kit.Text.truncate(item.code, limit: 40),
            title: item.title,
            region: item.region,
            updatedAt: String(item.updatedAt),
            encounterID: item.encounterID,
            maximumText: String(format: "%.2f", item.maximum),
            acuity: String(item.acuity),
            contactEmail: item.contactEmail,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toScheduledShiftReservationViews(_ items: [ScheduledShiftReservation]) -> [ScheduledShiftReservationView] {
        var views: [ScheduledShiftReservationView] = []
        for item in items {
            views.append(toScheduledShiftReservationView(item))
        }
        return views
    }

    static func sumScheduledShiftReservationView(_ view: ScheduledShiftReservationView) throws -> Double {
        guard let parsedUpdatedAt = Int(view.updatedAt) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        guard let parsedMaximum = Double(view.maximumText) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        guard let parsedAcuity = Int(view.acuity) else {
            throw Kit.Failure("parse acuity: not a number")
        }
        return Double(parsedUpdatedAt) + parsedMaximum + Double(parsedAcuity)
    }
}
