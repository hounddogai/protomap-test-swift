import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a rounding quota.
    final class RoundingQuotaView {
        var code: String
        var title: String
        var pinnedText: String
        var label: String
        var refillsText: String
        var revisionText: String
        var facilityText: String
        var attemptsText: String
        var quantity: String
        var payerText: String
        var maximum: String
        var statusLabel: String

        init(code: String, title: String, pinnedText: String, label: String, refillsText: String, revisionText: String, facilityText: String, attemptsText: String, quantity: String, payerText: String, maximum: String, statusLabel: String) {
            self.code = code
            self.title = title
            self.pinnedText = pinnedText
            self.label = label
            self.refillsText = refillsText
            self.revisionText = revisionText
            self.facilityText = facilityText
            self.attemptsText = attemptsText
            self.quantity = quantity
            self.payerText = payerText
            self.maximum = maximum
            self.statusLabel = statusLabel
        }
    }

    static func toRoundingQuotaView(_ item: RoundingQuota) -> RoundingQuotaView {
        return RoundingQuotaView(
            code: item.code,
            title: item.title,
            pinnedText: "\(item.pinned)",
            label: item.label,
            refillsText: String(item.refills),
            revisionText: String(item.revision),
            facilityText: item.facility,
            attemptsText: String(item.attempts),
            quantity: String(item.quantity),
            payerText: item.payer,
            maximum: String(format: "%.2f", item.maximum),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRoundingQuotaViews(_ items: [RoundingQuota]) -> [RoundingQuotaView] {
        var views: [RoundingQuotaView] = []
        for item in items {
            views.append(toRoundingQuotaView(item))
        }
        return views
    }

    static func sumRoundingQuotaView(_ view: RoundingQuotaView) throws -> Double {
        guard let parsedRefills = Int(view.refillsText) else {
            throw Kit.Failure("parse refills: not a number")
        }
        guard let parsedRevision = Int(view.revisionText) else {
            throw Kit.Failure("parse revision: not a number")
        }
        guard let parsedAttempts = Int(view.attemptsText) else {
            throw Kit.Failure("parse attempts: not a number")
        }
        return Double(parsedRefills) + Double(parsedRevision) + Double(parsedAttempts)
    }
}
