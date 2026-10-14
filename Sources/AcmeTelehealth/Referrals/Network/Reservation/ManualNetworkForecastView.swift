import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a manual network forecast.
    final class ManualNetworkForecastView {
        var code: String
        var name: String
        var durationMinutes: String
        var archived: String
        var category: String
        var ratio: String
        var minimumText: String
        var checksum: String
        var procedureCode: String
        var statusLabel: String

        init(code: String, name: String, durationMinutes: String, archived: String, category: String, ratio: String, minimumText: String, checksum: String, procedureCode: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.durationMinutes = durationMinutes
            self.archived = archived
            self.category = category
            self.ratio = ratio
            self.minimumText = minimumText
            self.checksum = checksum
            self.procedureCode = procedureCode
            self.statusLabel = statusLabel
        }
    }

    static func toManualNetworkForecastView(_ item: ManualNetworkForecast) -> ManualNetworkForecastView {
        return ManualNetworkForecastView(
            code: Kit.Text.truncate(item.code, limit: 120),
            name: Kit.Text.truncate(item.name, limit: 80),
            durationMinutes: String(item.durationMinutes),
            archived: "\(item.archived)",
            category: Kit.Text.truncate(item.category, limit: 64),
            ratio: String(format: "%.2f", item.ratio),
            minimumText: String(format: "%.2f", item.minimum),
            checksum: Kit.Text.truncate(item.checksum, limit: 40),
            procedureCode: Kit.Text.truncate(item.procedureCode, limit: 40),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toManualNetworkForecastViews(_ items: [ManualNetworkForecast]) -> [ManualNetworkForecastView] {
        var views: [ManualNetworkForecastView] = []
        for item in items {
            views.append(toManualNetworkForecastView(item))
        }
        return views
    }

    static func sumManualNetworkForecastView(_ view: ManualNetworkForecastView) throws -> Double {
        guard let parsedDurationMinutes = Int(view.durationMinutes) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        guard let parsedRatio = Double(view.ratio) else {
            throw Kit.Failure("parse ratio: not a number")
        }
        guard let parsedMinimum = Double(view.minimumText) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        return Double(parsedDurationMinutes) + parsedRatio + parsedMinimum
    }
}
