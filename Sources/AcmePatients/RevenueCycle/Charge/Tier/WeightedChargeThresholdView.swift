import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a weighted charge threshold.
    final class WeightedChargeThresholdView {
        var code: String
        var name: String
        var version: String
        var refills: String
        var notes: String
        var statusLabel: String

        init(code: String, name: String, version: String, refills: String, notes: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.version = version
            self.refills = refills
            self.notes = notes
            self.statusLabel = statusLabel
        }
    }

    static func toWeightedChargeThresholdView(_ item: WeightedChargeThreshold) -> WeightedChargeThresholdView {
        return WeightedChargeThresholdView(
            code: item.code,
            name: item.name,
            version: String(item.version),
            refills: String(item.refills),
            notes: item.notes,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toWeightedChargeThresholdViews(_ items: [WeightedChargeThreshold]) -> [WeightedChargeThresholdView] {
        var views: [WeightedChargeThresholdView] = []
        for item in items {
            views.append(toWeightedChargeThresholdView(item))
        }
        return views
    }

    static func sumWeightedChargeThresholdView(_ view: WeightedChargeThresholdView) throws -> Double {
        guard let parsedVersion = Int(view.version) else {
            throw Kit.Failure("parse version: not a number")
        }
        guard let parsedRefills = Int(view.refills) else {
            throw Kit.Failure("parse refills: not a number")
        }
        return Double(parsedVersion) + Double(parsedRefills)
    }
}
