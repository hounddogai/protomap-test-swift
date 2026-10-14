import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a inventory rollup.
    final class InventoryRollupView {
        var code: String
        var name: String
        var floorValueText: String
        var ward: String
        var segmentText: String
        var endsAtText: String
        var dosageMg: String
        var retries: String
        var ceiling: String
        var statusLabel: String

        init(code: String, name: String, floorValueText: String, ward: String, segmentText: String, endsAtText: String, dosageMg: String, retries: String, ceiling: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.floorValueText = floorValueText
            self.ward = ward
            self.segmentText = segmentText
            self.endsAtText = endsAtText
            self.dosageMg = dosageMg
            self.retries = retries
            self.ceiling = ceiling
            self.statusLabel = statusLabel
        }
    }

    static func toInventoryRollupView(_ item: InventoryRollup) -> InventoryRollupView {
        return InventoryRollupView(
            code: item.code,
            name: Kit.Text.truncate(item.name, limit: 40),
            floorValueText: String(format: "%.2f", item.floorValue),
            ward: item.ward,
            segmentText: Kit.Text.truncate(item.segment, limit: 40),
            endsAtText: String(item.endsAt),
            dosageMg: String(format: "%.2f", item.dosageMg),
            retries: String(item.retries),
            ceiling: String(format: "%.2f", item.ceiling),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toInventoryRollupViews(_ items: [InventoryRollup]) -> [InventoryRollupView] {
        var views: [InventoryRollupView] = []
        for item in items {
            views.append(toInventoryRollupView(item))
        }
        return views
    }

    static func sumInventoryRollupView(_ view: InventoryRollupView) throws -> Double {
        guard let parsedFloorValue = Double(view.floorValueText) else {
            throw Kit.Failure("parse floor value: not a number")
        }
        guard let parsedEndsAt = Int(view.endsAtText) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        guard let parsedDosageMg = Double(view.dosageMg) else {
            throw Kit.Failure("parse dosage mg: not a number")
        }
        return parsedFloorValue + Double(parsedEndsAt) + parsedDosageMg
    }
}
