import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a goal bundle.
    final class GoalBundleView {
        var code: String
        var title: String
        var endsAt: String
        var procedureCode: String
        var margin: String
        var region: String
        var expiresAt: String
        var externalRef: String
        var locale: String
        var statusLabel: String

        init(code: String, title: String, endsAt: String, procedureCode: String, margin: String, region: String, expiresAt: String, externalRef: String, locale: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.endsAt = endsAt
            self.procedureCode = procedureCode
            self.margin = margin
            self.region = region
            self.expiresAt = expiresAt
            self.externalRef = externalRef
            self.locale = locale
            self.statusLabel = statusLabel
        }
    }

    static func toGoalBundleView(_ item: GoalBundle) -> GoalBundleView {
        return GoalBundleView(
            code: item.code,
            title: Kit.Text.truncate(item.title, limit: 64),
            endsAt: String(item.endsAt),
            procedureCode: Kit.Text.truncate(item.procedureCode, limit: 40),
            margin: String(format: "%.2f", item.margin),
            region: item.region,
            expiresAt: String(item.expiresAt),
            externalRef: item.externalRef,
            locale: Kit.Text.truncate(item.locale, limit: 40),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toGoalBundleViews(_ items: [GoalBundle]) -> [GoalBundleView] {
        var views: [GoalBundleView] = []
        for item in items {
            views.append(toGoalBundleView(item))
        }
        return views
    }

    static func sumGoalBundleView(_ view: GoalBundleView) throws -> Double {
        guard let parsedEndsAt = Int(view.endsAt) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        guard let parsedMargin = Double(view.margin) else {
            throw Kit.Failure("parse margin: not a number")
        }
        guard let parsedExpiresAt = Int(view.expiresAt) else {
            throw Kit.Failure("parse expires at: not a number")
        }
        return Double(parsedEndsAt) + parsedMargin + Double(parsedExpiresAt)
    }
}
