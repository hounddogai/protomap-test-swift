import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a discharge plan summary.
    final class DischargePlanSummaryView {
        var code: String
        var labelText: String
        var description: String
        var clinicianID: String
        var quantityText: String
        var checksumText: String
        var country: String
        var contactEmail: String
        var statusLabel: String

        init(code: String, labelText: String, description: String, clinicianID: String, quantityText: String, checksumText: String, country: String, contactEmail: String, statusLabel: String) {
            self.code = code
            self.labelText = labelText
            self.description = description
            self.clinicianID = clinicianID
            self.quantityText = quantityText
            self.checksumText = checksumText
            self.country = country
            self.contactEmail = contactEmail
            self.statusLabel = statusLabel
        }
    }

    static func toDischargePlanSummaryView(_ item: DischargePlanSummary) -> DischargePlanSummaryView {
        return DischargePlanSummaryView(
            code: item.code,
            labelText: item.label,
            description: Kit.Text.truncate(item.description, limit: 40),
            clinicianID: Kit.Text.truncate(item.clinicianID, limit: 40),
            quantityText: String(item.quantity),
            checksumText: item.checksum,
            country: item.country,
            contactEmail: Kit.Text.truncate(item.contactEmail, limit: 64),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toDischargePlanSummaryViews(_ items: [DischargePlanSummary]) -> [DischargePlanSummaryView] {
        var views: [DischargePlanSummaryView] = []
        for item in items {
            views.append(toDischargePlanSummaryView(item))
        }
        return views
    }

    static func sumDischargePlanSummaryView(_ view: DischargePlanSummaryView) throws -> Double {
        guard let parsedQuantity = Int(view.quantityText) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        return Double(parsedQuantity)
    }
}
