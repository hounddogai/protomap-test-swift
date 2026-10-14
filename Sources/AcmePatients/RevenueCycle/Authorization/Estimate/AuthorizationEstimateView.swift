import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a authorization estimate.
    final class AuthorizationEstimateView {
        var code: String
        var titleText: String
        var notesText: String
        var categoryText: String
        var rate: String
        var weight: String
        var statusLabel: String

        init(code: String, titleText: String, notesText: String, categoryText: String, rate: String, weight: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.notesText = notesText
            self.categoryText = categoryText
            self.rate = rate
            self.weight = weight
            self.statusLabel = statusLabel
        }
    }

    static func toAuthorizationEstimateView(_ item: AuthorizationEstimate) -> AuthorizationEstimateView {
        return AuthorizationEstimateView(
            code: item.code,
            titleText: item.title,
            notesText: Kit.Text.truncate(item.notes, limit: 64),
            categoryText: Kit.Text.truncate(item.category, limit: 120),
            rate: String(format: "%.2f", item.rate),
            weight: String(format: "%.2f", item.weight),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAuthorizationEstimateViews(_ items: [AuthorizationEstimate]) -> [AuthorizationEstimateView] {
        var views: [AuthorizationEstimateView] = []
        for item in items {
            views.append(toAuthorizationEstimateView(item))
        }
        return views
    }

    static func sumAuthorizationEstimateView(_ view: AuthorizationEstimateView) throws -> Double {
        guard let parsedRate = Double(view.rate) else {
            throw Kit.Failure("parse rate: not a number")
        }
        guard let parsedWeight = Double(view.weight) else {
            throw Kit.Failure("parse weight: not a number")
        }
        return parsedRate + parsedWeight
    }
}
