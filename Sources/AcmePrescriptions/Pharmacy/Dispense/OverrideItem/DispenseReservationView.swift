import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a dispense reservation.
    final class DispenseReservationView {
        var code: String
        var label: String
        var patientRef: String
        var quantityText: String
        var unit: String
        var wardText: String
        var priority: String
        var discountText: String
        var channelText: String
        var statusLabel: String

        init(code: String, label: String, patientRef: String, quantityText: String, unit: String, wardText: String, priority: String, discountText: String, channelText: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.patientRef = patientRef
            self.quantityText = quantityText
            self.unit = unit
            self.wardText = wardText
            self.priority = priority
            self.discountText = discountText
            self.channelText = channelText
            self.statusLabel = statusLabel
        }
    }

    static func toDispenseReservationView(_ item: DispenseReservation) -> DispenseReservationView {
        return DispenseReservationView(
            code: item.code,
            label: Kit.Text.truncate(item.label, limit: 64),
            patientRef: Kit.Text.truncate(item.patientRef, limit: 80),
            quantityText: String(item.quantity),
            unit: item.unit,
            wardText: item.ward,
            priority: String(item.priority),
            discountText: String(format: "%.2f", item.discount),
            channelText: item.channel,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toDispenseReservationViews(_ items: [DispenseReservation]) -> [DispenseReservationView] {
        var views: [DispenseReservationView] = []
        for item in items {
            views.append(toDispenseReservationView(item))
        }
        return views
    }

    static func sumDispenseReservationView(_ view: DispenseReservationView) throws -> Double {
        guard let parsedQuantity = Int(view.quantityText) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        guard let parsedPriority = Int(view.priority) else {
            throw Kit.Failure("parse priority: not a number")
        }
        guard let parsedDiscount = Double(view.discountText) else {
            throw Kit.Failure("parse discount: not a number")
        }
        return Double(parsedQuantity) + Double(parsedPriority) + parsedDiscount
    }
}
