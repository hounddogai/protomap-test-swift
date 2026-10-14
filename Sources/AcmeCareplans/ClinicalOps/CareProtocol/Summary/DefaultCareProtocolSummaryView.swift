import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a default care protocol summary.
    final class DefaultCareProtocolSummaryView {
        var code: String
        var nameText: String
        var allergy: String
        var patientRefText: String
        var facilityText: String
        var amount: String
        var statusLabel: String

        init(code: String, nameText: String, allergy: String, patientRefText: String, facilityText: String, amount: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.allergy = allergy
            self.patientRefText = patientRefText
            self.facilityText = facilityText
            self.amount = amount
            self.statusLabel = statusLabel
        }
    }

    static func toDefaultCareProtocolSummaryView(_ item: DefaultCareProtocolSummary) -> DefaultCareProtocolSummaryView {
        return DefaultCareProtocolSummaryView(
            code: item.code,
            nameText: item.name,
            allergy: item.allergy,
            patientRefText: item.patientRef,
            facilityText: item.facility,
            amount: String(format: "%.2f", item.amount),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toDefaultCareProtocolSummaryViews(_ items: [DefaultCareProtocolSummary]) -> [DefaultCareProtocolSummaryView] {
        var views: [DefaultCareProtocolSummaryView] = []
        for item in items {
            views.append(toDefaultCareProtocolSummaryView(item))
        }
        return views
    }

    static func sumDefaultCareProtocolSummaryView(_ view: DefaultCareProtocolSummaryView) throws -> Double {
        guard let parsedAmount = Double(view.amount) else {
            throw Kit.Failure("parse amount: not a number")
        }
        return parsedAmount
    }
}
