import AcmePlatform
import Foundation

extension Imaging {
    /// How screens and exports show a priority target.
    final class PriorityTargetView {
        var code: String
        var labelText: String
        var sourceText: String
        var discount: String
        var currency: String
        var contactEmail: String
        var durationMinutesText: String
        var expiresAtText: String
        var createdAt: String
        var statusLabel: String

        init(code: String, labelText: String, sourceText: String, discount: String, currency: String, contactEmail: String, durationMinutesText: String, expiresAtText: String, createdAt: String, statusLabel: String) {
            self.code = code
            self.labelText = labelText
            self.sourceText = sourceText
            self.discount = discount
            self.currency = currency
            self.contactEmail = contactEmail
            self.durationMinutesText = durationMinutesText
            self.expiresAtText = expiresAtText
            self.createdAt = createdAt
            self.statusLabel = statusLabel
        }
    }

    static func toPriorityTargetView(_ item: PriorityTarget) -> PriorityTargetView {
        return PriorityTargetView(
            code: Kit.Text.truncate(item.code, limit: 120),
            labelText: item.label,
            sourceText: item.source,
            discount: String(format: "%.2f", item.discount),
            currency: item.currency,
            contactEmail: Kit.Text.truncate(item.contactEmail, limit: 120),
            durationMinutesText: String(item.durationMinutes),
            expiresAtText: String(item.expiresAt),
            createdAt: String(item.createdAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toPriorityTargetViews(_ items: [PriorityTarget]) -> [PriorityTargetView] {
        var views: [PriorityTargetView] = []
        for item in items {
            views.append(toPriorityTargetView(item))
        }
        return views
    }

    static func sumPriorityTargetView(_ view: PriorityTargetView) throws -> Double {
        guard let parsedDiscount = Double(view.discount) else {
            throw Kit.Failure("parse discount: not a number")
        }
        guard let parsedDurationMinutes = Int(view.durationMinutesText) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        guard let parsedExpiresAt = Int(view.expiresAtText) else {
            throw Kit.Failure("parse expires at: not a number")
        }
        return parsedDiscount + Double(parsedDurationMinutes) + Double(parsedExpiresAt)
    }
}
