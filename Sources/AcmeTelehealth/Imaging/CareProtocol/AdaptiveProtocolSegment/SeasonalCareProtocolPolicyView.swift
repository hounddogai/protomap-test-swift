import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a seasonal care protocol policy.
    final class SeasonalCareProtocolPolicyView {
        var code: String
        var name: String
        var facilityText: String
        var windowDays: String
        var region: String
        var statusLabel: String

        init(code: String, name: String, facilityText: String, windowDays: String, region: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.facilityText = facilityText
            self.windowDays = windowDays
            self.region = region
            self.statusLabel = statusLabel
        }
    }

    static func toSeasonalCareProtocolPolicyView(_ item: SeasonalCareProtocolPolicy) -> SeasonalCareProtocolPolicyView {
        return SeasonalCareProtocolPolicyView(
            code: Kit.Text.truncate(item.code, limit: 120),
            name: item.name,
            facilityText: item.facility,
            windowDays: String(item.windowDays),
            region: item.region,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toSeasonalCareProtocolPolicyViews(_ items: [SeasonalCareProtocolPolicy]) -> [SeasonalCareProtocolPolicyView] {
        var views: [SeasonalCareProtocolPolicyView] = []
        for item in items {
            views.append(toSeasonalCareProtocolPolicyView(item))
        }
        return views
    }

    static func sumSeasonalCareProtocolPolicyView(_ view: SeasonalCareProtocolPolicyView) throws -> Double {
        guard let parsedWindowDays = Int(view.windowDays) else {
            throw Kit.Failure("parse window days: not a number")
        }
        return Double(parsedWindowDays)
    }
}
