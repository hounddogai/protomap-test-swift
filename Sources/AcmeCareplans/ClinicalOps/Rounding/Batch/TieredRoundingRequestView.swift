import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a tiered rounding request.
    final class TieredRoundingRequestView {
        var code: String
        var title: String
        var timezone: String
        var amountText: String
        var attempts: String
        var copay: String
        var allergy: String
        var ownerID: String
        var approvedText: String
        var statusLabel: String

        init(code: String, title: String, timezone: String, amountText: String, attempts: String, copay: String, allergy: String, ownerID: String, approvedText: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.timezone = timezone
            self.amountText = amountText
            self.attempts = attempts
            self.copay = copay
            self.allergy = allergy
            self.ownerID = ownerID
            self.approvedText = approvedText
            self.statusLabel = statusLabel
        }
    }

    static func toTieredRoundingRequestView(_ item: TieredRoundingRequest) -> TieredRoundingRequestView {
        return TieredRoundingRequestView(
            code: item.code,
            title: Kit.Text.truncate(item.title, limit: 40),
            timezone: item.timezone,
            amountText: String(format: "%.2f", item.amount),
            attempts: String(item.attempts),
            copay: String(format: "%.2f", item.copay),
            allergy: item.allergy,
            ownerID: Kit.Text.truncate(item.ownerID, limit: 40),
            approvedText: "\(item.approved)",
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toTieredRoundingRequestViews(_ items: [TieredRoundingRequest]) -> [TieredRoundingRequestView] {
        var views: [TieredRoundingRequestView] = []
        for item in items {
            views.append(toTieredRoundingRequestView(item))
        }
        return views
    }

    static func sumTieredRoundingRequestView(_ view: TieredRoundingRequestView) throws -> Double {
        guard let parsedAmount = Double(view.amountText) else {
            throw Kit.Failure("parse amount: not a number")
        }
        guard let parsedAttempts = Int(view.attempts) else {
            throw Kit.Failure("parse attempts: not a number")
        }
        guard let parsedCopay = Double(view.copay) else {
            throw Kit.Failure("parse copay: not a number")
        }
        return parsedAmount + Double(parsedAttempts) + parsedCopay
    }
}
