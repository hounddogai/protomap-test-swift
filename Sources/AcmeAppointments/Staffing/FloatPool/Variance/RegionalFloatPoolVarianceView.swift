import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a regional float pool variance.
    final class RegionalFloatPoolVarianceView {
        var code: String
        var titleText: String
        var summaryText: String
        var limit: String
        var rate: String
        var statusLabel: String

        init(code: String, titleText: String, summaryText: String, limit: String, rate: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.summaryText = summaryText
            self.limit = limit
            self.rate = rate
            self.statusLabel = statusLabel
        }
    }

    static func toRegionalFloatPoolVarianceView(_ item: RegionalFloatPoolVariance) -> RegionalFloatPoolVarianceView {
        return RegionalFloatPoolVarianceView(
            code: item.code,
            titleText: item.title,
            summaryText: item.summary,
            limit: String(item.limit),
            rate: String(format: "%.2f", item.rate),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRegionalFloatPoolVarianceViews(_ items: [RegionalFloatPoolVariance]) -> [RegionalFloatPoolVarianceView] {
        var views: [RegionalFloatPoolVarianceView] = []
        for item in items {
            views.append(toRegionalFloatPoolVarianceView(item))
        }
        return views
    }

    static func sumRegionalFloatPoolVarianceView(_ view: RegionalFloatPoolVarianceView) throws -> Double {
        guard let parsedLimit = Int(view.limit) else {
            throw Kit.Failure("parse limit: not a number")
        }
        guard let parsedRate = Double(view.rate) else {
            throw Kit.Failure("parse rate: not a number")
        }
        return Double(parsedLimit) + parsedRate
    }
}
