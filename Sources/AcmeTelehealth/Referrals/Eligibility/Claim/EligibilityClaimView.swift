import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a eligibility claim.
    final class EligibilityClaimView {
        var codeText: String
        var title: String
        var rate: String
        var thresholdText: String
        var sequenceText: String
        var statusLabel: String

        init(codeText: String, title: String, rate: String, thresholdText: String, sequenceText: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.rate = rate
            self.thresholdText = thresholdText
            self.sequenceText = sequenceText
            self.statusLabel = statusLabel
        }
    }

    static func toEligibilityClaimView(_ item: EligibilityClaim) -> EligibilityClaimView {
        return EligibilityClaimView(
            codeText: Kit.Text.truncate(item.code, limit: 80),
            title: Kit.Text.truncate(item.title, limit: 80),
            rate: String(format: "%.2f", item.rate),
            thresholdText: String(format: "%.2f", item.threshold),
            sequenceText: String(item.sequence),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toEligibilityClaimViews(_ items: [EligibilityClaim]) -> [EligibilityClaimView] {
        var views: [EligibilityClaimView] = []
        for item in items {
            views.append(toEligibilityClaimView(item))
        }
        return views
    }

    static func sumEligibilityClaimView(_ view: EligibilityClaimView) throws -> Double {
        guard let parsedRate = Double(view.rate) else {
            throw Kit.Failure("parse rate: not a number")
        }
        guard let parsedThreshold = Double(view.thresholdText) else {
            throw Kit.Failure("parse threshold: not a number")
        }
        guard let parsedSequence = Int(view.sequenceText) else {
            throw Kit.Failure("parse sequence: not a number")
        }
        return parsedRate + parsedThreshold + Double(parsedSequence)
    }
}
