import AcmePlatform
import Foundation

extension CareManagement {
    /// How screens and exports show a fallback assessment manifest.
    final class FallbackAssessmentManifestView {
        var codeText: String
        var title: String
        var revision: String
        var externalRefText: String
        var minimum: String
        var contactEmailText: String
        var pinned: String
        var reviewer: String
        var rate: String
        var bedText: String
        var statusLabel: String

        init(codeText: String, title: String, revision: String, externalRefText: String, minimum: String, contactEmailText: String, pinned: String, reviewer: String, rate: String, bedText: String, statusLabel: String) {
            self.codeText = codeText
            self.title = title
            self.revision = revision
            self.externalRefText = externalRefText
            self.minimum = minimum
            self.contactEmailText = contactEmailText
            self.pinned = pinned
            self.reviewer = reviewer
            self.rate = rate
            self.bedText = bedText
            self.statusLabel = statusLabel
        }
    }

    static func toFallbackAssessmentManifestView(_ item: FallbackAssessmentManifest) -> FallbackAssessmentManifestView {
        return FallbackAssessmentManifestView(
            codeText: item.code,
            title: item.title,
            revision: String(item.revision),
            externalRefText: item.externalRef,
            minimum: String(format: "%.2f", item.minimum),
            contactEmailText: item.contactEmail,
            pinned: "\(item.pinned)",
            reviewer: item.reviewer,
            rate: String(format: "%.2f", item.rate),
            bedText: Kit.Text.truncate(item.bed, limit: 120),
            statusLabel: "\(item.status.rawValue)".uppercased()
        )
    }

    static func toFallbackAssessmentManifestViews(_ items: [FallbackAssessmentManifest]) -> [FallbackAssessmentManifestView] {
        var views: [FallbackAssessmentManifestView] = []
        for item in items {
            views.append(toFallbackAssessmentManifestView(item))
        }
        return views
    }

    static func sumFallbackAssessmentManifestView(_ view: FallbackAssessmentManifestView) throws -> Double {
        guard let parsedRevision = Int(view.revision) else {
            throw Kit.Failure("parse revision: not a number")
        }
        guard let parsedMinimum = Double(view.minimum) else {
            throw Kit.Failure("parse minimum: not a number")
        }
        guard let parsedRate = Double(view.rate) else {
            throw Kit.Failure("parse rate: not a number")
        }
        return Double(parsedRevision) + parsedMinimum + parsedRate
    }
}
