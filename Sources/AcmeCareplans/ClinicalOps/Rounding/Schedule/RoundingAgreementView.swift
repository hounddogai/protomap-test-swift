import AcmePlatform
import Foundation

extension ClinicalOps {
    /// How screens and exports show a rounding agreement.
    final class RoundingAgreementView {
        var code: String
        var label: String
        var payerText: String
        var dosageMg: String
        var source: String
        var reviewerText: String
        var durationMinutes: String
        var threshold: String
        var statusLabel: String

        init(code: String, label: String, payerText: String, dosageMg: String, source: String, reviewerText: String, durationMinutes: String, threshold: String, statusLabel: String) {
            self.code = code
            self.label = label
            self.payerText = payerText
            self.dosageMg = dosageMg
            self.source = source
            self.reviewerText = reviewerText
            self.durationMinutes = durationMinutes
            self.threshold = threshold
            self.statusLabel = statusLabel
        }
    }

    static func toRoundingAgreementView(_ item: RoundingAgreement) -> RoundingAgreementView {
        return RoundingAgreementView(
            code: item.code,
            label: item.label,
            payerText: item.payer,
            dosageMg: String(format: "%.2f", item.dosageMg),
            source: Kit.Text.truncate(item.source, limit: 120),
            reviewerText: item.reviewer,
            durationMinutes: String(item.durationMinutes),
            threshold: String(format: "%.2f", item.threshold),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toRoundingAgreementViews(_ items: [RoundingAgreement]) -> [RoundingAgreementView] {
        var views: [RoundingAgreementView] = []
        for item in items {
            views.append(toRoundingAgreementView(item))
        }
        return views
    }

    static func sumRoundingAgreementView(_ view: RoundingAgreementView) throws -> Double {
        guard let parsedDosageMg = Double(view.dosageMg) else {
            throw Kit.Failure("parse dosage mg: not a number")
        }
        guard let parsedDurationMinutes = Int(view.durationMinutes) else {
            throw Kit.Failure("parse duration minutes: not a number")
        }
        guard let parsedThreshold = Double(view.threshold) else {
            throw Kit.Failure("parse threshold: not a number")
        }
        return parsedDosageMg + Double(parsedDurationMinutes) + parsedThreshold
    }
}
