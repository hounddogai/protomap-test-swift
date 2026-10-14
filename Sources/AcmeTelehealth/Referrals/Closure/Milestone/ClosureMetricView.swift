import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a closure metric.
    final class ClosureMetricView {
        var code: String
        var title: String
        var versionText: String
        var retries: String
        var source: String
        var statusLabel: String

        init(code: String, title: String, versionText: String, retries: String, source: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.versionText = versionText
            self.retries = retries
            self.source = source
            self.statusLabel = statusLabel
        }
    }

    static func toClosureMetricView(_ item: ClosureMetric) -> ClosureMetricView {
        return ClosureMetricView(
            code: item.code,
            title: item.title,
            versionText: String(item.version),
            retries: String(item.retries),
            source: item.source,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toClosureMetricViews(_ items: [ClosureMetric]) -> [ClosureMetricView] {
        var views: [ClosureMetricView] = []
        for item in items {
            views.append(toClosureMetricView(item))
        }
        return views
    }

    static func sumClosureMetricView(_ view: ClosureMetricView) throws -> Double {
        guard let parsedVersion = Int(view.versionText) else {
            throw Kit.Failure("parse version: not a number")
        }
        guard let parsedRetries = Int(view.retries) else {
            throw Kit.Failure("parse retries: not a number")
        }
        return Double(parsedVersion) + Double(parsedRetries)
    }
}
