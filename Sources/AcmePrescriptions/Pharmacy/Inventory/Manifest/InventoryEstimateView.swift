import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a inventory estimate.
    final class InventoryEstimateView {
        var codeText: String
        var name: String
        var amount: String
        var bed: String
        var maximum: String
        var ward: String
        var visitMinutes: String
        var specialty: String
        var floorValue: String
        var retries: String
        var version: String
        var statusLabel: String

        init(codeText: String, name: String, amount: String, bed: String, maximum: String, ward: String, visitMinutes: String, specialty: String, floorValue: String, retries: String, version: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.amount = amount
            self.bed = bed
            self.maximum = maximum
            self.ward = ward
            self.visitMinutes = visitMinutes
            self.specialty = specialty
            self.floorValue = floorValue
            self.retries = retries
            self.version = version
            self.statusLabel = statusLabel
        }
    }

    static func toInventoryEstimateView(_ item: InventoryEstimate) -> InventoryEstimateView {
        return InventoryEstimateView(
            codeText: item.code,
            name: item.name,
            amount: String(format: "%.2f", item.amount),
            bed: Kit.Text.truncate(item.bed, limit: 64),
            maximum: String(format: "%.2f", item.maximum),
            ward: Kit.Text.truncate(item.ward, limit: 64),
            visitMinutes: String(item.visitMinutes),
            specialty: item.specialty,
            floorValue: String(format: "%.2f", item.floorValue),
            retries: String(item.retries),
            version: String(item.version),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toInventoryEstimateViews(_ items: [InventoryEstimate]) -> [InventoryEstimateView] {
        var views: [InventoryEstimateView] = []
        for item in items {
            views.append(toInventoryEstimateView(item))
        }
        return views
    }

    static func sumInventoryEstimateView(_ view: InventoryEstimateView) throws -> Double {
        guard let parsedAmount = Double(view.amount) else {
            throw Kit.Failure("parse amount: not a number")
        }
        guard let parsedMaximum = Double(view.maximum) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        guard let parsedVisitMinutes = Int(view.visitMinutes) else {
            throw Kit.Failure("parse visit minutes: not a number")
        }
        return parsedAmount + parsedMaximum + Double(parsedVisitMinutes)
    }
}
