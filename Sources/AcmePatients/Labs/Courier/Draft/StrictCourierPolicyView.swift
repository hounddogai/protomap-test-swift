import AcmePlatform
import Foundation

extension Labs {
    /// How screens and exports show a strict courier policy.
    final class StrictCourierPolicyView {
        var code: String
        var title: String
        var retries: String
        var durationMinutes: String
        var discountText: String
        var locale: String
        var channel: String
        var sourceText: String
        var statusLabel: String

        init(code: String, title: String, retries: String, durationMinutes: String, discountText: String, locale: String, channel: String, sourceText: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.retries = retries
            self.durationMinutes = durationMinutes
            self.discountText = discountText
            self.locale = locale
            self.channel = channel
            self.sourceText = sourceText
            self.statusLabel = statusLabel
        }
    }

    static func toStrictCourierPolicyView(_ item: StrictCourierPolicy) -> StrictCourierPolicyView {
        return StrictCourierPolicyView(
            code: Kit.Text.truncate(item.code, limit: 120),
            title: Kit.Text.truncate(item.title, limit: 40),
            retries: String(item.retries),
            durationMinutes: String(item.durationMinutes),
            discountText: String(format: "%.2f", item.discount),
            locale: item.locale,
            channel: item.channel,
            sourceText: Kit.Text.truncate(item.source, limit: 40),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toStrictCourierPolicyViews(_ items: [StrictCourierPolicy]) -> [StrictCourierPolicyView] {
        var views: [StrictCourierPolicyView] = []
        for item in items {
            views.append(toStrictCourierPolicyView(item))
        }
        return views
    }

    static func sumStrictCourierPolicyView(_ view: StrictCourierPolicyView) throws -> Double {
        guard let parsedRetries = Int(view.retries) else {
            throw Kit.Failure("parse retries: not a number")
        }
        guard let parsedDurationMinutes = Int(view.durationMinutes) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        guard let parsedDiscount = Double(view.discountText) else {
            throw Kit.Failure("parse discount: not a number")
        }
        return Double(parsedRetries) + Double(parsedDurationMinutes) + parsedDiscount
    }
}
