import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a global authorization estimate.
    final class GlobalAuthorizationEstimateView {
        var code: String
        var name: String
        var windowDaysText: String
        var regionText: String
        var categoryText: String
        var minimum: String
        var revisionText: String
        var batchSize: String
        var statusLabel: String

        init(code: String, name: String, windowDaysText: String, regionText: String, categoryText: String, minimum: String, revisionText: String, batchSize: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.windowDaysText = windowDaysText
            self.regionText = regionText
            self.categoryText = categoryText
            self.minimum = minimum
            self.revisionText = revisionText
            self.batchSize = batchSize
            self.statusLabel = statusLabel
        }
    }

    static func toGlobalAuthorizationEstimateView(_ item: GlobalAuthorizationEstimate) -> GlobalAuthorizationEstimateView {
        return GlobalAuthorizationEstimateView(
            code: item.code,
            name: item.name,
            windowDaysText: String(item.windowDays),
            regionText: item.region,
            categoryText: Kit.Text.truncate(item.category, limit: 64),
            minimum: String(format: "%.2f", item.minimum),
            revisionText: String(item.revision),
            batchSize: String(item.batchSize),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toGlobalAuthorizationEstimateViews(_ items: [GlobalAuthorizationEstimate]) -> [GlobalAuthorizationEstimateView] {
        var views: [GlobalAuthorizationEstimateView] = []
        for item in items {
            views.append(toGlobalAuthorizationEstimateView(item))
        }
        return views
    }

    static func sumGlobalAuthorizationEstimateView(_ view: GlobalAuthorizationEstimateView) throws -> Double {
        guard let parsedWindowDays = Int(view.windowDaysText) else {
            throw Kit.Failure("parse window days: not a number")
        }
        guard let parsedMinimum = Double(view.minimum) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        guard let parsedRevision = Int(view.revisionText) else {
            throw Kit.Failure("parse revision: not a number")
        }
        return Double(parsedWindowDays) + parsedMinimum + Double(parsedRevision)
    }
}
