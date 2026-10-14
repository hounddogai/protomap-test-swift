import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a rolling disclosure reservation.
    final class RollingDisclosureReservationView {
        var codeText: String
        var nameText: String
        var bed: String
        var floorValue: String
        var phone: String
        var budget: String
        var statusLabel: String

        init(codeText: String, nameText: String, bed: String, floorValue: String, phone: String, budget: String, statusLabel: String) {
            self.codeText = codeText
            self.nameText = nameText
            self.bed = bed
            self.floorValue = floorValue
            self.phone = phone
            self.budget = budget
            self.statusLabel = statusLabel
        }
    }

    static func toRollingDisclosureReservationView(_ item: RollingDisclosureReservation) -> RollingDisclosureReservationView {
        return RollingDisclosureReservationView(
            codeText: item.code,
            nameText: item.name,
            bed: Kit.Text.truncate(item.bed, limit: 64),
            floorValue: String(format: "%.2f", item.floorValue),
            phone: item.phone,
            budget: String(format: "%.2f", item.budget),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRollingDisclosureReservationViews(_ items: [RollingDisclosureReservation]) -> [RollingDisclosureReservationView] {
        var views: [RollingDisclosureReservationView] = []
        for item in items {
            views.append(toRollingDisclosureReservationView(item))
        }
        return views
    }

    static func sumRollingDisclosureReservationView(_ view: RollingDisclosureReservationView) throws -> Double {
        guard let parsedFloorValue = Double(view.floorValue) else {
            throw Kit.Failure("parse floor value: not a number")
        }
        guard let parsedBudget = Double(view.budget) else {
            throw Kit.Failure("parse budget: not a number")
        }
        return parsedFloorValue + parsedBudget
    }
}
