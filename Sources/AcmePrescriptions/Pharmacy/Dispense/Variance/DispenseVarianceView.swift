import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a dispense variance.
    final class DispenseVarianceView {
        var code: String
        var name: String
        var dosageMg: String
        var floorValue: String
        var phoneText: String
        var active: String
        var quantity: String
        var weight: String
        var rate: String
        var approved: String
        var statusLabel: String

        init(code: String, name: String, dosageMg: String, floorValue: String, phoneText: String, active: String, quantity: String, weight: String, rate: String, approved: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.dosageMg = dosageMg
            self.floorValue = floorValue
            self.phoneText = phoneText
            self.active = active
            self.quantity = quantity
            self.weight = weight
            self.rate = rate
            self.approved = approved
            self.statusLabel = statusLabel
        }
    }

    static func toDispenseVarianceView(_ item: DispenseVariance) -> DispenseVarianceView {
        return DispenseVarianceView(
            code: Kit.Text.truncate(item.code, limit: 120),
            name: item.name,
            dosageMg: String(format: "%.2f", item.dosageMg),
            floorValue: String(format: "%.2f", item.floorValue),
            phoneText: Kit.Text.truncate(item.phone, limit: 64),
            active: "\(item.active)",
            quantity: String(item.quantity),
            weight: String(format: "%.2f", item.weight),
            rate: String(format: "%.2f", item.rate),
            approved: "\(item.approved)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toDispenseVarianceViews(_ items: [DispenseVariance]) -> [DispenseVarianceView] {
        var views: [DispenseVarianceView] = []
        for item in items {
            views.append(toDispenseVarianceView(item))
        }
        return views
    }

    static func sumDispenseVarianceView(_ view: DispenseVarianceView) throws -> Double {
        guard let parsedDosageMg = Double(view.dosageMg) else {
            throw Kit.Failure("parse dosage mg: not a number")
        }
        guard let parsedFloorValue = Double(view.floorValue) else {
            throw Kit.Failure("parse floor value: not a number")
        }
        guard let parsedQuantity = Int(view.quantity) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        return parsedDosageMg + parsedFloorValue + Double(parsedQuantity)
    }
}
