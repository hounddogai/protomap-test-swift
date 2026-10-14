import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a regional discharge plan profile.
    final class RegionalDischargePlanProfileView {
        var code: String
        var titleText: String
        var ratioText: String
        var region: String
        var statusLabel: String

        init(code: String, titleText: String, ratioText: String, region: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.ratioText = ratioText
            self.region = region
            self.statusLabel = statusLabel
        }
    }

    static func toRegionalDischargePlanProfileView(_ item: RegionalDischargePlanProfile) -> RegionalDischargePlanProfileView {
        return RegionalDischargePlanProfileView(
            code: Kit.Text.truncate(item.code, limit: 64),
            titleText: item.title,
            ratioText: String(format: "%.2f", item.ratio),
            region: item.region,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRegionalDischargePlanProfileViews(_ items: [RegionalDischargePlanProfile]) -> [RegionalDischargePlanProfileView] {
        var views: [RegionalDischargePlanProfileView] = []
        for item in items {
            views.append(toRegionalDischargePlanProfileView(item))
        }
        return views
    }

    static func sumRegionalDischargePlanProfileView(_ view: RegionalDischargePlanProfileView) throws -> Double {
        guard let parsedRatio = Double(view.ratioText) else {
            throw Kit.Failure("parse ratio: not a number")
        }
        return parsedRatio
    }
}
