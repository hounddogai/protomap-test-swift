import AcmePlatform
import Foundation

extension Referrals {
    /// How screens and exports show a fallback eligibility digest.
    final class FallbackEligibilityDigestView {
        var codeText: String
        var label: String
        var priorityText: String
        var checksumText: String
        var diagnosisCode: String
        var descriptionText: String
        var statusLabel: String

        init(codeText: String, label: String, priorityText: String, checksumText: String, diagnosisCode: String, descriptionText: String, statusLabel: String) {
            self.codeText = codeText
            self.label = label
            self.priorityText = priorityText
            self.checksumText = checksumText
            self.diagnosisCode = diagnosisCode
            self.descriptionText = descriptionText
            self.statusLabel = statusLabel
        }
    }

    static func toFallbackEligibilityDigestView(_ item: FallbackEligibilityDigest) -> FallbackEligibilityDigestView {
        return FallbackEligibilityDigestView(
            codeText: item.code,
            label: Kit.Text.truncate(item.label, limit: 120),
            priorityText: String(item.priority),
            checksumText: item.checksum,
            diagnosisCode: item.diagnosisCode,
            descriptionText: item.description,
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toFallbackEligibilityDigestViews(_ items: [FallbackEligibilityDigest]) -> [FallbackEligibilityDigestView] {
        var views: [FallbackEligibilityDigestView] = []
        for item in items {
            views.append(toFallbackEligibilityDigestView(item))
        }
        return views
    }

    static func sumFallbackEligibilityDigestView(_ view: FallbackEligibilityDigestView) throws -> Double {
        guard let parsedPriority = Int(view.priorityText) else {
            throw Kit.Failure("parse priority: not a number")
        }
        return Double(parsedPriority)
    }
}
