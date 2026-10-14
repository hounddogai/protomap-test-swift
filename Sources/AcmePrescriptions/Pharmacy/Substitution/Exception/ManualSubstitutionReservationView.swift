import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a manual substitution reservation.
    final class ManualSubstitutionReservationView {
        var code: String
        var label: String
        var acuity: String
        var name: String
        var notes: String
        var pinnedText: String
        var quantity: String
        var startsAtText: String
        var locale: String
        var unit: String
        var statusLabel: String

        init(code: String, label: String, acuity: String, name: String, notes: String, pinnedText: String, quantity: String, startsAtText: String, locale: String, unit: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.acuity = acuity
            self.name = name
            self.notes = notes
            self.pinnedText = pinnedText
            self.quantity = quantity
            self.startsAtText = startsAtText
            self.locale = locale
            self.unit = unit
            self.statusLabel = statusLabel
        }
    }

    static func toManualSubstitutionReservationView(_ item: ManualSubstitutionReservation) -> ManualSubstitutionReservationView {
        return ManualSubstitutionReservationView(
            code: item.code,
            label: item.label,
            acuity: String(item.acuity),
            name: item.name,
            notes: item.notes,
            pinnedText: "\(item.pinned)",
            quantity: String(item.quantity),
            startsAtText: String(item.startsAt),
            locale: item.locale,
            unit: Kit.Text.truncate(item.unit, limit: 40),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toManualSubstitutionReservationViews(_ items: [ManualSubstitutionReservation]) -> [ManualSubstitutionReservationView] {
        var views: [ManualSubstitutionReservationView] = []
        for item in items {
            views.append(toManualSubstitutionReservationView(item))
        }
        return views
    }

    static func sumManualSubstitutionReservationView(_ view: ManualSubstitutionReservationView) throws -> Double {
        guard let parsedAcuity = Int(view.acuity) else {
            throw Kit.Failure("parse acuity: not a number")
        }
        guard let parsedQuantity = Int(view.quantity) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        guard let parsedStartsAt = Int(view.startsAtText) else {
            throw Kit.Failure("parse starts at: not a number")
        }
        return Double(parsedAcuity) + Double(parsedQuantity) + Double(parsedStartsAt)
    }
}
