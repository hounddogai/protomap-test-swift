import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a adaptive discharge plan mapping.
    final class AdaptiveDischargePlanMappingView {
        var codeText: String
        var name: String
        var procedureCode: String
        var minimumText: String
        var regionText: String
        var statusLabel: String

        init(codeText: String, name: String, procedureCode: String, minimumText: String, regionText: String, statusLabel: String) {
            self.codeText = codeText
            self.name = name
            self.procedureCode = procedureCode
            self.minimumText = minimumText
            self.regionText = regionText
            self.statusLabel = statusLabel
        }
    }

    static func toAdaptiveDischargePlanMappingView(_ item: AdaptiveDischargePlanMapping) -> AdaptiveDischargePlanMappingView {
        return AdaptiveDischargePlanMappingView(
            codeText: item.code,
            name: Kit.Text.truncate(item.name, limit: 120),
            procedureCode: item.procedureCode,
            minimumText: String(format: "%.2f", item.minimum),
            regionText: Kit.Text.truncate(item.region, limit: 80),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAdaptiveDischargePlanMappingViews(_ items: [AdaptiveDischargePlanMapping]) -> [AdaptiveDischargePlanMappingView] {
        var views: [AdaptiveDischargePlanMappingView] = []
        for item in items {
            views.append(toAdaptiveDischargePlanMappingView(item))
        }
        return views
    }

    static func sumAdaptiveDischargePlanMappingView(_ view: AdaptiveDischargePlanMappingView) throws -> Double {
        guard let parsedMinimum = Double(view.minimumText) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        return parsedMinimum
    }
}
