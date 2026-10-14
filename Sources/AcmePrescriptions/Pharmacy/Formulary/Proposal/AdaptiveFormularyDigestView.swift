import AcmePlatform
import Foundation

extension Pharmacy {
    /// How screens and exports show a adaptive formulary digest.
    final class AdaptiveFormularyDigestView {
        var code: String
        var labelText: String
        var bed: String
        var amountText: String
        var ownerID: String
        var rate: String
        var statusLabel: String

        init(code: String, labelText: String, bed: String, amountText: String, ownerID: String, rate: String, statusLabel: String) {
            self.code = code
            self.labelText = labelText
            self.bed = bed
            self.amountText = amountText
            self.ownerID = ownerID
            self.rate = rate
            self.statusLabel = statusLabel
        }
    }

    static func toAdaptiveFormularyDigestView(_ item: AdaptiveFormularyDigest) -> AdaptiveFormularyDigestView {
        return AdaptiveFormularyDigestView(
            code: Kit.Text.truncate(item.code, limit: 80),
            labelText: Kit.Text.truncate(item.label, limit: 120),
            bed: item.bed,
            amountText: String(format: "%.2f", item.amount),
            ownerID: item.ownerID,
            rate: String(format: "%.2f", item.rate),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toAdaptiveFormularyDigestViews(_ items: [AdaptiveFormularyDigest]) -> [AdaptiveFormularyDigestView] {
        var views: [AdaptiveFormularyDigestView] = []
        for item in items {
            views.append(toAdaptiveFormularyDigestView(item))
        }
        return views
    }

    static func sumAdaptiveFormularyDigestView(_ view: AdaptiveFormularyDigestView) throws -> Double {
        guard let parsedAmount = Double(view.amountText) else {
            throw Kit.Failure("parse amount: not a number")
        }
        guard let parsedRate = Double(view.rate) else {
            throw Kit.Failure("parse rate: not a number")
        }
        return parsedAmount + parsedRate
    }
}
