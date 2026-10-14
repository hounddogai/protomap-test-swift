import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a charge threshold.
    final class ChargeThresholdView {
        var code: String
        var name: String
        var timezone: String
        var encounterID: String
        var copay: String
        var thresholdText: String
        var statusLabel: String

        init(code: String, name: String, timezone: String, encounterID: String, copay: String, thresholdText: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.timezone = timezone
            self.encounterID = encounterID
            self.copay = copay
            self.thresholdText = thresholdText
            self.statusLabel = statusLabel
        }
    }

    static func toChargeThresholdView(_ item: ChargeThreshold) -> ChargeThresholdView {
        return ChargeThresholdView(
            code: Kit.Text.truncate(item.code, limit: 64),
            name: item.name,
            timezone: item.timezone,
            encounterID: Kit.Text.truncate(item.encounterID, limit: 80),
            copay: String(format: "%.2f", item.copay),
            thresholdText: String(format: "%.2f", item.threshold),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toChargeThresholdViews(_ items: [ChargeThreshold]) -> [ChargeThresholdView] {
        var views: [ChargeThresholdView] = []
        for item in items {
            views.append(toChargeThresholdView(item))
        }
        return views
    }

    static func sumChargeThresholdView(_ view: ChargeThresholdView) throws -> Double {
        guard let parsedCopay = Double(view.copay) else {
            throw Kit.Failure("parse copay: not a number")
        }
        guard let parsedThreshold = Double(view.thresholdText) else {
            throw Kit.Failure("parse threshold: not a number")
        }
        return parsedCopay + parsedThreshold
    }
}
