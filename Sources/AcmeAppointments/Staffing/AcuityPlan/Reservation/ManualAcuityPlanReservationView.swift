import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a manual acuity plan reservation.
    final class ManualAcuityPlanReservationView {
        var codeText: String
        var label: String
        var discount: String
        var maximum: String
        var durationMinutes: String
        var threshold: String
        var startsAt: String
        var nameText: String
        var categoryText: String
        var statusLabel: String

        init(codeText: String, label: String, discount: String, maximum: String, durationMinutes: String, threshold: String, startsAt: String, nameText: String, categoryText: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.discount = discount
            self.maximum = maximum
            self.durationMinutes = durationMinutes
            self.threshold = threshold
            self.startsAt = startsAt
            self.nameText = nameText
            self.categoryText = categoryText
            self.statusLabel = statusLabel
        }
    }

    static func toManualAcuityPlanReservationView(_ item: ManualAcuityPlanReservation) -> ManualAcuityPlanReservationView {
        return ManualAcuityPlanReservationView(
            codeText: Kit.Text.truncate(item.code, limit: 40),
            label: item.label,
            discount: String(format: "%.2f", item.discount),
            maximum: String(format: "%.2f", item.maximum),
            durationMinutes: String(item.durationMinutes),
            threshold: String(format: "%.2f", item.threshold),
            startsAt: String(item.startsAt),
            nameText: item.name,
            categoryText: item.category,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toManualAcuityPlanReservationViews(_ items: [ManualAcuityPlanReservation]) -> [ManualAcuityPlanReservationView] {
        var views: [ManualAcuityPlanReservationView] = []
        for item in items {
            views.append(toManualAcuityPlanReservationView(item))
        }
        return views
    }

    static func sumManualAcuityPlanReservationView(_ view: ManualAcuityPlanReservationView) throws -> Double {
        guard let parsedDiscount = Double(view.discount) else {
            throw Kit.Failure("parse discount: not a number")
        }
        guard let parsedMaximum = Double(view.maximum) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        guard let parsedDurationMinutes = Int(view.durationMinutes) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        return parsedDiscount + parsedMaximum + Double(parsedDurationMinutes)
    }
}
