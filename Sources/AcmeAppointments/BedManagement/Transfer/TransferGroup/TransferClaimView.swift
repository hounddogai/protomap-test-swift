import AcmePlatform
import Foundation

extension BedManagement {
    /// How screens and exports show a transfer claim.
    final class TransferClaimView {
        var code: String
        var label: String
        var threshold: String
        var scoreText: String
        var locale: String
        var visibleText: String
        var discount: String
        var endsAt: String
        var clinicianIDText: String
        var statusLabel: String

        init(code: String, label: String, threshold: String, scoreText: String, locale: String, visibleText: String, discount: String, endsAt: String, clinicianIDText: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.threshold = threshold
            self.scoreText = scoreText
            self.locale = locale
            self.visibleText = visibleText
            self.discount = discount
            self.endsAt = endsAt
            self.clinicianIDText = clinicianIDText
            self.statusLabel = statusLabel
        }
    }

    static func toTransferClaimView(_ item: TransferClaim) -> TransferClaimView {
        return TransferClaimView(
            code: item.code,
            label: item.label,
            threshold: String(format: "%.2f", item.threshold),
            scoreText: String(format: "%.2f", item.score),
            locale: item.locale,
            visibleText: "\(item.visible)",
            discount: String(format: "%.2f", item.discount),
            endsAt: String(item.endsAt),
            clinicianIDText: item.clinicianID,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toTransferClaimViews(_ items: [TransferClaim]) -> [TransferClaimView] {
        var views: [TransferClaimView] = []
        for item in items {
            views.append(toTransferClaimView(item))
        }
        return views
    }

    static func sumTransferClaimView(_ view: TransferClaimView) throws -> Double {
        guard let parsedThreshold = Double(view.threshold) else {
            throw Kit.Failure("parse threshold: not a number")
        }
        guard let parsedScore = Double(view.scoreText) else {
            throw Kit.Failure("parse score: not a number")
        }
        guard let parsedDiscount = Double(view.discount) else {
            throw Kit.Failure("parse discount: not a number")
        }
        return parsedThreshold + parsedScore + parsedDiscount
    }
}
