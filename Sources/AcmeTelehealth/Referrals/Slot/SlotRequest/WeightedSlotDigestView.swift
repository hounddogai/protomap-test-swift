import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a weighted slot digest.
    final class WeightedSlotDigestView {
        var code: String
        var name: String
        var phoneText: String
        var updatedAtText: String
        var rateText: String
        var payerText: String
        var retries: String
        var endsAtText: String
        var quantity: String
        var limitText: String
        var statusLabel: String

        init(code: String, name: String, phoneText: String, updatedAtText: String, rateText: String, payerText: String, retries: String, endsAtText: String, quantity: String, limitText: String, statusLabel: String) {
            self.code = code
            self.name = name
            self.phoneText = phoneText
            self.updatedAtText = updatedAtText
            self.rateText = rateText
            self.payerText = payerText
            self.retries = retries
            self.endsAtText = endsAtText
            self.quantity = quantity
            self.limitText = limitText
            self.statusLabel = statusLabel
        }
    }

    static func toWeightedSlotDigestView(_ item: WeightedSlotDigest) -> WeightedSlotDigestView {
        return WeightedSlotDigestView(
            code: item.code,
            name: item.name,
            phoneText: Kit.Text.truncate(item.phone, limit: 120),
            updatedAtText: String(item.updatedAt),
            rateText: String(format: "%.2f", item.rate),
            payerText: item.payer,
            retries: String(item.retries),
            endsAtText: String(item.endsAt),
            quantity: String(item.quantity),
            limitText: String(item.limit),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toWeightedSlotDigestViews(_ items: [WeightedSlotDigest]) -> [WeightedSlotDigestView] {
        var views: [WeightedSlotDigestView] = []
        for item in items {
            views.append(toWeightedSlotDigestView(item))
        }
        return views
    }

    static func sumWeightedSlotDigestView(_ view: WeightedSlotDigestView) throws -> Double {
        guard let parsedUpdatedAt = Int(view.updatedAtText) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        guard let parsedRate = Double(view.rateText) else {
            throw Kit.Failure("parse rate: not a number")
        }
        guard let parsedRetries = Int(view.retries) else {
            throw Kit.Failure("parse retries: not a number")
        }
        return Double(parsedUpdatedAt) + parsedRate + Double(parsedRetries)
    }
}
