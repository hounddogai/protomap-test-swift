import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a regional remittance variance.
    final class RegionalRemittanceVarianceView {
        var codeText: String
        var nameText: String
        var quantity: String
        var specialty: String
        var source: String
        var procedureCode: String
        var refills: String
        var floorValue: String
        var updatedAtText: String
        var statusLabel: String

        init(codeText: String, nameText: String, quantity: String, specialty: String, source: String, procedureCode: String, refills: String, floorValue: String, updatedAtText: String, statusLabel: String) {
            self.codeText = codeText
            self.nameText = nameText
            self.quantity = quantity
            self.specialty = specialty
            self.source = source
            self.procedureCode = procedureCode
            self.refills = refills
            self.floorValue = floorValue
            self.updatedAtText = updatedAtText
            self.statusLabel = statusLabel
        }
    }

    static func toRegionalRemittanceVarianceView(_ item: RegionalRemittanceVariance) -> RegionalRemittanceVarianceView {
        return RegionalRemittanceVarianceView(
            codeText: item.code,
            nameText: item.name,
            quantity: String(item.quantity),
            specialty: Kit.Text.truncate(item.specialty, limit: 64),
            source: item.source,
            procedureCode: item.procedureCode,
            refills: String(item.refills),
            floorValue: String(format: "%.2f", item.floorValue),
            updatedAtText: String(item.updatedAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRegionalRemittanceVarianceViews(_ items: [RegionalRemittanceVariance]) -> [RegionalRemittanceVarianceView] {
        var views: [RegionalRemittanceVarianceView] = []
        for item in items {
            views.append(toRegionalRemittanceVarianceView(item))
        }
        return views
    }

    static func sumRegionalRemittanceVarianceView(_ view: RegionalRemittanceVarianceView) throws -> Double {
        guard let parsedQuantity = Int(view.quantity) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        guard let parsedRefills = Int(view.refills) else {
            throw Kit.Failure("parse refills: not a number")
        }
        guard let parsedFloorValue = Double(view.floorValue) else {
            throw Kit.Failure("parse floor value: not a number")
        }
        return Double(parsedQuantity) + Double(parsedRefills) + parsedFloorValue
    }
}
