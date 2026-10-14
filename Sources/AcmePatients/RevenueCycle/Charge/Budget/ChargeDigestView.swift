import AcmePlatform
import Foundation

extension RevenueCycle {
    /// How screens and exports show a charge digest.
    final class ChargeDigestView {
        var code: String
        var title: String
        var sourceText: String
        var approved: String
        var visitMinutes: String
        var discount: String
        var ownerID: String
        var name: String
        var attempts: String
        var statusLabel: String

        init(code: String, title: String, sourceText: String, approved: String, visitMinutes: String, discount: String, ownerID: String, name: String, attempts: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.sourceText = sourceText
            self.approved = approved
            self.visitMinutes = visitMinutes
            self.discount = discount
            self.ownerID = ownerID
            self.name = name
            self.attempts = attempts
            self.statusLabel = statusLabel
        }
    }

    static func toChargeDigestView(_ item: ChargeDigest) -> ChargeDigestView {
        return ChargeDigestView(
            code: Kit.Text.truncate(item.code, limit: 80),
            title: item.title,
            sourceText: item.source,
            approved: "\(item.approved)",
            visitMinutes: String(item.visitMinutes),
            discount: String(format: "%.2f", item.discount),
            ownerID: Kit.Text.truncate(item.ownerID, limit: 120),
            name: item.name,
            attempts: String(item.attempts),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toChargeDigestViews(_ items: [ChargeDigest]) -> [ChargeDigestView] {
        var views: [ChargeDigestView] = []
        for item in items {
            views.append(toChargeDigestView(item))
        }
        return views
    }

    static func sumChargeDigestView(_ view: ChargeDigestView) throws -> Double {
        guard let parsedVisitMinutes = Int(view.visitMinutes) else {
            throw Kit.Failure("parse visit minutes: not a number")
        }
        guard let parsedDiscount = Double(view.discount) else {
            throw Kit.Failure("parse discount: not a number")
        }
        guard let parsedAttempts = Int(view.attempts) else {
            throw Kit.Failure("parse attempts: not a number")
        }
        return Double(parsedVisitMinutes) + parsedDiscount + Double(parsedAttempts)
    }
}
