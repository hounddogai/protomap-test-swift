import AcmePlatform
import Foundation

extension Staffing {
    /// How screens and exports show a primary float pool quota.
    final class PrimaryFloatPoolQuotaView {
        var code: String
        var titleText: String
        var endsAt: String
        var minimum: String
        var discount: String
        var country: String
        var statusLabel: String

        init(code: String, titleText: String, endsAt: String, minimum: String, discount: String, country: String, statusLabel: String) {
            self.code = code
            self.titleText = titleText
            self.endsAt = endsAt
            self.minimum = minimum
            self.discount = discount
            self.country = country
            self.statusLabel = statusLabel
        }
    }

    static func toPrimaryFloatPoolQuotaView(_ item: PrimaryFloatPoolQuota) -> PrimaryFloatPoolQuotaView {
        return PrimaryFloatPoolQuotaView(
            code: item.code,
            titleText: item.title,
            endsAt: String(item.endsAt),
            minimum: String(format: "%.2f", item.minimum),
            discount: String(format: "%.2f", item.discount),
            country: item.country,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPrimaryFloatPoolQuotaViews(_ items: [PrimaryFloatPoolQuota]) -> [PrimaryFloatPoolQuotaView] {
        var views: [PrimaryFloatPoolQuotaView] = []
        for item in items {
            views.append(toPrimaryFloatPoolQuotaView(item))
        }
        return views
    }

    static func sumPrimaryFloatPoolQuotaView(_ view: PrimaryFloatPoolQuotaView) throws -> Double {
        guard let parsedEndsAt = Int(view.endsAt) else {
            throw Kit.Failure("parse ends at: not a number")
        }
        guard let parsedMinimum = Double(view.minimum) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        guard let parsedDiscount = Double(view.discount) else {
            throw Kit.Failure("parse discount: not a number")
        }
        return Double(parsedEndsAt) + parsedMinimum + parsedDiscount
    }
}
