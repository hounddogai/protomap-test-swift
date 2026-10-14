import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a inventory override.
    final class InventoryOverrideView {
        var code: String
        var titleText: String
        var currencyText: String
        var procedureCode: String
        var name: String
        var limit: String
        var unit: String
        var dosageMg: String
        var threshold: String
        var version: String
        var statusLabel: String

        init(code: String, titleText: String, currencyText: String, procedureCode: String, name: String, limit: String, unit: String, dosageMg: String, threshold: String, version: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.currencyText = currencyText
            self.procedureCode = procedureCode
            self.name = name
            self.limit = limit
            self.unit = unit
            self.dosageMg = dosageMg
            self.threshold = threshold
            self.version = version
            self.statusLabel = statusLabel
        }
    }

    static func toInventoryOverrideView(_ item: InventoryOverride) -> InventoryOverrideView {
        return InventoryOverrideView(
            code: item.code,
            titleText: item.title,
            currencyText: item.currency,
            procedureCode: item.procedureCode,
            name: item.name,
            limit: String(item.limit),
            unit: item.unit,
            dosageMg: String(format: "%.2f", item.dosageMg),
            threshold: String(format: "%.2f", item.threshold),
            version: String(item.version),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toInventoryOverrideViews(_ items: [InventoryOverride]) -> [InventoryOverrideView] {
        var views: [InventoryOverrideView] = []
        for item in items {
            views.append(toInventoryOverrideView(item))
        }
        return views
    }

    static func sumInventoryOverrideView(_ view: InventoryOverrideView) throws -> Double {
        guard let parsedLimit = Int(view.limit) else {
            throw Kit.Failure("parse limit: not a number")
        }
        guard let parsedDosageMg = Double(view.dosageMg) else {
            throw Kit.Failure("parse dosage mg: not a number")
        }
        guard let parsedThreshold = Double(view.threshold) else {
            throw Kit.Failure("parse threshold: not a number")
        }
        return Double(parsedLimit) + parsedDosageMg + parsedThreshold
    }
}
