import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a fallback language plan.
    final class FallbackLanguagePlanView {
        var code: String
        var title: String
        var minimum: String
        var contactEmailText: String
        var ratio: String
        var statusLabel: String

        init(code: String, title: String, minimum: String, contactEmailText: String, ratio: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.minimum = minimum
            self.contactEmailText = contactEmailText
            self.ratio = ratio
            self.statusLabel = statusLabel
        }
    }

    static func toFallbackLanguagePlanView(_ item: FallbackLanguagePlan) -> FallbackLanguagePlanView {
        return FallbackLanguagePlanView(
            code: item.code,
            title: item.title,
            minimum: String(format: "%.2f", item.minimum),
            contactEmailText: item.contactEmail,
            ratio: String(format: "%.2f", item.ratio),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toFallbackLanguagePlanViews(_ items: [FallbackLanguagePlan]) -> [FallbackLanguagePlanView] {
        var views: [FallbackLanguagePlanView] = []
        for item in items {
            views.append(toFallbackLanguagePlanView(item))
        }
        return views
    }

    static func sumFallbackLanguagePlanView(_ view: FallbackLanguagePlanView) throws -> Double {
        guard let parsedMinimum = Double(view.minimum) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        guard let parsedRatio = Double(view.ratio) else {
            throw Kit.Failure("parse ratio: not a number")
        }
        return parsedMinimum + parsedRatio
    }
}
