import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a batched witness forecast.
    final class BatchedWitnessForecastView {
        var code: String
        var title: String
        var threshold: String
        var windowDays: String
        var visibleText: String
        var version: String
        var statusLabel: String

        init(code: String, title: String, threshold: String, windowDays: String, visibleText: String, version: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.threshold = threshold
            self.windowDays = windowDays
            self.visibleText = visibleText
            self.version = version
            self.statusLabel = statusLabel
        }
    }

    static func toBatchedWitnessForecastView(_ item: BatchedWitnessForecast) -> BatchedWitnessForecastView {
        return BatchedWitnessForecastView(
            code: item.code,
            title: item.title,
            threshold: String(format: "%.2f", item.threshold),
            windowDays: String(item.windowDays),
            visibleText: "\(item.visible)",
            version: String(item.version),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toBatchedWitnessForecastViews(_ items: [BatchedWitnessForecast]) -> [BatchedWitnessForecastView] {
        var views: [BatchedWitnessForecastView] = []
        for item in items {
            views.append(toBatchedWitnessForecastView(item))
        }
        return views
    }

    static func sumBatchedWitnessForecastView(_ view: BatchedWitnessForecastView) throws -> Double {
        guard let parsedThreshold = Double(view.threshold) else {
            throw Kit.Failure("parse threshold: not a number")
        }
        guard let parsedWindowDays = Int(view.windowDays) else {
            throw Kit.Failure("parse window days: not a number")
        }
        guard let parsedVersion = Int(view.version) else {
            throw Kit.Failure("parse version: not a number")
        }
        return parsedThreshold + Double(parsedWindowDays) + Double(parsedVersion)
    }
}
