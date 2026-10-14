import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a remittance variance.
    final class RemittanceVarianceView {
        var code: String
        var name: String
        var graceDays: String
        var encounterID: String
        var ownerID: String
        var specialty: String
        var quantity: String
        var statusLabel: String

        init(code: String, name: String, graceDays: String, encounterID: String, ownerID: String, specialty: String, quantity: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.graceDays = graceDays
            self.encounterID = encounterID
            self.ownerID = ownerID
            self.specialty = specialty
            self.quantity = quantity
            self.statusLabel = statusLabel
        }
    }

    static func toRemittanceVarianceView(_ item: RemittanceVariance) -> RemittanceVarianceView {
        return RemittanceVarianceView(
            code: item.code,
            name: item.name,
            graceDays: String(item.graceDays),
            encounterID: item.encounterID,
            ownerID: item.ownerID,
            specialty: item.specialty,
            quantity: String(item.quantity),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRemittanceVarianceViews(_ items: [RemittanceVariance]) -> [RemittanceVarianceView] {
        var views: [RemittanceVarianceView] = []
        for item in items {
            views.append(toRemittanceVarianceView(item))
        }
        return views
    }

    static func sumRemittanceVarianceView(_ view: RemittanceVarianceView) throws -> Double {
        guard let parsedGraceDays = Int(view.graceDays) else {
            throw Kit.Failure("parse grace days: not a number")
        }
        guard let parsedQuantity = Int(view.quantity) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        return Double(parsedGraceDays) + Double(parsedQuantity)
    }
}
