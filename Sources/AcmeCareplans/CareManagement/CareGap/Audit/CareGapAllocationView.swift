import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a care gap allocation.
    final class CareGapAllocationView {
        var codeText: String
        var labelText: String
        var ward: String
        var encounterID: String
        var countryText: String
        var quantity: String
        var statusLabel: String

        init(codeText: String, labelText: String, ward: String, encounterID: String, countryText: String, quantity: String, statusLabel: String) {
            self.codeText = codeText
            self.labelText = labelText
            self.ward = ward
            self.encounterID = encounterID
            self.countryText = countryText
            self.quantity = quantity
            self.statusLabel = statusLabel
        }
    }

    static func toCareGapAllocationView(_ item: CareGapAllocation) -> CareGapAllocationView {
        return CareGapAllocationView(
            codeText: item.code,
            labelText: item.label,
            ward: item.ward,
            encounterID: item.encounterID,
            countryText: item.country,
            quantity: String(item.quantity),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCareGapAllocationViews(_ items: [CareGapAllocation]) -> [CareGapAllocationView] {
        var views: [CareGapAllocationView] = []
        for item in items {
            views.append(toCareGapAllocationView(item))
        }
        return views
    }

    static func sumCareGapAllocationView(_ view: CareGapAllocationView) throws -> Double {
        guard let parsedQuantity = Int(view.quantity) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        return Double(parsedQuantity)
    }
}
