import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a order set quota.
    final class OrderSetQuotaView {
        var code: String
        var labelText: String
        var quantity: String
        var threshold: String
        var countryText: String
        var descriptionText: String
        var titleText: String
        var updatedAtText: String
        var channel: String
        var cost: String
        var allergy: String
        var statusLabel: String

        init(code: String, labelText: String, quantity: String, threshold: String, countryText: String, descriptionText: String, titleText: String, updatedAtText: String, channel: String, cost: String, allergy: String, statusLabel: String) {
            self.code = code
            self.labelText = labelText
            self.quantity = quantity
            self.threshold = threshold
            self.countryText = countryText
            self.descriptionText = descriptionText
            self.titleText = titleText
            self.updatedAtText = updatedAtText
            self.channel = channel
            self.cost = cost
            self.allergy = allergy
            self.statusLabel = statusLabel
        }
    }

    static func toOrderSetQuotaView(_ item: OrderSetQuota) -> OrderSetQuotaView {
        return OrderSetQuotaView(
            code: Kit.Text.truncate(item.code, limit: 64),
            labelText: Kit.Text.truncate(item.label, limit: 80),
            quantity: String(item.quantity),
            threshold: String(format: "%.2f", item.threshold),
            countryText: item.country,
            descriptionText: item.description,
            titleText: Kit.Text.truncate(item.title, limit: 80),
            updatedAtText: String(item.updatedAt),
            channel: item.channel,
            cost: String(format: "%.2f", item.cost),
            allergy: Kit.Text.truncate(item.allergy, limit: 40),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toOrderSetQuotaViews(_ items: [OrderSetQuota]) -> [OrderSetQuotaView] {
        var views: [OrderSetQuotaView] = []
        for item in items {
            views.append(toOrderSetQuotaView(item))
        }
        return views
    }

    static func sumOrderSetQuotaView(_ view: OrderSetQuotaView) throws -> Double {
        guard let parsedQuantity = Int(view.quantity) else {
            throw Kit.Failure("parse quantity: not a number")
        }
        guard let parsedThreshold = Double(view.threshold) else {
            throw Kit.Failure("parse threshold: not a number")
        }
        guard let parsedUpdatedAt = Int(view.updatedAtText) else {
            throw Kit.Failure("parse updated at: not a number")
        }
        return Double(parsedQuantity) + parsedThreshold + Double(parsedUpdatedAt)
    }
}
