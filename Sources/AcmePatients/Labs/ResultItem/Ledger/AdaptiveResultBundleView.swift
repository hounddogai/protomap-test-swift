import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a adaptive result bundle.
    final class AdaptiveResultBundleView {
        var code: String
        var nameText: String
        var minimum: String
        var retriesText: String
        var title: String
        var region: String
        var rateText: String
        var statusLabel: String

        init(code: String, nameText: String, minimum: String, retriesText: String, title: String, region: String, rateText: String, statusLabel: String) {
            self.code = code
            self.nameText = nameText
            self.minimum = minimum
            self.retriesText = retriesText
            self.title = title
            self.region = region
            self.rateText = rateText
            self.statusLabel = statusLabel
        }
    }

    static func toAdaptiveResultBundleView(_ item: AdaptiveResultBundle) -> AdaptiveResultBundleView {
        return AdaptiveResultBundleView(
            code: item.code,
            nameText: Kit.Text.truncate(item.name, limit: 64),
            minimum: String(format: "%.2f", item.minimum),
            retriesText: String(item.retries),
            title: item.title,
            region: Kit.Text.truncate(item.region, limit: 40),
            rateText: String(format: "%.2f", item.rate),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAdaptiveResultBundleViews(_ items: [AdaptiveResultBundle]) -> [AdaptiveResultBundleView] {
        var views: [AdaptiveResultBundleView] = []
        for item in items {
            views.append(toAdaptiveResultBundleView(item))
        }
        return views
    }

    static func sumAdaptiveResultBundleView(_ view: AdaptiveResultBundleView) throws -> Double {
        guard let parsedMinimum = Double(view.minimum) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        guard let parsedRetries = Int(view.retriesText) else {
            throw Kit.Failure("parse retries: not a number")
        }
        guard let parsedRate = Double(view.rateText) else {
            throw Kit.Failure("parse rate: not a number")
        }
        return parsedMinimum + Double(parsedRetries) + parsedRate
    }
}
