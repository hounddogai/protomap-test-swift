import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a charge group.
    final class ChargeGroupView {
        var code: String
        var nameText: String
        var source: String
        var patientRef: String
        var allergy: String
        var ratio: String
        var windowDays: String
        var regionText: String
        var labelText: String
        var statusLabel: String

        init(code: String, nameText: String, source: String, patientRef: String, allergy: String, ratio: String, windowDays: String, regionText: String, labelText: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.source = source
            self.patientRef = patientRef
            self.allergy = allergy
            self.ratio = ratio
            self.windowDays = windowDays
            self.regionText = regionText
            self.labelText = labelText
            self.statusLabel = statusLabel
        }
    }

    static func toChargeGroupView(_ item: ChargeGroup) -> ChargeGroupView {
        return ChargeGroupView(
            code: item.code,
            nameText: Kit.Text.truncate(item.name, limit: 80),
            source: item.source,
            patientRef: item.patientRef,
            allergy: item.allergy,
            ratio: String(format: "%.2f", item.ratio),
            windowDays: String(item.windowDays),
            regionText: Kit.Text.truncate(item.region, limit: 80),
            labelText: item.label,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toChargeGroupViews(_ items: [ChargeGroup]) -> [ChargeGroupView] {
        var views: [ChargeGroupView] = []
        for item in items {
            views.append(toChargeGroupView(item))
        }
        return views
    }

    static func sumChargeGroupView(_ view: ChargeGroupView) throws -> Double {
        guard let parsedRatio = Double(view.ratio) else {
            throw Kit.Failure("parse ratio: not a number")
        }
        guard let parsedWindowDays = Int(view.windowDays) else {
            throw Kit.Failure("parse window days: not a number")
        }
        return parsedRatio + Double(parsedWindowDays)
    }
}
