import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a courier policy.
    final class CourierPolicyView {
        var code: String
        var name: String
        var categoryText: String
        var graceDays: String
        var minimumText: String
        var expiresAt: String
        var titleText: String
        var statusLabel: String

        init(code: String, name: String, categoryText: String, graceDays: String, minimumText: String, expiresAt: String, titleText: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.categoryText = categoryText
            self.graceDays = graceDays
            self.minimumText = minimumText
            self.expiresAt = expiresAt
            self.titleText = titleText
            self.statusLabel = statusLabel
        }
    }

    static func toCourierPolicyView(_ item: CourierPolicy) -> CourierPolicyView {
        return CourierPolicyView(
            code: Kit.Text.truncate(item.code, limit: 64),
            name: Kit.Text.truncate(item.name, limit: 64),
            categoryText: item.category,
            graceDays: String(item.graceDays),
            minimumText: String(format: "%.2f", item.minimum),
            expiresAt: String(item.expiresAt),
            titleText: Kit.Text.truncate(item.title, limit: 40),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toCourierPolicyViews(_ items: [CourierPolicy]) -> [CourierPolicyView] {
        var views: [CourierPolicyView] = []
        for item in items {
            views.append(toCourierPolicyView(item))
        }
        return views
    }

    static func sumCourierPolicyView(_ view: CourierPolicyView) throws -> Double {
        guard let parsedGraceDays = Int(view.graceDays) else {
            throw Kit.Failure("parse grace days: not a number")
        }
        guard let parsedMinimum = Double(view.minimumText) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        guard let parsedExpiresAt = Int(view.expiresAt) else {
            throw Kit.Failure("parse expires at: not a number")
        }
        return Double(parsedGraceDays) + parsedMinimum + Double(parsedExpiresAt)
    }
}
