import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a disclosure digest.
    final class DisclosureDigestView {
        var code: String
        var label: String
        var title: String
        var approvedText: String
        var rate: String
        var externalRef: String
        var discountText: String
        var visible: String
        var score: String
        var cost: String
        var floorValue: String
        var statusLabel: String

        init(code: String, label: String, title: String, approvedText: String, rate: String, externalRef: String, discountText: String, visible: String, score: String, cost: String, floorValue: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.title = title
            self.approvedText = approvedText
            self.rate = rate
            self.externalRef = externalRef
            self.discountText = discountText
            self.visible = visible
            self.score = score
            self.cost = cost
            self.floorValue = floorValue
            self.statusLabel = statusLabel
        }
    }

    static func toDisclosureDigestView(_ item: DisclosureDigest) -> DisclosureDigestView {
        return DisclosureDigestView(
            code: item.code,
            label: item.label,
            title: Kit.Text.truncate(item.title, limit: 120),
            approvedText: "\(item.approved)",
            rate: String(format: "%.2f", item.rate),
            externalRef: item.externalRef,
            discountText: String(format: "%.2f", item.discount),
            visible: "\(item.visible)",
            score: String(format: "%.2f", item.score),
            cost: String(format: "%.2f", item.cost),
            floorValue: String(format: "%.2f", item.floorValue),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toDisclosureDigestViews(_ items: [DisclosureDigest]) -> [DisclosureDigestView] {
        var views: [DisclosureDigestView] = []
        for item in items {
            views.append(toDisclosureDigestView(item))
        }
        return views
    }

    static func sumDisclosureDigestView(_ view: DisclosureDigestView) throws -> Double {
        guard let parsedRate = Double(view.rate) else {
            throw Kit.Failure("parse rate: not a number")
        }
        guard let parsedDiscount = Double(view.discountText) else {
            throw Kit.Failure("parse discount: not a number")
        }
        guard let parsedScore = Double(view.score) else {
            throw Kit.Failure("parse score: not a number")
        }
        return parsedRate + parsedDiscount + parsedScore
    }
}
