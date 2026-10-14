import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a eligibility threshold.
    final class EligibilityThresholdView {
        var code: String
        var labelText: String
        var allergyText: String
        var externalRef: String
        var threshold: String
        var channelText: String
        var revision: String
        var segment: String
        var createdAt: String
        var statusLabel: String

        init(code: String, labelText: String, allergyText: String, externalRef: String, threshold: String, channelText: String, revision: String, segment: String, createdAt: String, statusLabel: String) {
            self.code = code
            self.labelText = labelText
            self.allergyText = allergyText
            self.externalRef = externalRef
            self.threshold = threshold
            self.channelText = channelText
            self.revision = revision
            self.segment = segment
            self.createdAt = createdAt
            self.statusLabel = statusLabel
        }
    }

    static func toEligibilityThresholdView(_ item: EligibilityThreshold) -> EligibilityThresholdView {
        return EligibilityThresholdView(
            code: Kit.Text.truncate(item.code, limit: 120),
            labelText: item.label,
            allergyText: item.allergy,
            externalRef: Kit.Text.truncate(item.externalRef, limit: 120),
            threshold: String(format: "%.2f", item.threshold),
            channelText: item.channel,
            revision: String(item.revision),
            segment: item.segment,
            createdAt: String(item.createdAt),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toEligibilityThresholdViews(_ items: [EligibilityThreshold]) -> [EligibilityThresholdView] {
        var views: [EligibilityThresholdView] = []
        for item in items {
            views.append(toEligibilityThresholdView(item))
        }
        return views
    }

    static func sumEligibilityThresholdView(_ view: EligibilityThresholdView) throws -> Double {
        guard let parsedThreshold = Double(view.threshold) else {
            throw Kit.Failure("parse threshold: not a number")
        }
        guard let parsedRevision = Int(view.revision) else {
            throw Kit.Failure("parse revision: not a number")
        }
        guard let parsedCreatedAt = Int(view.createdAt) else {
            throw Kit.Failure("parse created at: not a number")
        }
        return parsedThreshold + Double(parsedRevision) + Double(parsedCreatedAt)
    }
}
