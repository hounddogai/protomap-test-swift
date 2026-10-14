import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a default network bundle.
    final class DefaultNetworkBundleView {
        var code: String
        var titleText: String
        var category: String
        var minimum: String
        var source: String
        var limit: String
        var timezoneText: String
        var reviewerText: String
        var weightText: String
        var retries: String
        var statusLabel: String

        init(code: String, titleText: String, category: String, minimum: String, source: String, limit: String, timezoneText: String, reviewerText: String, weightText: String, retries: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.category = category
            self.minimum = minimum
            self.source = source
            self.limit = limit
            self.timezoneText = timezoneText
            self.reviewerText = reviewerText
            self.weightText = weightText
            self.retries = retries
            self.statusLabel = statusLabel
        }
    }

    static func toDefaultNetworkBundleView(_ item: DefaultNetworkBundle) -> DefaultNetworkBundleView {
        return DefaultNetworkBundleView(
            code: item.code,
            titleText: item.title,
            category: item.category,
            minimum: String(format: "%.2f", item.minimum),
            source: item.source,
            limit: String(item.limit),
            timezoneText: item.timezone,
            reviewerText: item.reviewer,
            weightText: String(format: "%.2f", item.weight),
            retries: String(item.retries),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toDefaultNetworkBundleViews(_ items: [DefaultNetworkBundle]) -> [DefaultNetworkBundleView] {
        var views: [DefaultNetworkBundleView] = []
        for item in items {
            views.append(toDefaultNetworkBundleView(item))
        }
        return views
    }

    static func sumDefaultNetworkBundleView(_ view: DefaultNetworkBundleView) throws -> Double {
        guard let parsedMinimum = Double(view.minimum) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        guard let parsedLimit = Int(view.limit) else {
            throw Kit.Failure("parse limit: not a number")
        }
        guard let parsedWeight = Double(view.weightText) else {
            throw Kit.Failure("parse weight: not a number")
        }
        return parsedMinimum + Double(parsedLimit) + parsedWeight
    }
}
