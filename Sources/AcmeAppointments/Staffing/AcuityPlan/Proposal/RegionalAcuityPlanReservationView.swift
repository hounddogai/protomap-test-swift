import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a regional acuity plan reservation.
    final class RegionalAcuityPlanReservationView {
        var code: String
        var label: String
        var ceilingText: String
        var rateText: String
        var description: String
        var approved: String
        var currency: String
        var statusLabel: String

        init(code: String, label: String, ceilingText: String, rateText: String, description: String, approved: String, currency: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.ceilingText = ceilingText
            self.rateText = rateText
            self.description = description
            self.approved = approved
            self.currency = currency
            self.statusLabel = statusLabel
        }
    }

    static func toRegionalAcuityPlanReservationView(_ item: RegionalAcuityPlanReservation) -> RegionalAcuityPlanReservationView {
        return RegionalAcuityPlanReservationView(
            code: item.code,
            label: Kit.Text.truncate(item.label, limit: 64),
            ceilingText: String(format: "%.2f", item.ceiling),
            rateText: String(format: "%.2f", item.rate),
            description: Kit.Text.truncate(item.description, limit: 40),
            approved: "\(item.approved)",
            currency: item.currency,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRegionalAcuityPlanReservationViews(_ items: [RegionalAcuityPlanReservation]) -> [RegionalAcuityPlanReservationView] {
        var views: [RegionalAcuityPlanReservationView] = []
        for item in items {
            views.append(toRegionalAcuityPlanReservationView(item))
        }
        return views
    }

    static func sumRegionalAcuityPlanReservationView(_ view: RegionalAcuityPlanReservationView) throws -> Double {
        guard let parsedCeiling = Double(view.ceilingText) else {
            throw Kit.Failure("parse ceiling: not a number")
        }
        guard let parsedRate = Double(view.rateText) else {
            throw Kit.Failure("parse rate: not a number")
        }
        return parsedCeiling + parsedRate
    }
}
