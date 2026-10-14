import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a care gap claim.
    final class CareGapClaimView {
        var code: String
        var nameText: String
        var ceiling: String
        var patientRefText: String
        var facilityText: String
        var durationMinutesText: String
        var statusLabel: String

        init(code: String, nameText: String, ceiling: String, patientRefText: String, facilityText: String, durationMinutesText: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.ceiling = ceiling
            self.patientRefText = patientRefText
            self.facilityText = facilityText
            self.durationMinutesText = durationMinutesText
            self.statusLabel = statusLabel
        }
    }

    static func toCareGapClaimView(_ item: CareGapClaim) -> CareGapClaimView {
        return CareGapClaimView(
            code: Kit.Text.truncate(item.code, limit: 40),
            nameText: item.name,
            ceiling: String(format: "%.2f", item.ceiling),
            patientRefText: item.patientRef,
            facilityText: Kit.Text.truncate(item.facility, limit: 120),
            durationMinutesText: String(item.durationMinutes),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCareGapClaimViews(_ items: [CareGapClaim]) -> [CareGapClaimView] {
        var views: [CareGapClaimView] = []
        for item in items {
            views.append(toCareGapClaimView(item))
        }
        return views
    }

    static func sumCareGapClaimView(_ view: CareGapClaimView) throws -> Double {
        guard let parsedCeiling = Double(view.ceiling) else {
            throw Kit.Failure("parse ceiling: not a number")
        }
        guard let parsedDurationMinutes = Int(view.durationMinutesText) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        return parsedCeiling + Double(parsedDurationMinutes)
    }
}
