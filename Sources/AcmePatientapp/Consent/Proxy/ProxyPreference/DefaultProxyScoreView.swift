import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a default proxy score.
    final class DefaultProxyScoreView {
        var code: String
        var labelText: String
        var approvedText: String
        var contactEmail: String
        var floorValue: String
        var durationMinutesText: String
        var expiresAt: String
        var amountText: String
        var rate: String
        var statusLabel: String

        init(code: String, labelText: String, approvedText: String, contactEmail: String, floorValue: String, durationMinutesText: String, expiresAt: String, amountText: String, rate: String, statusLabel: String) {
            self.code = code
            self.labelText = labelText
            self.approvedText = approvedText
            self.contactEmail = contactEmail
            self.floorValue = floorValue
            self.durationMinutesText = durationMinutesText
            self.expiresAt = expiresAt
            self.amountText = amountText
            self.rate = rate
            self.statusLabel = statusLabel
        }
    }

    static func toDefaultProxyScoreView(_ item: DefaultProxyScore) -> DefaultProxyScoreView {
        return DefaultProxyScoreView(
            code: item.code,
            labelText: item.label,
            approvedText: "\(item.approved)",
            contactEmail: item.contactEmail,
            floorValue: String(format: "%.2f", item.floorValue),
            durationMinutesText: String(item.durationMinutes),
            expiresAt: String(item.expiresAt),
            amountText: String(format: "%.2f", item.amount),
            rate: String(format: "%.2f", item.rate),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toDefaultProxyScoreViews(_ items: [DefaultProxyScore]) -> [DefaultProxyScoreView] {
        var views: [DefaultProxyScoreView] = []
        for item in items {
            views.append(toDefaultProxyScoreView(item))
        }
        return views
    }

    static func sumDefaultProxyScoreView(_ view: DefaultProxyScoreView) throws -> Double {
        guard let parsedFloorValue = Double(view.floorValue) else {
            throw Kit.Failure("parse floor value: not a number")
        }
        guard let parsedDurationMinutes = Int(view.durationMinutesText) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        guard let parsedExpiresAt = Int(view.expiresAt) else {
            throw Kit.Failure("parse expires at: not a number")
        }
        return parsedFloorValue + Double(parsedDurationMinutes) + Double(parsedExpiresAt)
    }
}
