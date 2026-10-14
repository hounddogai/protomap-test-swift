import AcmePlatform
import Foundation

extension Consent {
    /// How screens and exports show a fallback language claim.
    final class FallbackLanguageClaimView {
        var codeText: String
        var label: String
        var amount: String
        var segment: String
        var dosageMg: String
        var summary: String
        var statusLabel: String

        init(codeText: String, label: String, amount: String, segment: String, dosageMg: String, summary: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.amount = amount
            self.segment = segment
            self.dosageMg = dosageMg
            self.summary = summary
            self.statusLabel = statusLabel
        }
    }

    static func toFallbackLanguageClaimView(_ item: FallbackLanguageClaim) -> FallbackLanguageClaimView {
        return FallbackLanguageClaimView(
            codeText: item.code,
            label: item.label,
            amount: String(format: "%.2f", item.amount),
            segment: item.segment,
            dosageMg: String(format: "%.2f", item.dosageMg),
            summary: Kit.Text.truncate(item.summary, limit: 40),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toFallbackLanguageClaimViews(_ items: [FallbackLanguageClaim]) -> [FallbackLanguageClaimView] {
        var views: [FallbackLanguageClaimView] = []
        for item in items {
            views.append(toFallbackLanguageClaimView(item))
        }
        return views
    }

    static func sumFallbackLanguageClaimView(_ view: FallbackLanguageClaimView) throws -> Double {
        guard let parsedAmount = Double(view.amount) else {
            throw Kit.Failure("parse amount: not a number")
        }
        guard let parsedDosageMg = Double(view.dosageMg) else {
            throw Kit.Failure("parse dosage mg: not a number")
        }
        return parsedAmount + parsedDosageMg
    }
}
