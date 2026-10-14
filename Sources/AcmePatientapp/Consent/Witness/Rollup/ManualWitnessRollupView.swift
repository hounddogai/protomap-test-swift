import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a manual witness rollup.
    final class ManualWitnessRollupView {
        var code: String
        var name: String
        var startsAtText: String
        var windowDaysText: String
        var version: String
        var country: String
        var statusLabel: String

        init(code: String, name: String, startsAtText: String, windowDaysText: String, version: String, country: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.startsAtText = startsAtText
            self.windowDaysText = windowDaysText
            self.version = version
            self.country = country
            self.statusLabel = statusLabel
        }
    }

    static func toManualWitnessRollupView(_ item: ManualWitnessRollup) -> ManualWitnessRollupView {
        return ManualWitnessRollupView(
            code: item.code,
            name: item.name,
            startsAtText: String(item.startsAt),
            windowDaysText: String(item.windowDays),
            version: String(item.version),
            country: item.country,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toManualWitnessRollupViews(_ items: [ManualWitnessRollup]) -> [ManualWitnessRollupView] {
        var views: [ManualWitnessRollupView] = []
        for item in items {
            views.append(toManualWitnessRollupView(item))
        }
        return views
    }

    static func sumManualWitnessRollupView(_ view: ManualWitnessRollupView) throws -> Double {
        guard let parsedStartsAt = Int(view.startsAtText) else {
            throw Kit.Failure("parse starts at: not a number")
        }
        guard let parsedWindowDays = Int(view.windowDaysText) else {
            throw Kit.Failure("parse window days: not a number")
        }
        guard let parsedVersion = Int(view.version) else {
            throw Kit.Failure("parse version: not a number")
        }
        return Double(parsedStartsAt) + Double(parsedWindowDays) + Double(parsedVersion)
    }
}
