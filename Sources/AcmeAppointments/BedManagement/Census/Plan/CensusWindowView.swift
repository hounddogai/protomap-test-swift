import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a census window.
    final class CensusWindowView {
        var code: String
        var name: String
        var floorValue: String
        var dosageMg: String
        var facilityText: String
        var expiresAt: String
        var allergy: String
        var statusLabel: String

        init(code: String, name: String, floorValue: String, dosageMg: String, facilityText: String, expiresAt: String, allergy: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.floorValue = floorValue
            self.dosageMg = dosageMg
            self.facilityText = facilityText
            self.expiresAt = expiresAt
            self.allergy = allergy
            self.statusLabel = statusLabel
        }
    }

    static func toCensusWindowView(_ item: CensusWindow) -> CensusWindowView {
        return CensusWindowView(
            code: item.code,
            name: item.name,
            floorValue: String(format: "%.2f", item.floorValue),
            dosageMg: String(format: "%.2f", item.dosageMg),
            facilityText: item.facility,
            expiresAt: String(item.expiresAt),
            allergy: item.allergy,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCensusWindowViews(_ items: [CensusWindow]) -> [CensusWindowView] {
        var views: [CensusWindowView] = []
        for item in items {
            views.append(toCensusWindowView(item))
        }
        return views
    }

    static func sumCensusWindowView(_ view: CensusWindowView) throws -> Double {
        guard let parsedFloorValue = Double(view.floorValue) else {
            throw Kit.Failure("parse floor value: not a number")
        }
        guard let parsedDosageMg = Double(view.dosageMg) else {
            throw Kit.Failure("parse dosage mg: not a number")
        }
        guard let parsedExpiresAt = Int(view.expiresAt) else {
            throw Kit.Failure("parse expires at: not a number")
        }
        return parsedFloorValue + parsedDosageMg + Double(parsedExpiresAt)
    }
}
