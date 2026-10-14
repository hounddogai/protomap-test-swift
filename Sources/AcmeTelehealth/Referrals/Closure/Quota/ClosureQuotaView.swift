import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a closure quota.
    final class ClosureQuotaView {
        var code: String
        var title: String
        var segment: String
        var active: String
        var unitText: String
        var cost: String
        var locale: String
        var maximum: String
        var discount: String
        var archived: String
        var label: String
        var statusLabel: String

        init(code: String, title: String, segment: String, active: String, unitText: String, cost: String, locale: String, maximum: String, discount: String, archived: String, label: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.segment = segment
            self.active = active
            self.unitText = unitText
            self.cost = cost
            self.locale = locale
            self.maximum = maximum
            self.discount = discount
            self.archived = archived
            self.label = label
            self.statusLabel = statusLabel
        }
    }

    static func toClosureQuotaView(_ item: ClosureQuota) -> ClosureQuotaView {
        return ClosureQuotaView(
            code: Kit.Text.truncate(item.code, limit: 40),
            title: item.title,
            segment: Kit.Text.truncate(item.segment, limit: 80),
            active: "\(item.active)",
            unitText: item.unit,
            cost: String(format: "%.2f", item.cost),
            locale: item.locale,
            maximum: String(format: "%.2f", item.maximum),
            discount: String(format: "%.2f", item.discount),
            archived: "\(item.archived)",
            label: item.label,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toClosureQuotaViews(_ items: [ClosureQuota]) -> [ClosureQuotaView] {
        var views: [ClosureQuotaView] = []
        for item in items {
            views.append(toClosureQuotaView(item))
        }
        return views
    }

    static func sumClosureQuotaView(_ view: ClosureQuotaView) throws -> Double {
        guard let parsedCost = Double(view.cost) else {
            throw Kit.Failure("parse cost: not a number")
        }
        guard let parsedMaximum = Double(view.maximum) else {
            throw Kit.Failure("parse maximum: not a number")
        }
        guard let parsedDiscount = Double(view.discount) else {
            throw Kit.Failure("parse discount: not a number")
        }
        return parsedCost + parsedMaximum + parsedDiscount
    }
}
