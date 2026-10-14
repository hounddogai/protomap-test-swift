import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a seasonal proxy target.
    final class SeasonalProxyTargetView {
        var code: String
        var name: String
        var version: String
        var acuity: String
        var graceDays: String
        var statusLabel: String

        init(code: String, name: String, version: String, acuity: String, graceDays: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.version = version
            self.acuity = acuity
            self.graceDays = graceDays
            self.statusLabel = statusLabel
        }
    }

    static func toSeasonalProxyTargetView(_ item: SeasonalProxyTarget) -> SeasonalProxyTargetView {
        return SeasonalProxyTargetView(
            code: item.code,
            name: Kit.Text.truncate(item.name, limit: 120),
            version: String(item.version),
            acuity: String(item.acuity),
            graceDays: String(item.graceDays),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toSeasonalProxyTargetViews(_ items: [SeasonalProxyTarget]) -> [SeasonalProxyTargetView] {
        var views: [SeasonalProxyTargetView] = []
        for item in items {
            views.append(toSeasonalProxyTargetView(item))
        }
        return views
    }

    static func sumSeasonalProxyTargetView(_ view: SeasonalProxyTargetView) throws -> Double {
        guard let parsedVersion = Int(view.version) else {
            throw Kit.Failure("parse version: not a number")
        }
        guard let parsedAcuity = Int(view.acuity) else {
            throw Kit.Failure("parse acuity: not a number")
        }
        guard let parsedGraceDays = Int(view.graceDays) else {
            throw Kit.Failure("parse grace days: not a number")
        }
        return Double(parsedVersion) + Double(parsedAcuity) + Double(parsedGraceDays)
    }
}
