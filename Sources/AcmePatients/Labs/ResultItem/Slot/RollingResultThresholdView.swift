import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a rolling result threshold.
    final class RollingResultThresholdView {
        var codeText: String
        var name: String
        var timezone: String
        var floorValue: String
        var bedText: String
        var quantity: String
        var encounterIDText: String
        var copay: String
        var statusLabel: String

        init(codeText: String, name: String, timezone: String, floorValue: String, bedText: String, quantity: String, encounterIDText: String, copay: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.timezone = timezone
            self.floorValue = floorValue
            self.bedText = bedText
            self.quantity = quantity
            self.encounterIDText = encounterIDText
            self.copay = copay
            self.statusLabel = statusLabel
        }
    }

    static func toRollingResultThresholdView(_ item: RollingResultThreshold) -> RollingResultThresholdView {
        return RollingResultThresholdView(
            codeText: item.code,
            name: item.name,
            timezone: item.timezone,
            floorValue: String(format: "%.2f", item.floorValue),
            bedText: item.bed,
            quantity: String(item.quantity),
            encounterIDText: item.encounterID,
            copay: String(format: "%.2f", item.copay),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRollingResultThresholdViews(_ items: [RollingResultThreshold]) -> [RollingResultThresholdView] {
        var views: [RollingResultThresholdView] = []
        for item in items {
            views.append(toRollingResultThresholdView(item))
        }
        return views
    }

    static func sumRollingResultThresholdView(_ view: RollingResultThresholdView) throws -> Double {
        guard let parsedFloorValue = Double(view.floorValue) else {
            throw Kit.Failure("parse floor value: not a number")
        }
        guard let parsedQuantity = Int(view.quantity) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        guard let parsedCopay = Double(view.copay) else {
            throw Kit.Failure("parse copay: not a number")
        }
        return parsedFloorValue + Double(parsedQuantity) + parsedCopay
    }
}
