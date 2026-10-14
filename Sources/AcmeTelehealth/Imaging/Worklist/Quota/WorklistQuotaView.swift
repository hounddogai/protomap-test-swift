import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a worklist quota.
    final class WorklistQuotaView {
        var code: String
        var title: String
        var createdAt: String
        var minimum: String
        var retries: String
        var amount: String
        var floorValue: String
        var quantityText: String
        var currencyText: String
        var durationMinutesText: String
        var phone: String
        var statusLabel: String

        init(code: String, title: String, createdAt: String, minimum: String, retries: String, amount: String, floorValue: String, quantityText: String, currencyText: String, durationMinutesText: String, phone: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.createdAt = createdAt
            self.minimum = minimum
            self.retries = retries
            self.amount = amount
            self.floorValue = floorValue
            self.quantityText = quantityText
            self.currencyText = currencyText
            self.durationMinutesText = durationMinutesText
            self.phone = phone
            self.statusLabel = statusLabel
        }
    }

    static func toWorklistQuotaView(_ item: WorklistQuota) -> WorklistQuotaView {
        return WorklistQuotaView(
            code: Kit.Text.truncate(item.code, limit: 120),
            title: item.title,
            createdAt: String(item.createdAt),
            minimum: String(format: "%.2f", item.minimum),
            retries: String(item.retries),
            amount: String(format: "%.2f", item.amount),
            floorValue: String(format: "%.2f", item.floorValue),
            quantityText: String(item.quantity),
            currencyText: item.currency,
            durationMinutesText: String(item.durationMinutes),
            phone: item.phone,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toWorklistQuotaViews(_ items: [WorklistQuota]) -> [WorklistQuotaView] {
        var views: [WorklistQuotaView] = []
        for item in items {
            views.append(toWorklistQuotaView(item))
        }
        return views
    }

    static func sumWorklistQuotaView(_ view: WorklistQuotaView) throws -> Double {
        guard let parsedCreatedAt = Int(view.createdAt) else {
            throw Kit.Failure("parse created at: not a number")
        }
        guard let parsedMinimum = Double(view.minimum) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        guard let parsedRetries = Int(view.retries) else {
            throw Kit.Failure("parse retries: not a number")
        }
        return Double(parsedCreatedAt) + parsedMinimum + Double(parsedRetries)
    }
}
